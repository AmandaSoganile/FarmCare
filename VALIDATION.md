# Validation for this update

## Custom API — 6 November 2026

- **23 passed:** real PostgreSQL 17 integration tests, including migration
  consistency, verification/recovery, expiry, session revocation, concurrent
  refresh reuse, error privacy, rate limits, mail retry, profile protection,
  chunked body limits, account isolation, idempotency, conflicts, tombstones,
  snapshot pagination, cursor integrity, and transaction rollback.
- **Passed:** native Uvicorn startup/readiness and real Chromium verification
  and password-reset forms. Live API login, animal push/retry/pull, old-session
  revocation, old-password rejection, and new-password login passed.
- **Passed:** syntax parsing of 24 Swift files, Xcode project format, Info.plist,
  and asset JSON. Syntax parsing is not compilation or type checking.
- **Passed:** Compose configuration validation. Container build/run is unverified.
- **Warning:** Starlette deprecates its httpx TestClient adapter; no tests failed
  or were skipped because of it.

Unverified: Xcode, simulator/device execution, SwiftData, Keychain/native refresh
races, offline app relaunch, conflict UI behavior, external email delivery,
deployment, or existing-data migration. No live Supabase data was changed.

## Earlier uploaded baseline

Completed in the editing environment:

- Applied the database migration to embedded PostgreSQL (PGlite).
- Reapplied the migration to check that it can rerun.
- Executed the included SQL assertions for profile creation, private profile/animal reads, forbidden cross-account inserts/updates/upserts, ownership-transfer denial, deletion tombstones, client hard-delete denial, and anonymous access denial.
- Verified that SQL test fixtures roll back and that the migration aborts if an unknown permissive policy exists.
- Parsed all Swift source files with a Swift syntax parser: no syntax errors.
- Checked the authentication API signatures against the repository's pinned Supabase Swift 2.5.1 source.
- Checked the project plist and assets JSON files and verified the final ZIP contents.

Not completed here:

- Xcode compilation, simulator/device tests, SwiftData runtime migration behavior, and end-to-end tests against a hosted Supabase project. These need the Mac and project configuration; follow SETUP.md.

The UI refresh additionally passed source syntax checks; its Xcode build and rendered layout remain unverified. Follow UI_UPDATE.md.

No live database migrations, GitHub commits, or pushes were performed. This is the authentication/backend foundation, not completion of all app features.
