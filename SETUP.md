# FarmCare backend setup

**New custom API:** follow [backend/README.md](backend/README.md). The instructions
below describe the retained Supabase backend only. Do not run its migrations to
set up the new API; the new API uses its own PostgreSQL database and Alembic.

For the latest UI changes and continuation in Xcode, start with HANDOVER.md. API_DESIGN.md proposes a custom backend; the code below still uses Supabase.

This update prepares authentication and animal syncing. It does not create a hosted Supabase project or change the copy on your Desktop automatically.

## 1. Keep your current copy

Keep your original Desktop folder as a backup. Download the farmcare-custom-api
branch into a separate folder and open that folder's `FarmCare.xcodeproj`.
ZIP downloads contain source files without Git history; clone the branch if you
need its history locally.

Use Xcode 26 or later with an iOS 26 simulator. This project targets iPhone/iPad; running Xcode on a Mac does not make it a native macOS app. Select your own development team if running on a physical device.

## 2. Prepare Supabase

Use a development Supabase project first. In the SQL editor, run:

`supabase/migrations/202611030001_accounts_and_animals.sql`

The migration creates profiles, animals, account access policies, and profile/deletion triggers in one transaction. It also backfills profiles for existing accounts. Email/password authentication must be enabled in your project. Leave email confirmation enabled if you want verified accounts; the app now asks users to confirm their email before signing in.

If you already have profiles or animals tables, back up the database first. Unknown existing access policies deliberately stop the migration, because permissive policies can undermine account isolation. Share the error for review rather than dropping policies blindly. Existing unrelated triggers are not removed; any incompatible existing schema or trigger needs review.

To verify the hosted database, run `supabase/tests/account_isolation.sql` in the SQL editor of your development project. It uses two temporary test accounts and rolls all changes back. Do not run fixture tests against a production project with additional user-creation side effects.

## 3. Set the public connection values locally

Copy `FarmCare/Secrets.xcconfig.example` to `FarmCare/Secrets.xcconfig`. Fill in:

```text
SUPABASE_URL = YOUR_PROJECT_REF.supabase.co
SUPABASE_KEY = YOUR_PUBLIC_KEY
```

Use the project's public anon key or publishable key. Never place a service-role or secret key in the app. Use just the project hostname for the URL: `//` starts a comment in xcconfig files. The local file is ignored by Git. Missing configuration shows a setup message instead of crashing.

## 4. Build and check on your Mac

1. Open `FarmCare.xcodeproj` and allow Swift Package Manager to resolve the existing pinned dependencies.
2. Choose an iOS 26 simulator and press Command-R.
3. Create an account. With email confirmation enabled, verify the email and then sign in. Configure your Supabase confirmation success page as needed; this update uses manual return/sign-in, not a custom app deep link.
4. Try a wrong password and an invalid email; check the visible error and disabled button while a request is running.
5. Add animals from different species; edit an animal's notes and tap Done.
6. Wait for “Animals synced”; sign in to the same account on a second simulator/device and press Sync.
7. Delete an animal from one species list. Confirm the correct animal disappears on both devices after syncing.
8. Take a device offline, add/edit/delete animals, and confirm the changes remain locally. Reconnect and press Sync.
9. Edit an animal on an offline device, delete it on the other device, then reconnect the first device. The server tombstone must win.
10. Log out and sign in as a different account. The other account must not show the first account's animals. Return to the original account and confirm its records remain.
11. Relaunch to check session restoration. Log out from Settings to return to the welcome screen.

If Xcode reports an error, share the first error and its file/line. This update has not been compiled with Xcode in the editing environment.

## Sync behavior and limits

- Each account uses its own SwiftData store in `Application Support/FarmCareAccounts/<user-id>.store`.
- The previous shared SwiftData store is left intact and is not imported automatically: old records have no owner information. If you already entered animals in the old app, arrange an explicit import into the correct account before removing that store or uninstalling the app.
- Local changes are saved first. Upload errors keep changes queued on the device. Retry with Sync or by returning to the foreground. Signing out retains that account's queued changes locally.
- Sync runs after a local save, on sign-in/opening the account, on foreground, and through the Sync button. This is not continuous realtime or background sync; network restoration while the app stays open requires Sync.
- Remote records download in pages. Deleted records are retained as hidden tombstones locally and on the server so an offline device cannot restore them. There is no undelete UI.
- Concurrent edits to a live animal use last successful upload wins for the whole record. Edits made locally while a request is in flight stay queued for another sync. There is no field-level conflict merge.
- Local caches use the platform's normal storage protection, without an additional application encryption layer. No credential or backend admin key should be committed.
- Vaccination and feeding histories, password reset, live profile editing, health status correction, and remaining settings are outside this first phase.

## Repeat database tests locally (optional)

With Node.js installed, from the project folder:

```bash
cd validation
npm ci
npm test
```

The test uses embedded PostgreSQL through PGlite, with a small mock of Supabase's auth schema and roles. It verifies the actual migration and access policies, including cross-account upserts, anonymous reads, and stale uploads after deletion. It does not test Supabase's hosted authentication service or the iOS UI.
