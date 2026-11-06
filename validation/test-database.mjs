import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const db = new PGlite();
await db.exec(`
create role anon; create role authenticated;
create schema auth;
create table auth.users(id uuid primary key, email text, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as
$$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema public, auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
`);
const root = fileURLToPath(new URL('..', import.meta.url)).replace(/\/$/, '');
const migration = readFileSync(root+'/supabase/migrations/202611030001_accounts_and_animals.sql','utf8');
await db.exec(migration);
console.log('PASS: migration applies');
await db.exec(migration);
console.log('PASS: migration reruns without destroying records');
await db.exec(readFileSync(root+'/supabase/tests/account_isolation.sql','utf8'));
console.log('PASS: profile creation, owner reads, cross-account reads/writes/upserts, ownership transfer, tombstones, hard delete denial, anonymous access');
const fixtures = await db.query('select count(*)::int as count from auth.users');
if (fixtures.rows[0].count !== 0) throw new Error('Fixtures were not rolled back');
console.log('PASS: test fixtures rolled back');
await db.exec('create policy unexpected_policy on public.animals for select using (true)');
try { await db.exec(migration); throw new Error('Migration allowed unexpected policy'); }
catch(error) {
 if (!error.message.includes('Existing profiles/animals access policies need review')) throw error;
 await db.exec('rollback');
}
console.log('PASS: migration aborts on unknown permissive policies');
await db.close();
