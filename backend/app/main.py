import hashlib
import hmac
import json
import logging
from contextlib import asynccontextmanager
from uuid import UUID, uuid4
from pathlib import Path

import jwt
from fastapi import Depends, FastAPI, Query, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import HTMLResponse, JSONResponse
from sqlalchemy import create_engine, select, update, text
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session
from alembic.script import ScriptDirectory

from . import schemas as S
from .config import Settings
from .models import ActionToken, Animal, Change, DeviceSession, Mail, Mutation, RateBucket, RefreshToken, User
from .security import check_password, decode, digest, dummy_hash, encode, now, passwords, token
from .web import recovery_page
from .body_limit import BodyLimit

log = logging.getLogger("farmcare")


class APIError(Exception):
    def __init__(self, status, code, message, retry_after=None):
        self.status, self.code, self.message, self.retry_after = status, code, message, retry_after


def profile(user):
    return {"id": str(user.id), "email": user.email, "name": user.name}


def create_app(settings=None):
    settings = settings or Settings.from_env()
    engine = create_engine(settings.database_url, pool_pre_ping=True)

    @asynccontextmanager
    async def lifespan(app):
        yield
        engine.dispose()

    app = FastAPI(title="FarmCare API", version="1.0.0", lifespan=lifespan)
    app.state.engine = engine
    app.state.settings = settings
    expected_revision = ScriptDirectory(str(Path(__file__).resolve().parents[1] / "migrations")).get_current_head()

    @app.middleware("http")
    async def request_context(request, call_next):
        request.state.request_id = str(uuid4())
        try:
            size = int(request.headers.get("content-length", "0"))
        except ValueError:
            size = 1048577
        if size < 0 or size > 1048576:
            response = error_response(request, APIError(413, "PAYLOAD_TOO_LARGE", "Request is too large."))
        else:
            response = await call_next(request)
        response.headers["X-Request-ID"] = request.state.request_id
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "no-referrer"
        return response

    def error_response(request, error, fields=None):
        body = {"error": {"code": error.code, "message": error.message,
                          "request_id": request.state.request_id}}
        if fields:
            body["error"]["fields"] = fields
        headers = {"Retry-After": str(error.retry_after)} if error.retry_after else {}
        if error.status == 401:
            headers["WWW-Authenticate"] = "Bearer"
        return JSONResponse(body, status_code=error.status, headers=headers)

    @app.exception_handler(APIError)
    async def api_error(request, error):
        return error_response(request, error)

    @app.exception_handler(RequestValidationError)
    async def invalid_input(request, error):
        # ValidationError.input may contain passwords/tokens: never return or log it.
        fields = [{"field": ".".join(map(str, e["loc"][1:])), "message": e["msg"]}
                  for e in error.errors()]
        return error_response(request, APIError(422, "VALIDATION_ERROR", "Check the highlighted fields."), fields)

    @app.exception_handler(SQLAlchemyError)
    async def database_error(request, error):
        log.error("Database operation failed request_id=%s", request.state.request_id)
        return error_response(request, APIError(503, "SERVICE_UNAVAILABLE", "The service is temporarily unavailable. Please retry."))

    @app.exception_handler(Exception)
    async def unexpected_error(request, error):
        log.error("Unexpected failure request_id=%s", request.state.request_id)
        response = error_response(request, APIError(500, "INTERNAL_ERROR", "Something went wrong. Please retry."))
        response.headers["X-Request-ID"] = request.state.request_id
        return response

    def database():
        with Session(engine) as db:
            try:
                yield db
                db.commit()
            except Exception:
                db.rollback()
                raise

    def limit(db, request, action, email=""):
        window = now() // 900
        for identity, maximum in [(request.client.host if request.client else "unknown", settings.rate_limit * 5),
                                  (email or "anonymous", settings.rate_limit)]:
            key = hmac.new(settings.signing_key.encode(), (action + ":" + identity).encode(), hashlib.sha256).hexdigest()
            stmt = insert(RateBucket).values(key=key, window=window, count=1)
            count = db.scalar(stmt.on_conflict_do_update(
                index_elements=[RateBucket.key, RateBucket.window],
                set_={"count": RateBucket.count + 1}).returning(RateBucket.count))
            db.commit()  # Failed authentication must not undo rate accounting.
            if count > maximum:
                raise APIError(429, "RATE_LIMITED", "Too many attempts. Please try again later.", 900 - now() % 900)

    def locked_user(db, user_id):
        return db.scalar(select(User).where(User.id == user_id).with_for_update())

    def authenticated(request: Request, db: Session = Depends(database, scope="function")):
        value = request.headers.get("authorization", "")
        try:
            if not value.startswith("Bearer "):
                raise ValueError()
            claims = decode(settings, "access", value[7:])
            user = locked_user(db, UUID(claims["sub"]))
            session = db.get(DeviceSession, UUID(claims["sid"]))
            if not user or not user.verified or not session or session.user_id != user.id or session.revoked or session.expires_at <= now():
                raise ValueError()
        except (jwt.InvalidTokenError, ValueError, KeyError, TypeError):
            raise APIError(401, "SESSION_EXPIRED", "Your session has ended. Please sign in again.") from None
        return user, session

    def session_response(db, user, session):
        raw = token()
        db.add(RefreshToken(digest=digest(raw), session_id=session.id))
        return {"access_token": encode(settings, "access", {"sub": str(user.id), "sid": str(session.id)}, settings.access_seconds),
                "refresh_token": raw, "expires_in": settings.access_seconds, "user": profile(user)}

    def queue_action(db, user, purpose):
        raw = token()
        # Only the most recently requested link for a purpose remains valid.
        db.execute(update(ActionToken).where(ActionToken.user_id == user.id, ActionToken.purpose == purpose)
                   .values(used=True))
        db.add(ActionToken(digest=digest(raw), user_id=user.id, purpose=purpose,
                           expires_at=now() + (3600 if purpose == "reset" else 86400)))
        path = "/recover" if purpose == "reset" else "/verify"
        link = settings.public_url.rstrip("/") + path + "#token=" + raw
        db.add(Mail(recipient=user.email, subject="Reset your FarmCare password" if purpose == "reset" else "Confirm your FarmCare email",
                    body=("Reset your password" if purpose == "reset" else "Confirm your email") + ":\n" + link +
                    "\n\nIf you did not request this, you can ignore this email."))

    def action_user(db, value, purpose):
        row = db.get(ActionToken, digest(value))
        if row is None:
            raise APIError(400, "INVALID_LINK", "This link is invalid or has expired. Request a new email.")
        user = locked_user(db, row.user_id)
        db.refresh(row)  # Re-read after the per-account lock; another request may have consumed it.
        if row.purpose != purpose or row.used or row.expires_at <= now():
            raise APIError(400, "INVALID_LINK", "This link is invalid or has expired. Request a new email.")
        row.used = True
        return user

    @app.get("/healthz")
    def health():
        return {"status": "ok"}

    @app.get("/readyz")
    def ready(db: Session = Depends(database, scope="function")):
        if db.scalar(text("SELECT version_num FROM alembic_version")) != expected_revision:
            raise APIError(503, "SERVICE_UNAVAILABLE", "Database setup is incomplete.")
        return {"status": "ready"}

    @app.post("/v1/auth/register", status_code=202)
    def register(body: S.Register, request: Request, db: Session = Depends(database, scope="function")):
        limit(db, request, "register", body.email)
        # Serialize registration of the same email across server processes.
        db.execute(text("SELECT pg_advisory_xact_lock(hashtextextended(:email, 0))"), {"email": body.email})
        existing = db.scalar(select(User).where(User.email == body.email))
        hashed = passwords.hash(body.password)
        if existing is None:
            user = User(email=body.email, name=body.name, password_hash=hashed)
            db.add(user)
            db.flush()
            queue_action(db, user, "verify")
        return {"message": "If this address can be registered, a confirmation email will arrive shortly."}

    @app.post("/v1/auth/resend-verification", status_code=202)
    def resend(body: S.EmailInput, request: Request, db: Session = Depends(database, scope="function")):
        limit(db, request, "verification", body.email)
        user = db.scalar(select(User).where(User.email == body.email).with_for_update())
        if user and not user.verified:
            queue_action(db, user, "verify")
        return {"message": "If this account needs verification, a new email will arrive shortly."}

    @app.post("/v1/auth/verify-email")
    def verify(body: S.TokenInput, db: Session = Depends(database, scope="function")):
        user = action_user(db, body.token, "verify")
        user.verified = True
        return {"message": "Email confirmed. Return to FarmCare and sign in."}

    @app.post("/v1/auth/login")
    def login(body: S.Login, request: Request, db: Session = Depends(database, scope="function")):
        limit(db, request, "login", body.email)
        user = db.scalar(select(User).where(User.email == body.email).with_for_update())
        valid = check_password(body.password, user.password_hash if user else dummy_hash)
        if user is None or not valid:
            raise APIError(401, "INVALID_CREDENTIALS", "The email or password is incorrect.")
        if not user.verified:
            raise APIError(403, "EMAIL_NOT_VERIFIED", "Confirm your email before signing in. You can request a new confirmation email.")
        if passwords.check_needs_rehash(user.password_hash):
            user.password_hash = passwords.hash(body.password)
        session = DeviceSession(user_id=user.id, expires_at=now() + settings.refresh_seconds)
        db.add(session)
        db.flush()
        return session_response(db, user, session)

    @app.post("/v1/auth/refresh")
    def refresh(body: S.Refresh, request: Request, db: Session = Depends(database, scope="function")):
        limit(db, request, "refresh", digest(body.refresh_token))
        row = db.get(RefreshToken, digest(body.refresh_token))
        session = db.get(DeviceSession, row.session_id) if row else None
        if session is None:
            raise APIError(401, "SESSION_EXPIRED", "Please sign in again.")
        user = locked_user(db, session.user_id)
        db.refresh(row)
        db.refresh(session)
        if row.used:
            session.revoked = True
            db.commit()  # Retain revocation even though the request returns 401.
            raise APIError(401, "SESSION_EXPIRED", "This session is no longer valid. Please sign in again.")
        if session.revoked or session.expires_at <= now() or not user.verified:
            raise APIError(401, "SESSION_EXPIRED", "Please sign in again.")
        row.used = True
        return session_response(db, user, session)

    @app.post("/v1/auth/logout")
    def logout(account=Depends(authenticated, scope="function")):
        account[1].revoked = True
        return {"message": "Signed out."}

    @app.post("/v1/auth/forgot-password", status_code=202)
    def forgot(body: S.EmailInput, request: Request, db: Session = Depends(database, scope="function")):
        limit(db, request, "recovery", body.email)
        user = db.scalar(select(User).where(User.email == body.email).with_for_update())
        if user and user.verified:
            queue_action(db, user, "reset")
        return {"message": "If this address has a verified account, a password-reset email will arrive shortly."}

    @app.post("/v1/auth/reset-password")
    def reset(body: S.Reset, db: Session = Depends(database, scope="function")):
        user = action_user(db, body.token, "reset")
        user.password_hash = passwords.hash(body.password)
        db.execute(update(DeviceSession).where(DeviceSession.user_id == user.id).values(revoked=True))
        return {"message": "Password updated. Return to FarmCare and sign in with your new password."}

    @app.get("/v1/me")
    def me(account=Depends(authenticated, scope="function")):
        return profile(account[0])

    @app.patch("/v1/me")
    def update_me(body: S.ProfileUpdate, account=Depends(authenticated, scope="function")):
        account[0].name = body.name
        return profile(account[0])

    def record(animal):
        return {"id": str(animal.id), "revision": animal.revision, "deleted": animal.deleted,
                "data": None if animal.deleted else animal.data}

    @app.get("/v1/animals")
    def animals(limit: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0),
                account=Depends(authenticated, scope="function"), db: Session = Depends(database, scope="function")):
        rows = db.scalars(select(Animal).where(Animal.owner_id == account[0].id, Animal.deleted.is_(False))
                          .order_by(Animal.id).offset(offset).limit(limit)).all()
        return {"animals": [record(a) for a in rows]}

    @app.get("/v1/animals/{animal_id}")
    def animal(animal_id: UUID, account=Depends(authenticated, scope="function"), db: Session = Depends(database, scope="function")):
        row = db.scalar(select(Animal).where(Animal.id == animal_id, Animal.owner_id == account[0].id))
        if row is None:
            raise APIError(404, "NOT_FOUND", "Animal not found.")
        return record(row)

    @app.post("/v1/sync/push")
    def push(body: S.Push, account=Depends(authenticated, scope="function"), db: Session = Depends(database, scope="function")):
        user = account[0]  # Locked until commit; serializes account revision and mutation allocation.
        results = []
        for change in body.mutations:
            fingerprint = digest(json.dumps(change.model_dump(mode="json"), sort_keys=True))
            prior = db.get(Mutation, (user.id, change.mutation_id))
            if prior:
                if prior.digest != fingerprint:
                    raise APIError(409, "MUTATION_REUSED", "A mutation ID was reused for different data.")
                results.append(prior.result)
                continue
            row = db.get(Animal, change.record_id)
            if row and row.owner_id != user.id:
                raise APIError(404, "NOT_FOUND", "Animal not found.")
            if row and row.deleted:
                status = "deleted"  # A stale edit cannot resurrect a deleted animal.
            elif (row.revision if row else 0) != change.base_revision:
                status = "conflict"
            else:
                if row is None:
                    row = Animal(id=change.record_id, owner_id=user.id, revision=0, data={})
                    db.add(row)
                user.change_seq += 1
                row.revision = user.change_seq
                row.deleted = change.operation == "delete"
                if change.data is not None:
                    row.data = change.data.model_dump(mode="json")
                db.add(Change(owner_id=user.id, sequence=row.revision, record=record(row)))
                status = "applied"
            result = {"mutation_id": str(change.mutation_id), "status": status, "record": record(row) if row else None}
            db.add(Mutation(owner_id=user.id, id=change.mutation_id, digest=fingerprint, result=result))
            db.flush()
            results.append(result)
        return {"results": results}

    @app.get("/v1/sync/pull")
    def pull(cursor: str | None = Query(None, max_length=2048), limit: int = Query(100, ge=1, le=500),
             account=Depends(authenticated, scope="function"), db: Session = Depends(database, scope="function")):
        user = account[0]
        start, watermark = 0, user.change_seq
        if cursor:
            try:
                claims = decode(settings, "cursor", cursor)
                if claims["sub"] != str(user.id):
                    raise ValueError()
                start = int(claims["position"])
                watermark = int(claims.get("watermark", user.change_seq))
                if not 0 <= start <= watermark <= user.change_seq:
                    raise ValueError()
            except (jwt.InvalidTokenError, ValueError, KeyError, TypeError):
                raise APIError(400, "INVALID_CURSOR", "Sync history needs to be downloaded again.") from None
        rows = db.scalars(select(Change).where(Change.owner_id == user.id, Change.sequence > start,
                          Change.sequence <= watermark).order_by(Change.sequence).limit(limit + 1)).all()
        more = len(rows) > limit
        page = rows[:limit]
        position = page[-1].sequence if more else watermark
        payload = {"sub": str(user.id), "position": position}
        if more:
            payload["watermark"] = watermark
        return {"changes": [r.record for r in page], "has_more": more,
                "cursor": encode(settings, "cursor", payload, 30 * 86400)}

    @app.get("/recover", response_class=HTMLResponse)
    def recover_page():
        return recovery_page("reset")

    @app.get("/verify", response_class=HTMLResponse)
    def verify_page():
        return recovery_page("verify")

    app.add_middleware(BodyLimit)
    return app
