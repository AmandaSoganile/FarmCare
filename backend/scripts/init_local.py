"""Generate credentials for LOCAL development without overwriting an existing file."""
import os
import secrets
from pathlib import Path

path = Path(__file__).resolve().parents[1] / ".env"
password = secrets.token_urlsafe(32)
key = secrets.token_urlsafe(48)
try:
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
except FileExistsError:
    raise SystemExit("Existing backend/.env preserved. No settings were changed.")
with os.fdopen(fd, "w") as f:
    f.write(f"FARMCARE_ENV=development\nFARMCARE_DB_PASSWORD={password}\nFARMCARE_SIGNING_KEY={key}\n"
            f"FARMCARE_DATABASE_URL=postgresql+psycopg://farmcare:{password}@localhost:5433/farmcare\n"
            "FARMCARE_PUBLIC_URL=http://localhost:8000\n")
print("Created private backend/.env for local development. No values were printed.")
