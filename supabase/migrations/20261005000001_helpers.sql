-- ============================================================================
-- AgentPost — migration 1 of 5: helper functions
-- ============================================================================
-- Plain-language summary:
--   This file creates small helper functions used by the rest of the database.
--   Everything is created with "create or replace" so the whole database can be
--   rebuilt from these migration files alone.
--
--   set_updated_at(): a trigger function that stamps rows with the current
--   time whenever they are edited (so we always know when data last changed).
-- ============================================================================


-- Runs before every UPDATE on tables that have an `updated_at` column.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
