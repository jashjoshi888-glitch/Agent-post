-- ============================================================================
-- AgentPost — pgTAP security tests (Row Level Security)
-- ============================================================================
-- Plain-language summary:
--   These tests run against a REAL local Supabase database and prove that
--   user A can never read or modify user B's rows.
--
--   How to run (needs the Supabase CLI + Docker):
--       supabase start
--       supabase test db
--
--   Note: this file creates two throwaway users with fixed IDs
--   (1111... and 2222...) inside a transaction and rolls everything back
--   at the end, so nothing is left behind.
-- ============================================================================

begin;

create extension if not exists pgtap;

-- Two fake agents, created exactly like real sign-ups (the trigger fires).
insert into auth.users (id, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'pgtap-a@example.com', '{"full_name":"Pgtap A"}'),
  ('22222222-2222-2222-2222-222222222222', 'pgtap-b@example.com', '{"full_name":"Pgtap B"}');

select plan(22);

-- ---------------------------------------------------------------------------
-- 1–5: Row Level Security must be switched on everywhere.
-- ---------------------------------------------------------------------------
select ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'RLS enabled on profiles'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.brand_kits'::regclass),
  'RLS enabled on brand_kits'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.admin_users'::regclass),
  'RLS enabled on admin_users'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.legal_acceptances'::regclass),
  'RLS enabled on legal_acceptances'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.entitlements'::regclass),
  'RLS enabled on entitlements'
);

-- ---------------------------------------------------------------------------
-- 6–8: every new user is set up automatically, on the free plan.
-- ---------------------------------------------------------------------------
select is(
  (select plan from public.entitlements where user_id = '11111111-1111-1111-1111-111111111111'),
  'free',
  'new user A automatically gets a free entitlement'
);
select is(
  (select source from public.entitlements where user_id = '22222222-2222-2222-2222-222222222222'),
  'signup',
  'entitlement source is signup'
);
select is(
  (select full_name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'Pgtap A',
  'profile created with the name given at sign-up'
);

-- ---------------------------------------------------------------------------
-- 9–13: acting as user A.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
set local role authenticated;

select is(
  (select count(*)::int from public.profiles), 1,
  'A sees exactly one profile (their own)'
);
select is(
  (select count(*)::int from public.brand_kits), 1,
  'A sees exactly one brand kit (their own)'
);
select is(
  (select count(*)::int from public.entitlements), 1,
  'A sees exactly one entitlement (their own)'
);
select is(
  (select count(*)::int from public.admin_users), 0,
  'A cannot read the admin list'
);
select lives_ok(
  $$ update public.profiles set agency_name = 'A Agency'
     where id = '11111111-1111-1111-1111-111111111111' $$,
  'A can edit their own profile'
);

reset role;

-- ---------------------------------------------------------------------------
-- 14–18: acting as user B, attacking user A.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
set local role authenticated;

select is(
  (select count(*)::int from public.profiles where id = '11111111-1111-1111-1111-111111111111'), 0,
  'B cannot see A''s profile'
);
select is(
  (select count(*)::int from public.brand_kits where user_id = '11111111-1111-1111-1111-111111111111'), 0,
  'B cannot see A''s brand kit'
);
select lives_ok(
  $$ update public.profiles set full_name = 'HACKED'
     where id = '11111111-1111-1111-1111-111111111111' $$,
  'B''s update on A runs but is a silent no-op (checked next)'
);
reset role;
select is(
  (select full_name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'Pgtap A',
  'A''s profile was NOT modified by B'
);
set local role authenticated;

select throws_ok(
  $$ insert into public.legal_acceptances (user_id, document_type, document_version)
     values ('11111111-1111-1111-1111-111111111111', 'terms', 'v1') $$,
  '42501', null,
  'B cannot insert legal acceptances on behalf of A'
);
select throws_ok(
  $$ insert into public.entitlements (user_id, plan) values ('11111111-1111-1111-1111-111111111111', 'pro') $$,
  '42501', null,
  'B cannot create entitlements for A'
);

-- ---------------------------------------------------------------------------
-- 19–20: plans are server-managed — nobody can edit their own.
-- ---------------------------------------------------------------------------
reset role;
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$ update public.entitlements set plan = 'pro'
     where user_id = '11111111-1111-1111-1111-111111111111' $$,
  'A''s self-upgrade is a silent no-op'
);
reset role;
select is(
  (select plan from public.entitlements where user_id = '11111111-1111-1111-1111-111111111111'),
  'free',
  'A''s plan is still free (self-upgrade failed)'
);

-- ---------------------------------------------------------------------------
-- 21–22: signed-out visitors see nothing.
-- ---------------------------------------------------------------------------
set local role anon;
select is(
  (select count(*)::int from public.profiles), 0,
  'signed-out visitors see no profiles'
);
select is(
  (select count(*)::int from public.entitlements), 0,
  'signed-out visitors see no entitlements'
);

reset role;
select * from finish();
rollback;
