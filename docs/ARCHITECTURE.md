# How AgentPost fits together (plain language)

This document explains the three main pieces and how they talk to each other.
No coding knowledge needed.

---

## The three pieces

```
 ┌─────────────────┐        ┌─────────────────┐        ┌──────────────────┐
 │   Android app   │  ────  │    Supabase     │  ────  │  Admin dashboard │
 │  (agent's phone)│        │ (the database)  │        │  (owner's browser)│
 └─────────────────┘        └─────────────────┘        └──────────────────┘
```

### 1. The Android app (`app/`, built with Flutter)

This is what agents install from the Play Store. Flutter is a toolkit that
lets one codebase produce an Android app (and, later, possibly other
platforms — but Android only for now).

Inside the app:

- **Login** (email/password now, Google button ready to switch on)
- **Onboarding** — one guided form: name, photo, mobile, agency, licence,
  areas served, languages. Filled in once, used everywhere.
- **Profile** tab — view and edit those details.
- **Brand kit** — logo, two brand colours, font choice, contact display,
  with a live preview card.
- **Home / Create / Customers** tabs — honest developer placeholders for
  now; filled in by later phases.

The app is organised in **feature folders** (`lib/features/...`), so each
feature (auth, profile, brand_kit…) keeps its own screens and data together.
All look-and-feel comes from **one theme file**
(`lib/core/theme/app_theme.dart`), which is what makes the app feel like one
premium product.

State management is **Riverpod**: a standard, well-documented way to keep
"who is logged in / what does their profile say" in one place and update all
screens automatically. Navigation uses **go_router** with one central rule:

> signed out → login screens; signed in but profile not finished →
> onboarding; otherwise → the main app.

### 2. Supabase (`supabase/`, the backend)

Supabase is our "database in the cloud". It provides four things:

- **Auth** — accounts, login, password reset. (Google and, later, phone
  login plug in here.)
- **PostgreSQL database** — five Phase-1 tables:
  - `profiles` — the agent's details
  - `brand_kits` — colours, logo, font
  - `entitlements` — which plan the agent is on (`free` / `pro`)
  - `admin_users` — who may use the admin dashboard
  - `legal_acceptances` — proof of accepting Terms/Privacy (texts come in
    Phase 4)
- **Storage** — two private file buckets: `avatars` (photos) and `logos`.
  Files are never publicly linkable; the app creates short-lived private
  links only for the owner.
- **Row Level Security (RLS)** — the privacy layer (see below).

**How the database protects agents (RLS).** Every request to the database
carries the user's identity. Each table has rules of the shape:

> "You may only read and edit rows where the user id is yours."

So even if the app had a bug and asked for someone else's data, the database
would simply return nothing. Admins may **read** everything (for the
dashboard) but edit nothing. Plans (`entitlements`) are **server-managed**:
agents can read their own plan but can never change it — this is what makes
the free-plan limits enforceable in Phase 4.

**What happens automatically at sign-up.** A trigger in the database creates
the agent's profile row, brand kit row (with sensible defaults) and a
`free` plan row at the exact moment the account is created.

**Files are stored like this:**

```
avatars/
   1f2e3d4c-…-aaaa/          ← folder named after the user's ID
        img_1728123456.jpg   ← the photo
logos/
   1f2e3d4c-…-aaaa/
        img_1728123999.jpg
```

The app saves only this *path* in the profile; a viewable link is generated
on the spot whenever the image is shown.

**Environments.** Everything is defined in migration files
(`supabase/migrations/`), so the whole database can be rebuilt from scratch:
you create an empty Supabase project, run `supabase db push`, and it is
identical. `agentpost-dev` for development now; a `production` project later —
the same files apply to both.

### 3. The admin dashboard (`admin/`, built with Next.js)

A small website for the owner. Login is restricted to people in the
`admin_users` table — checked on the server for every page (the browser
cannot bypass it). Phase 1 delivers the skeleton plus a working **Users**
list (all agents, read-only). Templates, Content, Subscriptions and
Analytics are placeholders for later phases.

---

## How a picture gets onto a profile (example flow)

1. Agent taps "Change photo".
2. The phone opens the gallery; the agent picks a photo.
3. The photo is cropped to a square and compressed (fast upload on mobile
   networks).
4. The app uploads it to the private `avatars` bucket **inside the agent's
   own folder**.
5. The app saves the file path on the profile row.
6. Whenever the photo is shown (app or admin dashboard), a short-lived
   private link is created — other agents can never access it.

---

## What comes in later phases (context only)

Templates and the Social Media Studio (Phase 2), the template CMS and
business card (Phase 3), CRM, reminders, payments, referrals and free-plan
limits (Phase 4). The database already contains the tables needed for those
limits and legal texts, so later work will not require re-designing Phase 1.
