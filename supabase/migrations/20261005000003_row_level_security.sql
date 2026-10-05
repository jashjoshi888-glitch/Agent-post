-- ============================================================================
-- AgentPost — migration 3 of 5: Row Level Security (data privacy)
-- ============================================================================
-- Plain-language summary:
--   Row Level Security (RLS) is a PostgreSQL feature that makes the database
--   itself refuse to show one agent another agent's data — even if app code
--   has a bug. Think of it as: every request arrives with the user's ID card,
--   and each table only answers for rows owned by that ID card.
--
--   Rules implemented here:
--   * An agent can read and edit ONLY their own rows.
--   * Admins (rows in `admin_users`) can READ everything (for the dashboard),
--     but do not edit agent data.
--   * `entitlements` is server-managed: agents can read their own plan but
--     cannot create or change it (needed later for enforcing free-plan limits).
--   * `admin_users` write access is via the Supabase SQL editor only.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- is_admin(): "is the current user an admin?"
-- SECURITY DEFINER means the function may peek into `admin_users` without
-- giving normal users direct read access to the whole admin list.
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = (select auth.uid())
  );
$$;

revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;


-- ===========================================================================
-- profiles
-- ===========================================================================
alter table public.profiles enable row level security;

create policy "profiles_select_own_or_admin"
  on public.profiles for select
  to authenticated
  using (((select auth.uid()) = id) or public.is_admin());

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- No DELETE policy: rows are removed only when the auth user is deleted
-- (automatic via "on delete cascade") or by the service role.


-- ===========================================================================
-- brand_kits
-- ===========================================================================
alter table public.brand_kits enable row level security;

create policy "brand_kits_select_own_or_admin"
  on public.brand_kits for select
  to authenticated
  using (((select auth.uid()) = user_id) or public.is_admin());

create policy "brand_kits_insert_own"
  on public.brand_kits for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "brand_kits_update_own"
  on public.brand_kits for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);


-- ===========================================================================
-- admin_users
-- ===========================================================================
alter table public.admin_users enable row level security;

-- Users may read ONLY their own membership row (so the app can ask "am I an
-- admin?" without leaking the full admin list). Admins may see the full list.
create policy "admin_users_select_own_or_admin"
  on public.admin_users for select
  to authenticated
  using (((select auth.uid()) = user_id) or public.is_admin());

-- No insert/update/delete policies: the owner manages admins by running SQL
-- in the Supabase dashboard (which uses the service role and bypasses RLS).


-- ===========================================================================
-- legal_acceptances
-- ===========================================================================
alter table public.legal_acceptances enable row level security;

create policy "legal_acceptances_select_own_or_admin"
  on public.legal_acceptances for select
  to authenticated
  using (((select auth.uid()) = user_id) or public.is_admin());

create policy "legal_acceptances_insert_own"
  on public.legal_acceptances for insert
  to authenticated
  with check ((select auth.uid()) = user_id);


-- ===========================================================================
-- entitlements (server-managed)
-- ===========================================================================
alter table public.entitlements enable row level security;

-- Agents can only READ their own plan row. There are deliberately no
-- insert/update/delete policies: rows are created by the sign-up trigger and
-- changed later only by server code (service role) during Phase 4 payments.
create policy "entitlements_select_own_or_admin"
  on public.entitlements for select
  to authenticated
  using (((select auth.uid()) = user_id) or public.is_admin());
