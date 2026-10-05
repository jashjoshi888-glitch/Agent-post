-- ============================================================================
-- AgentPost — migration 5 of 5: automatic set-up for every new user
-- ============================================================================
-- Plain-language summary:
--   When somebody signs up, three rows must exist right away:
--     1. their profile row,
--     2. their brand kit row (with sensible default colours/font),
--     3. their entitlement row on the FREE plan.
--   This trigger creates them automatically at the moment the account is
--   created — so a brand-new user can never end up without a plan row.
-- ============================================================================


create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  -- Prefer the name given at sign-up; for Google sign-in fall back to the
  -- Google profile name; as a last resort use the part before "@" in the
  -- email address.
  v_name := nullif(
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    ''
  );

  insert into public.profiles (id, full_name)
  values (new.id, v_name);

  insert into public.brand_kits (user_id)
  values (new.id);

  insert into public.entitlements (user_id, plan, source)
  values (new.id, 'free', 'signup');

  return new;
end;
$$;


drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
