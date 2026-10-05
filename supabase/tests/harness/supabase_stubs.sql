-- ============================================================================
-- Test harness stubs — NOT part of the real database.
-- ============================================================================
-- Plain-language summary:
--   The real Supabase project already has an `auth` schema (logins) and a
--   `storage` schema (file uploads). When we test the database on a plain
--   PostgreSQL without Supabase (for example inside our CI pipeline), those
--   schemas don't exist — so this file recreates small stand-ins for them.
--
--   The stubs are intentionally minimal: just enough for the real migration
--   files and their security rules to run unchanged and be tested.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- Roles that Supabase always has.
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin;
  end if;
end
$$;


-- ---------------------------------------------------------------------------
-- auth schema stand-in: the users table + auth.uid().
-- ---------------------------------------------------------------------------
create schema if not exists auth;

create table auth.users (
  id uuid primary key,
  email text,
  raw_user_meta_data jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Same logic as Supabase's auth.uid(): read the user id from the "JWT claims"
-- that Supabase attaches to every request.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(
    coalesce(
      current_setting('request.jwt.claim.sub', true),
      (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    ), ''
  )::uuid
$$;

grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;


-- ---------------------------------------------------------------------------
-- storage schema stand-in: buckets + objects + foldername().
-- ---------------------------------------------------------------------------
create schema if not exists storage;

create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);

create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null references storage.buckets (id),
  name text not null,
  owner uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Supabase helper: the folders of a file path, e.g. 'a/b/c.jpg' -> {a, b}.
create or replace function storage.foldername(name text)
returns text[]
language sql
immutable
as $$
  select (string_to_array(name, '/'))[1 : array_length(string_to_array(name, '/'), 1) - 1]
$$;

grant usage on schema storage to anon, authenticated, service_role;
grant select, insert, update, delete on storage.buckets to anon, authenticated, service_role;
grant select, insert, update, delete on storage.objects to anon, authenticated, service_role;
grant execute on function storage.foldername(text) to anon, authenticated, service_role;

-- The real storage.objects table has RLS enabled; mirror that here so our
-- policies are tested under the same conditions.
alter table storage.objects enable row level security;


-- ---------------------------------------------------------------------------
-- Default privileges, matching what Supabase grants on the public schema.
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;
