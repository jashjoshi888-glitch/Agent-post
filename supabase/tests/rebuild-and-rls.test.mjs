/**
 * rebuild-and-rls.test.mjs — full database rebuild + security tests.
 *
 * Plain language:
 *   This test proves two important promises from the spec:
 *
 *   1. "The database can be rebuilt from migration files alone."
 *      It starts an empty real PostgreSQL database (running locally in Node,
 *      no Docker or cloud needed), applies every migration file in order, and
 *      fails if anything breaks.
 *
 *   2. "A second test account cannot read or modify the first account's
 *      data or files."
 *      It creates two fake agents (A and B), then acts as each of them in
 *      turn and checks the database refuses cross-account access — using the
 *      real Row Level Security rules, not a simulation.
 *
 * Run with:  npm run test:schema
 */
import { PGlite } from '@electric-sql/pglite';
import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.join(here, '..', '..');
const migrationsDir = path.join(here, '..', 'migrations');
const stubsPath = path.join(here, 'harness', 'supabase_stubs.sql');

// Fixed IDs for the fake agents, so test output is readable.
const USER_A = '11111111-1111-1111-1111-111111111111';
const USER_B = '22222222-2222-2222-2222-222222222222';
const USER_ADMIN = '33333333-3333-3333-3333-333333333333';

let passed = 0;
let failed = 0;

function check(name, ok, detail = '') {
  if (ok) {
    passed++;
    console.log(`✓ ${name}`);
  } else {
    failed++;
    console.error(`✗ ${name}${detail ? ` — ${detail}` : ''}`);
  }
}

async function expectThrows(name, promise) {
  try {
    await promise;
    check(name, false, 'expected the database to refuse, but it succeeded');
  } catch (err) {
    check(name, true, `refused with: ${String(err.message ?? err).split('\n')[0]}`);
    // print the refusal reason as info
  }
}

/** Pretend to be a signed-in user from here on. */
async function actAs(db, userId) {
  await db.exec('reset role');
  await db.query(`select set_config('request.jwt.claims', $1, false)`, [
    JSON.stringify({ sub: userId, role: 'authenticated' }),
  ]);
  await db.exec('set role authenticated');
}

/** Go back to being the database superuser (the "server"). */
async function actAsServer(db) {
  await db.exec('reset role');
  await db.exec(`select set_config('request.jwt.claims', '', false)`);
}

async function count(db, sql, params = []) {
  const res = await db.query(sql, params);
  return Number(res.rows[0].n);
}

// ---------------------------------------------------------------------------
// 1. Build the database from scratch.
// ---------------------------------------------------------------------------
console.log('Rebuilding database from migration files...');

const db = new PGlite();

await db.exec(readFileSync(stubsPath, 'utf8'));

// Supabase-style grants on the stub tables.
await db.exec(`
  grant select, insert, update, delete on auth.users to service_role;
`);

