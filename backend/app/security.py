import hashlib
import secrets
import time
from uuid import UUID

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError, InvalidHashError

passwords = PasswordHasher()
# Match the work done for an existing account even when an email is unknown.
dummy_hash = passwords.hash(secrets.token_urlsafe(32))


def now():
    return int(time.time())


def token():
    return secrets.token_urlsafe(32)


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


def check_password(value, hashed):
    try:
        return passwords.verify(hashed, value)
    except (VerificationError, InvalidHashError):
        return False


def encode(settings, kind, payload, seconds):
    return jwt.encode({**payload, "typ": kind, "iss": "farmcare", "aud": "farmcare-" + kind,
                       "iat": now(), "exp": now() + seconds}, settings.signing_key, algorithm="HS256")


def decode(settings, kind, value):
    result = jwt.decode(value, settings.signing_key, algorithms=["HS256"], issuer="farmcare",
                        audience="farmcare-" + kind, options={"require": ["exp", "iat", "sub", "typ"]})
    if result["typ"] != kind:
        raise jwt.InvalidTokenError()
    UUID(result["sub"])
    return result
