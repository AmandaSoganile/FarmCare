import os
import re
from pathlib import Path
from dataclasses import replace
from uuid import uuid4

import pytest
from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import Session

from app.config import Settings
from app.main import create_app
from app.models import Base, Mail


@pytest.fixture(scope="session")
def engine():
    url = os.environ.get("FARMCARE_TEST_DATABASE_URL", "")
    if not url or not url.split("?", 1)[0].endswith("_test"):
        pytest.fail("Set FARMCARE_TEST_DATABASE_URL to a disposable PostgreSQL database ending in _test")
    previous = os.environ.get("FARMCARE_DATABASE_URL")
    os.environ["FARMCARE_DATABASE_URL"] = url
    config = Config(str(Path(__file__).resolve().parents[1] / "alembic.ini"))
    command.upgrade(config, "head")
    command.upgrade(config, "head")
    command.check(config)
    if previous is None:
        os.environ.pop("FARMCARE_DATABASE_URL")
    else:
        os.environ["FARMCARE_DATABASE_URL"] = previous
    engine = create_engine(url)
    yield engine
    engine.dispose()


@pytest.fixture(autouse=True)
def clean_database(engine):
    with engine.begin() as c:
        c.execute(text("TRUNCATE " + ", ".join(Base.metadata.tables) + " CASCADE"))


@pytest.fixture
def settings(engine, tmp_path):
    return Settings(database_url=engine.url.render_as_string(hide_password=False),
                    signing_key="test-only-signing-key-" + "x" * 32,
                    environment="test", mail_directory=tmp_path / "mail")


@pytest.fixture
def app(settings):
    return create_app(settings)


@pytest.fixture
def client(app):
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mail_token(engine):
    def latest(email, subject):
        with Session(engine) as db:
            rows = db.scalars(select(Mail).where(Mail.recipient == email)).all()
            rows = [r for r in rows if subject in r.subject and "#token=" in r.body]
            assert rows
            return re.search(r"#token=([^\s]+)", rows[-1].body).group(1)
    return latest


@pytest.fixture
def account(client, mail_token):
    def create(email=None):
        email = email or f"farmer-{uuid4().hex}@example.com"
        response = client.post("/v1/auth/register", json={"email": email, "name": "Farmer", "password": "Farm-password-123"})
        assert response.status_code == 202, response.text
        response = client.post("/v1/auth/verify-email", json={"token": mail_token(email, "Confirm")})
        assert response.status_code == 200, response.text
        response = client.post("/v1/auth/login", json={"email": email, "password": "Farm-password-123"})
        assert response.status_code == 200, response.text
        session = response.json()
        return session, {"Authorization": "Bearer " + session["access_token"]}
    return create