const migrationFiles = readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).sort();
let rebuildOk = true;
let rebuildError = '';
for (const f of migrationFiles) {
  try {
    await db.exec(readFileSync(path.join(migrationsDir, f), 'utf8'));
    console.log(`  applied ${f}`);
  } catch (err) {
    rebuildOk = false;
    rebuildError = `${f}: ${String(err.message ?? err).split('\n')[0]}`;
    break;
  }
}
check('database rebuilds from migration files alone', rebuildOk, rebuildError);
if (!rebuildOk) {
  console.error('\nFAILED: cannot continue without a database.');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// 2. Row Level Security must be switched on for every user-data table.
// ---------------------------------------------------------------------------
const userTables = ['profiles', 'brand_kits', 'admin_users', 'legal_acceptances', 'entitlements'];
for (const t of userTables) {
  const res = await db.query(
    `select relrowsecurity as on from pg_class where oid = 'public.${t}'::regclass`
  );
  check(`RLS is enabled on ${t}`, res.rows[0].on === true);
}

// ---------------------------------------------------------------------------
// 3. Sign-up automatically creates profile, brand kit and free plan rows.
// ---------------------------------------------------------------------------
console.log('\nSimulating two sign-ups (users A and B)...');
await actAsServer(db);
await db.query(
  `insert into auth.users (id, email, raw_user_meta_data) values ($1, $2, $3)`,
  [USER_A, 'agent-a@example.com', JSON.stringify({ full_name: 'Agent A' })]
);
await db.query(
  `insert into auth.users (id, email, raw_user_meta_data) values ($1, $2, $3)`,
  [USER_B, 'agent-b@example.com', JSON.stringify({ full_name: 'Agent B' })]
);

check('sign-up creates a profile row', (await count(db, `select count(*) as n from public.profiles where id = $1`, [USER_A])) === 1);
check('sign-up creates a brand kit row', (await count(db, `select count(*) as n from public.brand_kits where user_id = $1`, [USER_A])) === 1);
check(
  'sign-up creates a FREE entitlement row',
  (await count(db, `select count(*) as n from public.entitlements where user_id = $1 and plan = 'free' and source = 'signup'`, [USER_A])) === 1
);
check(
  'brand kit gets sensible defaults',
  (await count(db, `select count(*) as n from public.brand_kits where user_id = $1 and font_preference = 'noto_sans'`, [USER_A])) === 1
);

// ---------------------------------------------------------------------------
// 4. Each user sees ONLY their own data.
// ---------------------------------------------------------------------------
console.log('\nActing as user A...');
await actAs(db, USER_A);

check('A sees exactly 1 profile (their own)', (await count(db, `select count(*) as n from public.profiles`)) === 1);
check('A sees exactly 1 brand kit (their own)', (await count(db, `select count(*) as n from public.brand_kits`)) === 1);
check('A sees exactly 1 entitlement (their own)', (await count(db, `select count(*) as n from public.entitlements`)) === 1);
check('A cannot see the admin list', (await count(db, `select count(*) as n from public.admin_users`)) === 0);

// A edits their own profile — this SHOULD work.
await db.query(`update public.profiles set agency_name = 'A Insurance' where id = $1`, [USER_A]);
check('A can edit their own profile', (await count(db, `select count(*) as n from public.profiles where id = $1 and agency_name = 'A Insurance'`, [USER_A])) === 1);

// ---------------------------------------------------------------------------
// 5. The cross-account attack tests: B versus A.
// ---------------------------------------------------------------------------
console.log('\nActing as user B (attacking user A)...');
await actAs(db, USER_B);

check('B sees exactly 1 profile (their own, not A)', (await count(db, `select count(*) as n from public.profiles`)) === 1);
check('B cannot see A\'s profile', (await count(db, `select count(*) as n from public.profiles where id = $1`, [USER_A])) === 0);
check('B cannot see A\'s brand kit', (await count(db, `select count(*) as n from public.brand_kits where user_id = $1`, [USER_A])) === 0);
check('B cannot see A\'s entitlement', (await count(db, `select count(*) as n from public.entitlements where user_id = $1`, [USER_A])) === 0);

// B tries to overwrite A's profile. RLS makes this a silent no-op (0 rows).
await db.query(`update public.profiles set full_name = 'HACKED', agency_name = 'HACKED' where id = $1`, [USER_A]);
check('B cannot modify A\'s profile', (await count(db, `select count(*) as n from public.profiles where id = $1 and full_name = 'HACKED'`, [USER_A])) === 0);

// B tries to insert a legal acceptance on behalf of A — must be refused.
await expectThrows(
  'B cannot insert legal_acceptances for A',
  db.query(`insert into public.legal_acceptances (user_id, document_type, document_version) values ($1, 'terms', 'v1')`, [USER_A])
);

// B tries to upgrade A's plan — must fail (silent no-op, plan stays 'free').
await db.query(`update public.entitlements set plan = 'pro' where user_id = $1`, [USER_A]);
check('B cannot change A\'s plan', (await count(db, `select count(*) as n from public.entitlements where user_id = $1 and plan = 'pro'`, [USER_A])) === 0);

// ---------------------------------------------------------------------------
// 6. Even against THEMSELVES, users cannot tamper with plans.
// ---------------------------------------------------------------------------
console.log('\nActing as user A again (self-service attacks)...');
await actAs(db, USER_A);

await expectThrows(
  'A cannot create entitlements rows by hand',
  db.query(`insert into public.entitlements (user_id, plan) values ($1, 'pro')`, [USER_A])
);

await db.query(`update public.entitlements set plan = 'pro' where user_id = $1`, [USER_A]);
check('A cannot upgrade their own plan', (await count(db, `select count(*) as n from public.entitlements where user_id = $1 and plan = 'free'`, [USER_A])) === 1);

// ---------------------------------------------------------------------------
// 7. File storage: same rules for uploaded files.
// ---------------------------------------------------------------------------
console.log('\nTesting file storage rules (avatars)...');
await actAsServer(db);
await db.query(`insert into storage.objects (bucket_id, name, owner) values ('avatars', $1, $2)`, [`${USER_A}/avatar.jpg`, USER_A]);

await actAs(db, USER_A);
check('A can see their own uploaded file', (await count(db, `select count(*) as n from storage.objects where name = $1`, [`${USER_A}/avatar.jpg`])) === 1);

await actAs(db, USER_B);
check('B cannot see A\'s file', (await count(db, `select count(*) as n from storage.objects where bucket_id = 'avatars'`)) === 0);
await expectThrows(
  'B cannot upload a file into A\'s folder',
  db.query(`insert into storage.objects (bucket_id, name, owner) values ('avatars', $1, $2)`, [`${USER_A}/evil.png`, USER_B])
);
// B tries to delete A's file. Like updates, RLS turns this into a silent
// no-op: the command "runs" but deletes 0 rows because B cannot see the file.
await db.query(`delete from storage.objects where name = $1`, [`${USER_A}/avatar.jpg`]);
await actAsServer(db);
check('B cannot delete A\'s file (it survives)', (await count(db, `select count(*) as n from storage.objects where name = $1`, [`${USER_A}/avatar.jpg`])) === 1);
await actAs(db, USER_B);

await db.query(`insert into storage.objects (bucket_id, name, owner) values ('avatars', $1, $2)`, [`${USER_B}/ok.png`, USER_B]);
check('B can upload files to their own folder', (await count(db, `select count(*) as n from storage.objects where name = $1`, [`${USER_B}/ok.png`])) === 1);

// ---------------------------------------------------------------------------
// 8. Admin can read (but not edit) everyone — for the dashboard.
// ---------------------------------------------------------------------------
console.log('\nActing as an admin...');
await actAsServer(db);
await db.query(`insert into auth.users (id, email) values ($1, 'owner@example.com')`, [USER_ADMIN]);
await db.query(`insert into public.admin_users (user_id) values ($1)`, [USER_ADMIN]);

await actAs(db, USER_ADMIN);
check('admin can see all 3 profiles', (await count(db, `select count(*) as n from public.profiles`)) === 3);
check('admin can see all entitlements', (await count(db, `select count(*) as n from public.entitlements`)) === 3);
check('admin can see uploaded files', (await count(db, `select count(*) as n from storage.objects`)) === 2);

await db.query(`update public.profiles set full_name = 'ADMIN HACK' where id = $1`, [USER_A]);
check('admin cannot edit agent profiles', (await count(db, `select count(*) as n from public.profiles where id = $1 and full_name = 'ADMIN HACK'`, [USER_A])) === 0);

// ---------------------------------------------------------------------------
// 9. Anonymous (signed out) visitors see nothing at all.
// ---------------------------------------------------------------------------
await db.exec('reset role');
await db.exec(`select set_config('request.jwt.claims', '', false)`);
await db.exec('set role anon');
check('signed-out visitors see no profiles', (await count(db, `select count(*) as n from public.profiles`)) === 0);
check('signed-out visitors see no files', (await count(db, `select count(*) as n from storage.objects`)) === 0);
await db.exec('reset role');

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log('\n----------------------------------------');
console.log(`PASSED: ${passed}   FAILED: ${failed}`);
if (failed > 0) {
  process.exit(1);
}
console.log('All database rebuild + security tests passed.');
