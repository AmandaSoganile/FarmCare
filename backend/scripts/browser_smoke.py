"""Local API + Chromium acceptance check. Never point this at a live service.

From backend/: uv run --frozen --with playwright python scripts/browser_smoke.py
Requires a running native local API and Chromium (or a Playwright installation).
Creates a disposable test account and animal in the development database.
"""
import os
import re
import secrets
from email import policy
from email.parser import Parser
from uuid import uuid4

import httpx
from playwright.sync_api import sync_playwright, expect
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.config import Settings
from app.mail import drain
from app.models import Mail

settings = Settings.from_env()
engine = create_engine(settings.database_url)
if settings.environment != "development" or engine.url.host not in ("localhost", "127.0.0.1"):
    raise SystemExit("This smoke check only supports a native local development database")
origin = "http://127.0.0.1:8000"
email = f"smoke-{uuid4().hex}@example.com"
password = secrets.token_urlsafe(20)
new_password = secrets.token_urlsafe(20)
client = httpx.Client(base_url=origin, trust_env=False, timeout=15)


def mail_link(subject):
    drain(engine, settings)
    with Session(engine) as db:
        row = db.scalar(select(Mail).where(Mail.recipient == email, Mail.subject == subject))
        assert row and row.sent
        path = settings.mail_directory / f"{row.id}.eml"
    message = Parser(policy=policy.default).parsestr(path.read_text())
    body = message.get_content()
    path_and_fragment = re.search(r"http[^\s]+(/(?:verify|recover)#token=[^\s]+)", body)
    assert path_and_fragment
    return origin + path_and_fragment.group(1)


assert client.get("/readyz").status_code == 200
assert client.post("/v1/auth/register", json={"email": email, "name": "Smoke farmer", "password": password}).status_code == 202
with sync_playwright() as playwright:
    executable = os.getenv("FARMCARE_BROWSER_EXECUTABLE")
    if not executable and os.path.isfile("/usr/bin/chromium"):
        executable = "/usr/bin/chromium"
    browser = playwright.chromium.launch(executable_path=executable, headless=True)
    page = browser.new_page()
    page.goto(mail_link("Confirm your FarmCare email"))
    page.get_by_role("button", name="Confirm your email").click()
    expect(page.locator("#message")).to_contain_text("Email confirmed")
    assert "#" not in page.url  # Token removed from browser history.
    print("PASS: live API registration, email worker, and browser verification")

    login = client.post("/v1/auth/login", json={"email": email, "password": password})
    assert login.status_code == 200
    headers = {"Authorization": "Bearer " + login.json()["access_token"]}
    mutation = {"mutation_id": str(uuid4()), "record_id": str(uuid4()), "base_revision": 0, "operation": "upsert",
                "data": {"name": "Bessie", "species": "Cow", "breed": "Jersey", "weight": 450, "feed_type": "Grass",
                         "feed_schedule": 2, "vaccination_type": "Routine", "vaccination_frequency": 4,
                         "last_vaccination_date": "2026-11-06T10:00:00Z", "notes": "Smoke test"}}
    result = client.post("/v1/sync/push", headers=headers, json={"mutations": [mutation]})
    assert result.status_code == 200
    assert client.post("/v1/sync/push", headers=headers, json={"mutations": [mutation]}).json() == result.json()
    assert len(client.get("/v1/sync/pull", headers=headers).json()["changes"]) == 1
    print("PASS: live login, idempotent animal push, and change pull")

    assert client.post("/v1/auth/forgot-password", json={"email": email}).status_code == 202
    page.goto(mail_link("Reset your FarmCare password"))
    page.locator("#password").fill(new_password)
    page.locator("#confirm").fill(new_password)
    page.get_by_role("button", name="Reset your password").click()
    expect(page.locator("#message")).to_contain_text("Password updated")
    assert client.get("/v1/me", headers=headers).status_code == 401
    assert client.post("/v1/auth/login", json={"email": email, "password": password}).status_code == 401
    assert client.post("/v1/auth/login", json={"email": email, "password": new_password}).status_code == 200
    print("PASS: browser password reset, old-session revocation, and new-password login")
    browser.close()
client.close()
engine.dispose()
