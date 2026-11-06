from concurrent.futures import ThreadPoolExecutor
from dataclasses import replace

import jwt
from fastapi.testclient import TestClient
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.main import create_app
from app.mail import drain
from app.models import ActionToken, DeviceSession, Mail, User


def test_signup_requires_verification_and_tokens_are_one_use(client, mail_token, engine):
    body = {"email": "  Farmer@Example.com ", "name": " Farmer ", "password": "good-password-123"}
    assert client.post("/v1/auth/register", json=body).status_code == 202
    login = {"email": "farmer@example.com", "password": body["password"]}
    assert client.post("/v1/auth/login", json=login).json()["error"]["code"] == "EMAIL_NOT_VERIFIED"
    value = mail_token(login["email"], "Confirm")
    with Session(engine) as db:
        assert db.scalar(select(User)).password_hash.startswith("$argon2id$")
        assert db.scalar(select(ActionToken)).digest != value
    assert client.post("/v1/auth/verify-email", json={"token": value}).status_code == 200
    assert client.post("/v1/auth/verify-email", json={"token": value}).status_code == 400
    response = client.post("/v1/auth/login", json=login)
    assert response.status_code == 200
    assert response.json()["user"]["email"] == "farmer@example.com"


def test_recovery_changes_password_and_revokes_all_devices(client, account, mail_token):
    session, headers = account("farmer@example.com")
    second = client.post("/v1/auth/login", json={"email": "farmer@example.com", "password": "Farm-password-123"}).json()
    assert client.post("/v1/auth/forgot-password", json={"email": "farmer@example.com"}).status_code == 202
    value = mail_token("farmer@example.com", "Reset")
    body = {"token": value, "password": "New-farm-password-456"}
    assert client.post("/v1/auth/reset-password", json=body).status_code == 200
    assert client.post("/v1/auth/reset-password", json=body).status_code == 400
    assert client.get("/v1/me", headers=headers).status_code == 401
    for device in (session, second):
        assert client.post("/v1/auth/refresh", json={"refresh_token": device["refresh_token"]}).status_code == 401
    assert client.post("/v1/auth/login", json={"email": "farmer@example.com", "password": "Farm-password-123"}).status_code == 401
    assert client.post("/v1/auth/login", json={"email": "farmer@example.com", "password": body["password"]}).status_code == 200


def test_unknown_addresses_and_duplicate_registration_are_generic(client, account):
    account("farmer@example.com")
    known = client.post("/v1/auth/forgot-password", json={"email": "farmer@example.com"})
    unknown = client.post("/v1/auth/forgot-password", json={"email": "unknown@example.com"})
    assert known.json() == unknown.json()
    a = client.post("/v1/auth/register", json={"email": "farmer@example.com", "name": "Other", "password": "New-password-123"})
    b = client.post("/v1/auth/register", json={"email": "another@example.com", "name": "Other", "password": "New-password-123"})
    assert a.json() == b.json()


def test_refresh_rotation_reuse_revokes_family(client, account):
    session, _ = account()
    rotated = client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})
    assert rotated.status_code == 200
    new = rotated.json()
    assert new["refresh_token"] != session["refresh_token"]
    assert client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}).status_code == 401
    assert client.get("/v1/me", headers={"Authorization": "Bearer " + new["access_token"]}).status_code == 401
    assert client.post("/v1/auth/refresh", json={"refresh_token": new["refresh_token"]}).status_code == 401


def test_concurrent_refresh_reuse_is_atomic(client, account):
    session, _ = account()
    def refresh(_):
        return client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]})
    with ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(refresh, range(2)))
    assert sorted(r.status_code for r in responses) == [200, 401]
    winner = next(r.json() for r in responses if r.status_code == 200)
    assert client.post("/v1/auth/refresh", json={"refresh_token": winner["refresh_token"]}).status_code == 401


def test_logout_revokes_access_and_refresh(client, account):
    session, headers = account()
    assert client.post("/v1/auth/logout", headers=headers).status_code == 200
    assert client.get("/v1/me", headers=headers).status_code == 401
    assert client.post("/v1/auth/refresh", json={"refresh_token": session["refresh_token"]}).status_code == 401


