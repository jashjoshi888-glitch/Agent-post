# AgentPost

**A premium Android app for insurance agents in Gujarat.** Agents get finished,
professional marketing material and a simple customer manager — no design
skills needed. Choose → personalize → share.

This repository currently contains **Phase 1 (Foundation)**:

- ✅ Flutter Android app: login, guided onboarding, profile, brand kit
- ✅ Secure Supabase database (each agent's data is private to them)
- ✅ Admin web dashboard with a working Users list
- ✅ Automated security tests (a second account cannot see the first one's data)

---

## What is where?

| Folder | What it is | Who runs it |
|---|---|---|
| `app/` | The Android app (Flutter) | Installed on agents' phones |
| `admin/` | The admin web dashboard (Next.js) | Owner, in a web browser |
| `supabase/` | Database structure + security rules + tests | Runs on Supabase servers |
| `docs/` | Plain-language explainers | For reading |
| `scripts/` + `supabase/tests/` | Automated tests | Run on a computer / in the cloud |

---

## First-time setup (about 30–45 minutes)

You only do this once. You do **not** need to be a developer.

### 1. Create a free Supabase account and project

1. Go to [supabase.com](https://supabase.com) and sign up (GitHub account works).
2. Click **New project**. Choose the free plan and a region close to India
   (e.g. Mumbai or Singapore). Name it `agentpost-dev`.
3. When the project is ready, open **Project Settings → API** and note down:
   - **Project URL** (looks like `https://xxxxxxxx.supabase.co`)
   - **anon public key** (a long text starting with `eyJ...`)
   - **service_role key** (keep this one secret — never in the app, never in Git)

### 2. Create the database

1. In GitHub: this repository → **Code** button → **Codespaces** → **Create codespace**
   (or ask your developer to run the commands locally).
2. Install the [Supabase CLI](https://supabase.com/docs/guides/cli) and log in:
   ```bash
   supabase login
   ```
3. Link to your project and push the database structure:
   ```bash
   supabase link --project-ref YOUR-PROJECT-REF
   supabase db push
   ```
   That's it — all tables, privacy rules and automatic setup are created from
   the files in `supabase/migrations/`.

### 3. Make yourself the admin

1. Sign up **once in the mobile app** (or at the Supabase dashboard under
   Authentication → Users) with your email.
2. In the Supabase dashboard, open **SQL Editor** and run:
   ```sql
   insert into public.admin_users (user_id, note)
   select id, 'owner' from auth.users where email = 'you@example.com';
   ```
   (replace `you@example.com` with your email)

### 4. Run the admin dashboard

```bash
cd admin
cp .env.example .env.local
# edit .env.local: paste your Project URL and anon key
npm install
npm run dev
```

Open http://localhost:3000 and log in with your admin account. Non-admin
accounts are refused.

### 5. Run the Android app

Install [Flutter](https://docs.flutter.dev/get-started/install) (and Android
Studio for the phone drivers), then:

```bash
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

Tip: save the command above in a small file (for example `app/run_dev.sh`)
so you can start the app with one click next time.

---

## How to check the security tests (the "A cannot see B's data" promise)

Three kinds of tests, fastest first:

```bash
# 1. Instant check (no database needed): every table has privacy rules.
npm run test:rls-coverage

# 2. Full rebuild + attack simulation on a real PostgreSQL running locally
#    inside Node (no Docker needed) — creates users A and B and proves the
#    database refuses every cross-account attack.
npm install
npm run test:schema

# 3. Against your REAL Supabase project (the final proof):
#    copy supabase/.env.example to supabase/.env and fill in your keys,
#    then:
npm run test:rls-live
```

The same database tests also run as pgTAP tests with the Supabase CLI:

```bash
supabase start      # needs Docker
supabase test db
```

---

## Important rules (so nothing breaks later)

1. **Never commit secrets.** No `.env` files, no service-role keys, no
   keystore files. Git history is public-ish; the repo is already set up to
   ignore these files.
2. **Database changes only through migration files** in
   `supabase/migrations/` — never edit the database only through the
   dashboard, or the rebuild-from-files promise breaks.
3. **Templates are data, not code** — coming in Phase 2.
4. Each agent must only ever see **their own** data. The database enforces
   this even if the app has a bug.

## Docs

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the pieces fit together (plain language)
- [docs/DECISIONS.md](docs/DECISIONS.md) — decisions made while building Phase 1
- [docs/TESTING.md](docs/TESTING.md) — exactly what each test proves
- [docs/SETUP_GOOGLE_SIGN_IN.md](docs/SETUP_GOOGLE_SIGN_IN.md) — one-time Google login setup
