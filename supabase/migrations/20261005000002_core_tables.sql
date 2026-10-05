-- ============================================================================
-- AgentPost — migration 2 of 5: core tables
-- ============================================================================
-- Plain-language summary:
--   Creates the five Phase-1 tables. Each agent gets one row in `profiles`
--   (their details), one in `brand_kits` (their colours/logo/fonts) and one in
--   `entitlements` (their subscription plan). `admin_users` lists who may use
--   the admin dashboard. `legal_acceptances` records when someone accepted
--   our Terms / Privacy documents.
--
--   Notes for non-developers:
--   * `uuid` values are long random IDs that never repeat between users.
--   * Constraints below are safety nets (e.g. phone numbers must look like
--     phone numbers). The app applies friendlier validation before saving.
--   * No table is "publicly readable" — privacy is enforced in migration 3
--     with Row Level Security.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- profiles — one row per agent, created automatically at sign-up.
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,

  -- The `*_url` columns store a Storage FOLDER PATH (example:
  -- "avatars/1f2e3d.../avatar.jpg"), not a full web link. The app turns the
  -- path into a temporary private link whenever it needs to show the image.
  full_name text,
  photo_url text,
  mobile_whatsapp text,
  agency_name text,
  designation text,
  licence_number text,
  areas_served text[] not null default '{}',
  languages text[] not null default '{}',
  social_links jsonb not null default '{}'::jsonb,

  onboarding_completed boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint profiles_full_name_len
    check (full_name is null or char_length(full_name) between 1 and 120),
  constraint profiles_photo_url_len
    check (photo_url is null or char_length(photo_url) <= 512),
  -- 10–13 digits, optional leading "+" (the app checks the Indian format).
  constraint profiles_mobile_format
    check (mobile_whatsapp is null or mobile_whatsapp ~ '^\+?[0-9]{10,13}$'),
  constraint profiles_agency_len
    check (agency_name is null or char_length(agency_name) <= 120),
  constraint profiles_designation_len
    check (designation is null or char_length(designation) <= 80),
  constraint profiles_licence_len
    check (licence_number is null or char_length(licence_number) <= 60),
  constraint profiles_areas_max
    check (cardinality(areas_served) <= 25),
  constraint profiles_languages_max
    check (cardinality(languages) <= 12),
  constraint profiles_social_links_object
    check (jsonb_typeof(social_links) = 'object')
);

comment on table public.profiles is
  'One row per agent (customer of the app). Created automatically at sign-up.';
comment on column public.profiles.photo_url is
  'Storage object path inside the private "avatars" bucket, e.g. avatars/<user-id>/avatar.jpg';


-- ---------------------------------------------------------------------------
-- brand_kits — one row per agent: colours, logo, font, contact display.
-- ---------------------------------------------------------------------------
create table public.brand_kits (
  user_id uuid primary key references auth.users (id) on delete cascade,

  logo_url text,
  primary_color text not null default '#173B63',
  secondary_color text not null default '#0FA3B1',
  font_preference text not null default 'noto_sans',
  show_contact_details boolean not null default true,
  contact_mobile text,
  contact_email text,
  contact_website text,
  contact_address text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint brand_kits_logo_url_len
    check (logo_url is null or char_length(logo_url) <= 512),
  constraint brand_kits_primary_color_hex
    check (primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  constraint brand_kits_secondary_color_hex
    check (secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
  -- The curated font list agreed with the owner (6 fonts, Gujarati-friendly).
  constraint brand_kits_font_allowed
    check (font_preference in (
      'noto_sans', 'poppins', 'mukta_vaani',
      'hind_vadodara', 'baloo_bhai_2', 'tiro_gujarati'
    )),
  constraint brand_kits_contact_mobile
    check (contact_mobile is null or contact_mobile ~ '^\+?[0-9]{10,13}$'),
  constraint brand_kits_contact_email_len
    check (contact_email is null or char_length(contact_email) <= 254),
  constraint brand_kits_contact_website_len
    check (contact_website is null or char_length(contact_website) <= 254),
  constraint brand_kits_contact_address_len
    check (contact_address is null or char_length(contact_address) <= 300)
);

comment on table public.brand_kits is
  'One row per agent: brand colours, logo, font and contact details for materials.';
comment on column public.brand_kits.logo_url is
  'Storage object path inside the private "logos" bucket, e.g. logos/<user-id>/logo.png';


-- ---------------------------------------------------------------------------
-- admin_users — who may use the admin web dashboard (the owner).
-- Managed by hand in the Supabase SQL editor (see README).
-- ---------------------------------------------------------------------------
create table public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  added_at timestamptz not null default now(),
  note text
);

comment on table public.admin_users is
  'Admins of the app (the owner). Row presence = admin.';


-- ---------------------------------------------------------------------------
-- legal_acceptances — proof that a user accepted Terms / Privacy.
-- The document texts themselves arrive in Phase 4.
-- ---------------------------------------------------------------------------
create table public.legal_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  document_type text not null,
  document_version text not null,
  accepted_at timestamptz not null default now(),

  constraint legal_acceptances_document_type_allowed
    check (document_type in ('terms', 'privacy')),
  constraint legal_acceptances_version_len
    check (char_length(document_version) between 1 and 40)
);

create index legal_acceptances_user_idx
  on public.legal_acceptances (user_id, accepted_at desc);

comment on table public.legal_acceptances is
  'Records each time a user accepted a legal document (Terms/Privacy).';


-- ---------------------------------------------------------------------------
-- entitlements — subscription plan per user.
-- Every new user starts on the free plan. Only the server (Phase 4 payments)
-- may change this — users cannot edit their own plan.
-- ---------------------------------------------------------------------------
create table public.entitlements (
  user_id uuid primary key references auth.users (id) on delete cascade,
  plan text not null default 'free',
  source text not null default 'signup',
  valid_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint entitlements_plan_allowed
    check (plan in ('free', 'pro')),
  constraint entitlements_source_allowed
    check (source in ('signup', 'referral', 'payment', 'promo', 'manual'))
);

comment on table public.entitlements is
  'Subscription plan per user (free/pro). Server-managed; users can only read.';


-- ---------------------------------------------------------------------------
-- Keep updated_at fresh automatically.
-- ---------------------------------------------------------------------------
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger brand_kits_set_updated_at
  before update on public.brand_kits
  for each row execute function public.set_updated_at();

create trigger entitlements_set_updated_at
  before update on public.entitlements
  for each row execute function public.set_updated_at();
