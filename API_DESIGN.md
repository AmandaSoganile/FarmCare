# Proposed FarmCare custom API

Status as of 6 November 2026: the local FastAPI/PostgreSQL implementation and configurable Swift integration are implemented. See backend/README.md for tested local startup, recovery, validation, and remaining deployment/migration work. Supabase remains available for rollback; no live data has been migrated. Xcode compilation is still unverified.

## What the connection review found

These findings come from the uploaded project, not from access to the live Supabase project:

| Code path | Observed behavior | Consequence |
| --- | --- | --- |
| `AuthViewModel` | Uses Supabase's authentication event stream and one shared client | Session changes reach the UI; live auth events and failures still need observation |
| `AnimalSyncService.performSync` | Reads a session once, then reuses the access token for all uploads and downloads | A token expiring during a long sync can fail a later request; there is no refresh-and-replay step after a 401 |
| `AnimalAPI.send` | Makes one request and throws on non-success HTTP responses | No bounded automatic retry for transient errors or throttling |
| `SyncedTabsView` | Sync starts on opening an account, foregrounding, a local save, or pressing Sync | Restoring the network while the app stays foregrounded does not itself trigger a retry |
| Local SwiftData store | Separates account caches and keeps unsynced changes | A server failure should leave local changes available for the same account |
| HTTP error reporting | Returns a status code without a request ID, endpoint, or structured server error | Hard to distinguish invalid sessions, access policies, database setup, network problems, and provider availability |

These are possible contributors to the reported disconnects. They do not establish a Supabase outage or the cause of the user's live problem. The next diagnostic input would be the failing action, HTTP status/error, and whether it happens after backgrounding, inactivity, or switching networks. Do not collect passwords, access tokens, or refresh tokens in logs.

## Architecture

Keep the SwiftUI screens and account-isolated SwiftData storage. Replace the Supabase-specific authentication and animal HTTP calls with a small URLSession client that calls a FarmCare API.

- FastAPI application with versioned JSON endpoints and an OpenAPI specification.
- PostgreSQL owned by this backend, SQLAlchemy models, and Alembic migrations.
- Docker Compose for a local API and database on the Mac. Choose production hosting separately after local acceptance; no provider, paid service, or deployment is selected in this proposal.
- TLS at the production reverse proxy, health checks, database backups with restore testing, and request IDs in errors/logs. Hosting uptime still needs monitoring; using our own API is not a guarantee against disconnects.

## API contract

| Method | Route | Behavior |
| --- | --- | --- |
| GET | `/healthz` | Minimal liveness response, without database credentials or diagnostics |
| POST | `/v1/auth/register` | Create account and send a verification email |
| POST | `/v1/auth/verify-email` | Consume a one-use verification token |
| POST | `/v1/auth/login` | Authenticate verified account and create a device session |
| POST | `/v1/auth/refresh` | Rotate a device refresh token and issue a new access token |
| POST | `/v1/auth/logout` | Revoke that device session |
| POST | `/v1/auth/forgot-password` | Generic response; send reset email for an eligible account |
| POST | `/v1/auth/reset-password` | Consume reset token and invalidate existing sessions |
| GET/PATCH | `/v1/me` | Read/update permitted profile fields |
| GET | `/v1/animals` | Bounded offset-paginated current animals owned by the caller; use sync/pull for consistent change pagination |
| GET | `/v1/animals/{id}` | Caller-owned animal or 404 |
| POST | `/v1/sync/push` | Submit a bounded batch of idempotent animal changes with base revisions |
| GET | `/v1/sync/pull?cursor=...` | Read ordered per-account changes, including deletion tombstones |

The server derives account ownership from the authenticated session. A supplied owner ID is never authority to read or write another account's records. Animal writes use the sync endpoint so local changes and remote changes follow the same revision rules.

Errors use a stable code, user-safe message, request ID, and field errors where relevant. The client can distinguish `SESSION_EXPIRED`, `VALIDATION_ERROR`, `REVISION_CONFLICT`, `RATE_LIMITED`, and temporary server failures without displaying implementation details.

## Accounts and sessions

- Hash passwords with Argon2id; never store or log plaintext passwords.
- Short-lived signed access tokens (proposed 15 minutes) and random device refresh tokens (proposed 30 days). Store only refresh-token hashes on the server and tokens in the iOS Keychain.
- Rotate refresh tokens atomically; revoke the device session on reuse. Logout revokes that session. Access-token validation also checks session revocation.
- Serialize refreshes on the device so simultaneous requests share one refresh operation. Retry a failed authenticated request once after a successful refresh; preserve queued writes when refresh fails because the network is unavailable.
- Return a clear sign-in requirement after confirmed expiry/revocation; do not erase the local animal cache because a request timed out.
- Rate-limit login, registration, and recovery. Verification/reset tokens are hashed, expiring, and single-use. Email delivery needs a chosen SMTP/email provider before public signup is enabled.

FastAPI's official security guidance covers password hashing and bearer JWT validation: https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/ . Rotation, revocation, recovery, and offline syncing are additional proposed application work.

## Offline sync and conflicts

Keep the existing stable animal UUIDs and per-account stores. Introduce a durable outbox with a unique mutation ID, record ID, base revision, operation, and payload. The server records each mutation result in the same transaction as its data change, making retries safe.

Pull responses contain a server-issued opaque cursor. A per-account transactional change counter is locked until commit so changes cannot commit out of cursor order. Advance the local cursor only after the page has been saved successfully. Capture a sync watermark for consistent pagination.

If a live record has changed since its base revision, return a conflict with the server version. Keep both the pending local edit and server version and present a choice; do not silently replace one. Deletion tombstones win over stale updates. Keep tombstones until all supported clients have acknowledged them, or require a full resync when an old cursor expires.

Retry network errors, 429 (respecting Retry-After), and selected 5xx responses with a bounded exponential delay and jitter. Do not retry validation or access-denied errors automatically. Schedule a retry when network access returns and when the app foregrounds. iOS background execution is best effort, so always expose a manual retry and the last successful sync time.

## Migration from the existing project

1. Build and test the API locally with disposable users and a test database.
2. Add custom-API configuration to the Swift client; keep the Supabase implementation available until acceptance.
3. Export and back up current cloud data through an authorized admin workflow. Preserve user IDs and animal IDs. Original legacy SwiftData records still need an explicit ownership import.
4. Use a controlled password-reset flow for existing users unless a compatible password-hash migration is separately verified and approved. Do not pretend existing Supabase sessions will authenticate to the new service.
5. Test two accounts, two devices, network loss, token expiry, refresh races, stale edits, and deletions. Compare migrated record counts and spot-check records.
6. Switch the production API address only after approval. Keep the original database intact for an agreed rollback period.

## Implementation sequence and remaining cutover

Steps 1–3 now have a local implementation. Server checks passed; native iOS
acceptance and production work in step 4 remain outstanding.

1. Local FastAPI/PostgreSQL service, migrations, auth, and account-isolation tests.
2. Animal endpoints and revisioned sync, with duplicate-write, cursor, conflict, and deletion tests.
3. Swift client, Keychain storage, serialized refresh, retry queue, and visible connection state.
4. Mac simulator and device verification, migration rehearsal, then a separately approved deployment.

Feeding event history and vaccination event history are a later extension after the account/animal sync path is reliable. No production migration or account deletion is part of initial implementation approval.
