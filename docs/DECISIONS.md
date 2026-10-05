# Decisions made while building Phase 1

These are the choices that were made on your behalf. Each one can be changed
later if you disagree — none of them are permanent except the app's ID
(Decision 1). Ordered by importance.

---

### 1. App name and Android ID
- **Decided:** name **AgentPost**, Android ID **`in.agentpost.app`**
  (your choice from the 4 open decisions).
- **Why it matters:** the name can change later; the ID cannot once the app
  is on the Play Store.

### 2. Login: Google + email (your choice)
- Email/password works end-to-end now.
- The Google button **appears automatically** once you complete the free
  one-time setup in Google Cloud — steps are in
  [SETUP_GOOGLE_SIGN_IN.md](SETUP_GOOGLE_SIGN_IN.md). Until then the button
  is hidden and nothing breaks.
- Phone OTP (SMS) is deferred, as agreed — it needs a paid SMS provider and
  DLT registration in India.

### 3. State management: Riverpod (your choice)
- One well-known solution, used consistently everywhere.

### 4. Brand fonts (your choice): the 6 Gujarati-friendly fonts
- Noto Sans, Poppins, Mukta Vaani, Hind Vadodara, Baloo Bhai 2,
  Tiro Gujarati.
- Phase 1 stores the choice and shows it in the live preview. The actual
  font files for marketing materials arrive with the template system (Phase 2).
- In the preview, fonts are downloaded from Google's free font service the
  first time they are shown, then cached.

### 5. What `photo_url` / `logo_url` store
- **Decided:** these columns store the file's *location inside private
  storage* (e.g. `avatars/1f2e3d.../img_123.jpg`), not a full web link.
- **Why:** private files have expiring links; storing the location and
  creating a fresh short-lived link on every display is the standard, safest
  approach. Nothing changes from your point of view.

### 6. One form for onboarding and "Edit profile"
- The guided onboarding and the edit screen use literally the same form
  component, so they can never drift apart.
- **Required fields:** full name and mobile number (Indian format checked).
  Everything else is optional but recommended. "Skip for now" is allowed —
  and only flips the completion flag without wiping anything.

### 7. Areas / languages entered as comma-separated text
- "Surat, Vadodara, Rajkot" — simple and obvious for non-technical agents.
  Can be upgraded to fancy chips later without changing the database.

### 8. The colour picker is hand-built, not a library
- A small in-app picker: 8 curated presets + 3 sliders + hex code field.
  Avoided adding another third-party package.

### 9. Package list used in the Flutter app (all free, no new services)
| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management (your decision) |
| `go_router` | Screen navigation (required by the spec) |
| `supabase_flutter` | Talks to Supabase (login/database/files) |
| `image_picker` + `image_cropper` + `flutter_image_compress` | Photo upload with crop + compression (required by the spec) |
| `google_sign_in` | Google login (your decision) |
| `google_fonts` | Shows the brand fonts in the preview |
| `sentry_flutter` | Crash reporting (spec requirement; auto-off until you add a key) |

The admin dashboard uses: Next.js, Tailwind CSS, Supabase JS client, shadcn/
ui-style components (copied into the code by hand — see #12), lucide icons.

### 10. Mobile number validation
- The app requires a valid Indian mobile (10 digits starting 6–9; +91, 0,
  spaces and dashes accepted while typing). The database keeps a looser
  safety net (digits, 10–13 characters) so unusual-but-valid numbers can
  never be rejected at the storage level.

### 11. Accounts are fully created at sign-up
- Profile row, brand kit row (with default navy #173B63 / teal #0FA3B1,
  Noto Sans) and a `free` plan row are created automatically in one trigger.
- Default brand colours double as the app's own brand colours.

### 12. shadcn/ui components were copied by hand
- The shadcn online registry was unreachable from the build sandbox, so the
  standard components (button, card, input, table…) were copied from the
  well-known shadcn source into `admin/src/components/ui/`. They look and
  behave identically; this is exactly what shadcn/ui normally does
  (components live in your code).

### 13. Admin dashboard uses system fonts (no Google Fonts download)
- Simpler, works on any network, loads instantly. The main app keeps the
  Google Fonts package only for the brand preview.

### 14. Release builds are temporarily signed with the debug key
- So you can build and install an APK today. Proper Play Store signing is a
  later-phase task (it needs your Play Console account).

### 15. Placeholder launcher icon
- A clean navy gradient square stands in for the real app icon. Replace it
  when the logo is ready (the README of `app/` will note the folder).

### 16. Free-plan limits are NOT enforced yet (as agreed)
- But the `entitlements` table and its security rules are already in place:
  agents can read their plan, and only server code can change it — exactly
  what Phase 4 enforcement needs.

### 17. Sentry crash reporting is wired but silent until configured
- Build with `--dart-define=SENTRY_DSN=...` to switch it on (free tier is
  fine). No key → no crash reporting, no errors.

### 18. Email confirmation behaviour
- The local/dev Supabase config has email confirmations **disabled** (instant
  login after sign-up). If you switch confirmations on in production, the app
  already shows the right "check your inbox" message.

---

## Verification status in the build sandbox (honest notes)

- ✅ **Database:** rebuilt from the migration files on a real PostgreSQL and
  passed all **35 security tests** (cross-account read/modify/delete attacks,
  file storage attacks, self-upgrade attacks, admin read-only).
- ✅ **Admin dashboard:** `npm run build` and lint pass; login page renders;
  protected pages redirect to login when signed out.
- ⚠️ **Flutter app:** the sandbox could not download the Flutter SDK
  (network restrictions), so `flutter analyze` / `flutter test` / `flutter
  build apk` must be run on your machine — commands are in the README. The
  code passed a structural check (all files parse-balance, all imports
  resolve) and a test suite is included and ready to run.
