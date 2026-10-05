# What the tests prove (and how to run them)

The Phase 1 acceptance criteria say:

> "A second test account **cannot** read or modify the first account's data
> or files (verified by tests)."

Four layers of tests prove this. Each layer catches what the previous one
cannot.

---

## 1. Static coverage check (runs in 1 second, no database)

```bash
npm run test:rls-coverage
```

**Proves:** every table created by the migration files has Row Level
Security switched on *and* at least one policy. If somebody adds a table
later and forgets privacy rules, this test fails immediately — even in the
cloud CI, before anything is deployed.

**Result in the build sandbox: PASSED (5/5 tables covered).**

---

## 2. Full database rebuild + attack simulation (real PostgreSQL, local)

```bash
npm install
npm run test:schema
```

**Proves two promises at once:**

1. *"The database can be rebuilt from migration files alone."* It creates an
   empty real PostgreSQL database (running inside Node — no Docker, no cloud
   account), applies every migration in order, and fails if anything breaks.
2. *The multi-tenancy promise.* It then creates two fake agents (A and B) and
   acts as each of them, using the real database security rules:
   - B cannot see A's profile, brand kit or plan
   - B cannot change A's profile or plan
   - B cannot insert rows on behalf of A
   - B cannot see, download, upload into or delete A's files
   - nobody can upgrade their own plan (server-managed)
   - admins can read everything but edit nothing
   - signed-out visitors see nothing
   - every sign-up automatically receives a `free` plan row

**Result in the build sandbox: PASSED (35/35 checks).**

---

## 3. pgTAP tests against a local Supabase stack

```bash
supabase start     # needs Docker + Supabase CLI
supabase test db
```

**Proves:** the same rules behave identically on the *real* Supabase
database (with its real `auth` and `storage` modules), covering 22 checks.

---

## 4. Live two-account verification against YOUR project (the final proof)

```bash
cp supabase/.env.example supabase/.env   # fill in URL + 2 keys
npm run test:rls-live
```

**Proves:** on your actual Supabase project (dev or production), two real
throwaway accounts are created, every cross-account attack is attempted
through the real API (including file storage), and the script prints a
PASS/FAIL list. It deletes the throwaway accounts afterwards.

**This is the run to paste into your records when signing off Phase 1.**

---

## App tests (Flutter)

```bash
cd app
flutter test        # unit + widget tests
flutter analyze     # code-quality check
```

Cover: Indian mobile-number validation, all form validators, the profile and
brand-kit data models, the curated font list, and the shared UI components
(loading/error/empty states).

## Admin dashboard checks

```bash
cd admin
npm run lint
npm run build
```

Both pass in the build sandbox. The build also verifies TypeScript types on
every page.

## Continuous integration (GitHub Actions)

Every push runs: the static RLS check + database rebuild/attack tests, the
admin lint + build, and the Flutter analyze + test (this last one runs on
GitHub's machines, which have full internet access). See
`.github/workflows/ci.yml`.
