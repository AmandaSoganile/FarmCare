import os
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import urlparse


@dataclass(frozen=True)
class Settings:
    database_url: str = field(repr=False)
    signing_key: str = field(repr=False)
    environment: str = "development"
    public_url: str = "http://localhost:8000"
    mail_directory: Path = Path(".mail")
    smtp_host: str = ""
    smtp_port: int = 1025
    smtp_user: str = ""
    smtp_password: str = field(default="", repr=False)
    smtp_starttls: bool = False
    mail_from: str = "FarmCare <noreply@farmcare.local>"
    access_seconds: int = 900
    refresh_seconds: int = 30 * 86400
    rate_limit: int = 20

    def __post_init__(self):
        if len(self.signing_key.encode()) < 32:
            raise ValueError("FARMCARE_SIGNING_KEY must contain at least 32 bytes")
        if not self.database_url.startswith("postgresql+psycopg://"):
            raise ValueError("Use PostgreSQL via postgresql+psycopg://")
        u = urlparse(self.public_url)
        if not u.hostname or u.username or u.password or u.query or u.fragment or u.path not in ("", "/"):
            raise ValueError("FARMCARE_PUBLIC_URL must be an origin without a path")
        if self.environment not in ("development", "test", "production"):
            raise ValueError("Invalid FARMCARE_ENV")
        if self.environment == "production":
            if u.scheme != "https" or not self.smtp_host or not self.smtp_starttls:
                raise ValueError("Production requires HTTPS and SMTP with STARTTLS")
        elif u.scheme not in ("http", "https"):
            raise ValueError("Invalid public URL scheme")

    @classmethod
    def from_env(cls):
        from dotenv import load_dotenv
        load_dotenv(override=False)
        return cls(
            database_url=os.environ["FARMCARE_DATABASE_URL"],
            signing_key=os.environ["FARMCARE_SIGNING_KEY"],
            environment=os.getenv("FARMCARE_ENV", "development"),
            public_url=os.getenv("FARMCARE_PUBLIC_URL", "http://localhost:8000"),
            mail_directory=Path(os.getenv("FARMCARE_MAIL_DIRECTORY", ".mail")),
            smtp_host=os.getenv("FARMCARE_SMTP_HOST", ""),
            smtp_port=int(os.getenv("FARMCARE_SMTP_PORT", "1025")),
            smtp_user=os.getenv("FARMCARE_SMTP_USER", ""),
            smtp_password=os.getenv("FARMCARE_SMTP_PASSWORD", ""),
            smtp_starttls=os.getenv("FARMCARE_SMTP_STARTTLS", "false").lower() == "true",
            mail_from=os.getenv("FARMCARE_MAIL_FROM", "FarmCare <noreply@farmcare.local>"),
        )
