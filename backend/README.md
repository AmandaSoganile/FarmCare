# FarmCare API

FarmCare now has its own FastAPI/PostgreSQL backend. Supabase is optional during
the transition. No existing Supabase accounts, cloud animals, or local device
stores have been migrated or deleted. Start with new development accounts.

## Run on your Mac

Install Docker Desktop and start it. From the **updated project folder**:

```bash
cd backend
python3 scripts/init_local.py
docker compose up --build -d
```

`init_local.py` generates a private, ignored `.env` with random local credentials.
It refuses to overwrite an existing file. Keep this file: changing the database
password in `.env` does not change a password inside an existing PostgreSQL volume.

Open `http://localhost:8000/readyz` in your Mac browser. It should return
`{"status":"ready"}`. API documentation is at `http://localhost:8000/docs`.
Development emails appear in Mailpit at `http://localhost:8025`; they are captured
locally rather than sent to real inboxes. Do not share recovery links or tokens.

Stop with `docker compose down`. The named PostgreSQL volume keeps the database.
Do not add `-v` unless you intend to delete that local database.

The Compose configuration is for local development. Its containers were not run
in the cloud session; the API was instead tested natively against PostgreSQL 17.

## Connect the iOS simulator

Keep the previous Mac project as a backup. Open the updated `FarmCare.xcodeproj`
in Xcode 26 or later. Preserve your signing settings and your local secrets file.
Edit **FarmCare/Secrets.xcconfig** to add:

```xcconfig
FARMCARE_BACKEND = custom
FARMCARE_API_SCHEME = http
FARMCARE_API_HOST = localhost:8000
```

No Supabase key is needed in custom mode. Keep any existing Supabase values for
rollback. Select an **iOS 26 simulator**, clean the build folder, and run.
HTTP is restricted to local addresses in Debug builds; Release requires HTTPS.
Local network access may require the simulator's permission prompt.

1. Create a **new test account**.
2. Find its verification email in Mailpit and open the link in your Mac browser.
   Click **Confirm your email**, then sign in inside FarmCare.
3. Add an animal and wait for **Animals synced**. Sign in on a second simulator
   with the same account and press **Sync**.
4. Choose **Forgot password?** on Sign In. Open the new Mailpit email and set a
   new password in the FarmCare recovery page. Return to the app and sign in.
   Existing device sessions should be rejected following password reset.
5. Try a wrong password. FarmCare should show a clear message with a reference
   ID for server errors, rather than `Auth.AuthError error 0`.
6. Test offline edits, reconnection, and changes made on two devices. Conflicting
   edits must show **Review**, with both versions retained until a choice is made.
   A server deletion takes precedence over a stale edit.

The custom API has a separate local store namespace per server and account.
Switching backends does **not** automatically import previous local records.
Do not uninstall FarmCare or remove its old stores to solve a connection issue.

For a physical phone, `localhost` means the phone. This default Compose stack is
bound to your Mac's loopback interface and is intended for the simulator. Device
testing needs a reachable development service, matching public email-link origin,
local-network permissions, and preferably HTTPS; it is not enabled by this setup.

To return to the existing backend, set `FARMCARE_BACKEND = supabase`, preserve
the existing SUPABASE_URL and public key, and rebuild. Old secrets files without
FARMCARE_BACKEND continue selecting Supabase. The old SDK and SQL files remain
until Mac acceptance and a separately planned data migration are complete.

## API behavior

- Argon2id password hashes; verification required before login.
- Fifteen-minute JWT access tokens and thirty-day device sessions. Refresh tokens
  rotate; replay revokes their device session. Logout and password reset revoke
  sessions at the server, including access-token use.
- One-use, hashed verification/reset tokens, generic account-email responses,
  shared database-backed rate limits, bounded request bodies, safe structured errors,
  and request IDs. No passwords or tokens are logged.
- Transactional mail outbox with retry backoff. Native development without SMTP
  writes private `.mail/*.eml` files. Delivery bodies are cleared from the outbox
  after sending. The pending outbox and mail files contain sensitive links and
  must be protected along with database backups. Expired links need a new email.
