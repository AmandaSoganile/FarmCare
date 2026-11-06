"""Transactional outbox. Run `python -m app.mail` as a separate mail worker.

Local development writes private .eml files; production requires authenticated
or trusted SMTP with STARTTLS. Never print message bodies or recovery tokens.
"""
import os
import smtplib
import ssl
import time
from email.message import EmailMessage

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from .config import Settings
from .models import Mail
from .security import now


def deliver(settings, row):
    message = EmailMessage()
    message["From"] = settings.mail_from
    message["To"] = row.recipient
    message["Subject"] = row.subject
    message["Message-ID"] = f"<{row.id}@farmcare>"
    message.set_content(row.body)
    if settings.smtp_host:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as smtp:
            if settings.smtp_starttls:
                smtp.starttls(context=ssl.create_default_context())
            if settings.smtp_user:
                smtp.login(settings.smtp_user, settings.smtp_password)
            smtp.send_message(message)
    else:
        settings.mail_directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        path = settings.mail_directory / f"{row.id}.eml"
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as f:
            f.write(message.as_string())


def drain(engine, settings, limit=50):
    sent = 0
    for _ in range(limit):
        with Session(engine) as db, db.begin():
            row = db.scalar(select(Mail).where(Mail.sent.is_(False), Mail.next_attempt_at <= now())
                            .order_by(Mail.attempts, Mail.id).with_for_update(skip_locked=True).limit(1))
            if row is None:
                break
            row.attempts += 1
            row.next_attempt_at = now() + min(3600, 2 ** min(row.attempts, 12))
            try:
                deliver(settings, row)
                row.sent = True
                row.body = ""  # Do not retain usable recovery tokens after delivery.
                sent += 1
            except (OSError, smtplib.SMTPException):
                # Committing attempts keeps failed mail available for a later retry.
                pass
    return sent


if __name__ == "__main__":
    settings = Settings.from_env()
    engine = create_engine(settings.database_url, pool_pre_ping=True)
    while True:
        drain(engine, settings)
        time.sleep(5)