def test_expired_tokens_are_rejected(client, account, settings, engine, mail_token):
    session, headers = account("farmer@example.com")
    claims = jwt.decode(session["access_token"], options={"verify_signature": False})
    claims["exp"] = 1
    expired = jwt.encode(claims, settings.signing_key, algorithm="HS256")
    assert client.get("/v1/me", headers={"Authorization": "Bearer " + expired}).status_code == 401
    client.post("/v1/auth/forgot-password", json={"email": "farmer@example.com"})
    value = mail_token("farmer@example.com", "Reset")
    with Session(engine) as db, db.begin():
        db.execute(update(ActionToken).values(expires_at=1))
    assert client.post("/v1/auth/reset-password", json={"token": value, "password": "New-password-123"}).status_code == 400
    with Session(engine) as db, db.begin():
        db.execute(update(DeviceSession).values(expires_at=1))
    assert client.get("/v1/me", headers=headers).status_code == 401


def test_validation_errors_do_not_echo_passwords(client):
    response = client.post("/v1/auth/register", json={"email": "not-email", "password": "secret", "name": ""})
    assert response.status_code == 422
    assert "secret" not in response.text
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert response.json()["error"]["request_id"] == response.headers["X-Request-ID"]


def test_rate_limit_persists_after_rejected_login(settings):
    with TestClient(create_app(replace(settings, rate_limit=2))) as client:
        for _ in range(2):
            assert client.post("/v1/auth/login", json={"email": "a@example.com", "password": "bad"}).status_code == 401
        response = client.post("/v1/auth/login", json={"email": "a@example.com", "password": "bad"})
        assert response.status_code == 429
        assert int(response.headers["Retry-After"]) > 0


def test_mail_worker_and_recovery_pages(client, account, settings, engine):
    account("farmer@example.com")
    client.post("/v1/auth/forgot-password", json={"email": "farmer@example.com"})
    assert drain(engine, settings) == 2
    assert drain(engine, settings) == 0
    paths = list(settings.mail_directory.glob("*.eml"))
    assert len(paths) == 2
    assert all(p.stat().st_mode & 0o077 == 0 for p in paths)
    assert any("/recover#token=" in p.read_text() for p in paths)
    with Session(engine) as db:
        assert all(not m.body and m.sent for m in db.scalars(select(Mail)))
    for path in ("/recover", "/verify"):
        response = client.get(path)
        assert response.status_code == 200
        assert "frame-ancestors 'none'" in response.headers["Content-Security-Policy"]
        assert "location.hash" in response.text and "history.replaceState" in response.text


def test_profile_update_cannot_change_owner_or_email(client, account):
    session, headers = account()
    assert client.patch("/v1/me", headers=headers, json={"name": "New farmer"}).json()["name"] == "New farmer"
    assert client.patch("/v1/me", headers=headers, json={"name": "New", "id": session["user"]["id"]}).status_code == 422


def test_failed_mail_is_retained_with_backoff(client, account, settings, engine, monkeypatch):
    account()
    def unavailable(*args):
        raise OSError("SMTP unavailable")
    monkeypatch.setattr("app.mail.deliver", unavailable)
    assert drain(engine, settings) == 0
    with Session(engine) as db:
        mail = db.scalar(select(Mail))
        assert not mail.sent and mail.body
        assert mail.attempts == 1 and mail.next_attempt_at > 0
    assert drain(engine, settings) == 0
    with Session(engine) as db:
        assert db.scalar(select(Mail)).attempts == 1


def test_resend_replaces_old_verification_link(client, mail_token):
    client.post("/v1/auth/register", json={"email": "a@example.com", "name": "A", "password": "Good-password-123"})
    old = mail_token("a@example.com", "Confirm")
    assert client.post("/v1/auth/resend-verification", json={"email": "a@example.com"}).status_code == 202
    assert client.post("/v1/auth/verify-email", json={"token": old}).status_code == 400


def test_health_and_payload_size(client):
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").json() == {"status": "ready"}
    response = client.post("/v1/auth/login", content="x" * 1048577)
    assert response.status_code == 413
    chunked = client.post("/v1/auth/login", content=iter([b"x" * 600000, b"y" * 600000]))
    assert chunked.status_code == 413
