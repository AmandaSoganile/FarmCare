# FarmCare development handover

Updated 6 November 2026. Work is based on the latest uploaded FarmCare.zip,
not the older GitHub source. The updated project is being published on the
farmcare-custom-api branch at the user's request. No live migrations or
deployments have been made.

## New custom API implementation

The user authorized building our own API and phasing out Supabase. The local
implementation is in `backend/`; start with `backend/README.md`.

- FastAPI/PostgreSQL, SQLAlchemy/Alembic, hashed dependency locks, Compose, and
  private local configuration generation.
- Verification, login, rotating refresh tokens, logout, password recovery pages,
  retrying email outbox, Argon2id hashes, revocation, rate limits, and safe errors.
- Account-scoped animal endpoints, idempotent writes, revision conflicts,
  immutable changes with snapshot cursors, and deletion tombstones.
- Swift API client, per-origin Keychain tokens, serialized refresh, safe retries,
  account email screens, durable mutation queue, conflict review, and network
  restoration sync.
- `FARMCARE_BACKEND = custom` selects the new backend. Existing configurations
  without a selector still use Supabase; `supabase` explicitly selects rollback.
  Custom caches are isolated by origin/account. Old data is not imported or deleted.

Verified: 23 PostgreSQL integration tests; native API startup and HTTP readiness;
real Chromium verification, password recovery, login and animal-sync smoke checks;
Swift syntax, project/plist/asset parsing; Compose configuration parsing.

Unverified: Xcode compilation, simulator/device behavior, SwiftData runtime,
Keychain and native refresh races, app offline transitions, Docker build/run,
external SMTP, public hosting, data migration, and production cutover. The Python
suite passes with one upstream Starlette deprecation warning.

Next: perform Mac/two-device/offline acceptance checks from backend/README.md;
choose hosting, HTTPS, and email delivery; rehearse authorized migration with
preserved IDs and controlled account recovery; obtain production cutover
authorization. Remove the Supabase SDK after acceptance. Feeding/vaccination
event histories and remaining Settings work are still unfinished.

## Earlier uploaded context

The following describes the retained Supabase/UI baseline. The status and
authorization above supersede its old custom-API proposal.

## User's goal and preferences

Complete FarmCare, build our own API, connect it to the existing SwiftUI app, and improve the UI without a major redesign. The user reports that Supabase disconnects, but the live cause has not been diagnosed.

- The user works on macOS and cloned https://github.com/AmandaSoganile/FarmCare onto their Desktop.
- Ask before starting a new batch of implementation or an external change. Explain the concrete change for approval. Continue normally within a batch once approved.
- Use the owner's author identity without tooling attribution, co-author trailers, or added branding.
- Keep the FarmCare name, green identity, existing animal artwork, familiar screens, and Home/Add/Animals navigation.
- Do not push, deploy, migrate a live database, purchase hosting, or remove existing data without explicit approval.

## Which project to open

Use the latest FarmCare.zip delivered with this handover. Extract it separately from the original Desktop clone and open its FarmCare.xcodeproj. Earlier copies do not include all changes below.

If continuing in the existing Desktop clone, first inspect git status and compare files. Merge only intended source/documentation changes. Preserve the user's .git directory, local Secrets.xcconfig, signing configuration, uncommitted work, and any animal data. Do not replace the existing folder blindly.

The original uploaded ZIP included Git metadata. The updated downloadable ZIP
contains source, documentation, SQL migrations, and database tests, excluding
Git metadata and local credentials. GitHub branch downloads also exclude Git metadata.

## Retained Supabase implementation

Native SwiftUI iPhone/iPad application targeting iOS 26, built using Xcode 26 or later. It is not a native macOS app. It uses SwiftData for local animal records and the existing pinned Supabase Swift 2.5.1 SDK for authentication.

### Authentication and animal sync foundation

- Shared AuthViewModel follows authentication events and restores the session.
- Signup passes the name as user metadata; a database trigger creates the profile. When email confirmation is required, the UI asks the user to confirm and then sign in.
- Input/error/loading handling and actual Settings logout are implemented.
- Missing backend configuration shows a setup message instead of crashing.
- Separate SwiftData stores per user ID prevent different accounts sharing one local animal cache.
- Animal records use stable sync UUIDs, dirty flags, and revision identifiers. Local changes save first; queued changes can be retried.
- Animal upload/download uses Supabase REST; downloads are paginated. Deletions use retained tombstones; server logic prevents stale uploads resurrecting deleted records.
- The included SQL migration defines profiles, animals, account isolation policies, and profile/deletion triggers. It deliberately aborts for unknown existing policies instead of silently retaining permissive access.
- No migration was run against the user's live Supabase project.

### UI refresh included in this handover