- `GET/PATCH /v1/me`; caller-owned animal listing and retrieval.
- `POST /v1/sync/push` accepts up to 100 mutations. Each has a UUID, record UUID,
  base revision, operation, and payload. Mutation IDs bind to exact payloads;
  retries return the original result. Reusing an ID for different data fails.
- Stale live edits return a conflict; deleted records cannot be resurrected.
  Immutable change history and account-locked counters prevent skipped commits.
  Signed cursors bind pagination to an account and a snapshot watermark.
- Swift saves exact mutation bytes before sending, saves changes and pull cursors
  together, keeps conflict versions, serializes refresh, and retries safe reads
  and mutations with bounded backoff. Network restoration and foregrounding retry
  sync. Auth mutations and refresh rotation are not automatically replayed after
  an ambiguous network failure: an interrupted refresh may require signing in.
- Tokens live in the device Keychain, scoped to the API origin. Transient network
  errors retain the account cache; confirmed expired/revoked sessions require login.

## Native development and tests

Requires Python 3.12+, uv, and PostgreSQL 17. Run from `backend/`:

```bash
uv sync --frozen
python3 scripts/init_local.py
# Set FARMCARE_DATABASE_URL in the private .env to your local development DB.
uv run alembic upgrade head
uv run uvicorn app.main:create_app --factory --env-file .env --no-access-log
# In a second terminal, in backend/:
uv run python -m app.mail
```

For tests, first create an **empty disposable database whose name ends in
`_test`**, then supply its DSN privately. The test suite truncates that database's
application tables; it refuses other database names. It never needs Supabase.

```bash
# Set FARMCARE_TEST_DATABASE_URL to the disposable database's DSN first.
uv run pytest -q
```

Tests apply migrations, check metadata consistency, and exercise accounts,
verification, recovery, session expiry/rotation/reuse, concurrent requests,
rate limiting, mail retry, account isolation, idempotency, conflicts, rollback,
pagination snapshots, and deletion tombstones against PostgreSQL.

For a running native development server, the optional browser smoke check uses
a new disposable account and leaves its test data in the local database:

```bash
# Install a Playwright Chromium browser if system Chromium is unavailable:
uv run --with playwright playwright install chromium
PYTHONPATH=. uv run --frozen --with playwright python scripts/browser_smoke.py
```

The browser check covers actual HTTP registration/login/sync and the rendered
verification/reset forms. It does not validate SwiftUI, SwiftData, or Keychain.

## Before production and Supabase retirement

Local implementation and tests are complete; production cutover is outstanding.
Choose hosting, an HTTPS hostname, a PostgreSQL backup/restore strategy, and SMTP
delivery. Set FARMCARE_ENV=production, a strong private FARMCARE_SIGNING_KEY,
FARMCARE_PUBLIC_URL to the public HTTPS origin, and SMTP with STARTTLS. The API
refuses production configuration without HTTPS and STARTTLS. Do not put server
keys, database passwords, or SMTP credentials in the iOS app.

Put the API behind a managed TLS ingress with request/time/concurrency limits,
correct proxy handling, monitoring, and mail-outbox monitoring. The local Compose
ports and Mailpit are not a public deployment configuration. Retain immutable
sync history and tombstones until a tested retention/full-resync policy exists.
Schedule cleanup of old rate buckets and expired account tokens/sessions without
removing active refresh-reuse history. Back up and restore-test the database.

On the Mac, verify Swift compilation, two-device sync, Keychain restoration,
refresh concurrency, offline/relaunch behavior, and conflict choices. These are
unverified in this Linux session. Then rehearse an authorized export/import that
preserves existing account and animal IDs and record counts. Existing Supabase
sessions do not authenticate to this API; existing users need a controlled
password reset or a separately verified compatible password-hash migration.
Assign ownership explicitly before importing legacy shared local records.

Keep Supabase intact for rollback until the migration has been accepted. No live
deployment, Supabase migration, or account deletion was performed. The source
is available on the farmcare-custom-api GitHub branch at the owner's request.