- Shared FarmStyle/FarmCard/button styling with adaptive backgrounds and green accents.
- Cleaner dashboard totals, species cards, compact vaccination rows, and useful empty states.
- Grouped Add form with Cancel, validation, editable whole-kilogram weight, and species preselection when opened from a species list.
- Add tab returns to the previous screen behind its sheet.
- Search by animal name/breed, alphabetical animal lists, and deletion using the displayed filtered list.
- Profile care cards and explicit Save/Cancel for notes. Vaccination schedule badges replace the misleading frequency-based health dot.
- Calendar-day comparisons: a vaccination due today is not overdue until the next day.
- Compact sync indicator with Retry and expandable error details.
- Consistent welcome/signin/signup styling and a working system/light/dark appearance preference.
- Incomplete notification preferences are marked Planned; nonfunctional legal/help placeholders are not represented as completed features.

## Important files

| File or directory | Purpose |
| --- | --- |
| SETUP.md | Existing Supabase configuration and Mac verification steps |
| API_DESIGN.md | Proposed custom backend architecture, endpoints, auth, sync, and migration |
| UI_UPDATE.md | UI changes and manual acceptance checks |
| VALIDATION.md | Checks completed and limits |
| FarmCare/FarmCareApp.swift | Auth routing, per-account containers, sync status, appearance |
| FarmCare/Models/AuthViewModel.swift | Current Supabase auth flow |
| FarmCare/Models/AnimalSyncService.swift | Sync service, DTO, REST transport |
| FarmCare/Models/AnimalModel.swift | Animal data, sync fields, schedule calculations |
| FarmCare/Utilities/FarmStyle.swift | Shared UI styling and schedule badge |
| FarmCare/Utilities/Constants.swift | Validated Supabase configuration |
| supabase/migrations/ | SQL schema and access rules |
| supabase/tests/account_isolation.sql | Database assertions with rolled-back fixtures |
| validation/ | Repeatable embedded PostgreSQL test runner |

## Verification status

Passed here: database migration application/reapplication; account-isolation assertions; cross-account write/upsert denial; ownership transfer denial; tombstone protection; anonymous/hard-delete denial; fixture rollback; unknown-policy rejection; Swift syntax parsing; JSON/plist parsing; ZIP integrity.

NOT performed: Xcode compilation/type checking, simulator/device execution, SwiftData runtime checks, UI rendering, VoiceOver/Dynamic Type checks, live Supabase authentication or sync, or production deployment. Syntax parsing is not a successful Xcode build. The appearance preference and recent UI changes particularly need real device/simulator review.

To repeat database tests, from validation/: npm ci, then npm test. These use PGlite with a minimal mock Supabase auth schema; they do not test the hosted auth service.

## Connection findings and backend proposal

The current sync transport reads one access token for the whole sync, does not refresh/replay after a 401, does not automatically retry transient failures, and does not react to network restoration while continuously foregrounded. Errors lack request-level diagnostic context. These are possible contributors, not a confirmed explanation for the user's reported disconnects.

Proposed replacement: FastAPI + PostgreSQL, SQLAlchemy/Alembic migrations, and a small URLSession Swift client. Keep SwiftData and the UI. Own account authentication, Argon2id password hashes, short-lived access tokens, rotating device refresh tokens, Keychain storage, and email verification/recovery. Add account-scoped, idempotent, revisioned animal sync with conflict handling, deletion tombstones, bounded retries, and server cursors. Local development can use Docker Compose; production hosting/email providers remain undecided.

Read API_DESIGN.md for the architecture and backend/README.md for the local
implementation. The user approved API implementation and Swift integration.
Production deployment, live migration, and data removal still need separate
authorization.

## Data preservation

- The old shared SwiftData store is intentionally untouched and not automatically imported because it has no account ownership. Ask which account owns any existing records before importing.
- Do not uninstall the old app or delete local stores until records are safely backed up/migrated.
- Per-account unsynced changes remain on that device. Current live-record conflicts use last successful whole-record upload wins; the proposed custom API should improve this.
- Do not assume Supabase sessions will authenticate to the new API. Plan an approved account migration with preserved IDs; use password reset unless a compatible hash migration is verified.
- Only public anon/publishable keys belong in the existing app configuration. Keep admin keys and passwords out of the app, Git, and logs.

## Recommended next session in Xcode

1. Confirm this is the latest project, read repository instructions, inspect git status, and preserve local changes.
2. Build the existing app on an iOS 26 simulator. Fix compile errors before adding features. Obtain missing public configuration locally without requesting secret keys in chat.
3. Check navigation, Add-sheet dismissal, filtered deletion, notes Save/Cancel, appearance, accessibility text sizes, and vaccination date boundaries. Follow UI_UPDATE.md.
4. Report the build result and any reproducible connection failure; do not label all network errors as a Supabase outage.
5. Exercise the new custom API following backend/README.md; keep the Supabase path available until migration acceptance.
6. Keep feeding/vaccination histories and remaining settings on the completion list; they are not finished.

## Short prompt to start with

Read HANDOVER.md and the linked project documents. Confirm you are working in the latest FarmCare source, inspect the working tree, then build it in Xcode and report the first actionable errors. Preserve local work and data. Keep the UI changes modest and preserve the owner's attribution. The local custom API and integration are implemented; production deployment and live data migration still require explicit authorization.
