# One-time setup: Google Sign-In (about 15 minutes, free)

The app already supports Google login — the button simply stays hidden until
you complete this one-time setup. **Email login works fine without it.**

1. **Go to the Google Cloud Console:** [console.cloud.google.com](https://console.cloud.google.com)
   (use your Google account; no payment needed).

2. **Create a project:** click the project dropdown at the top →
   **New Project** → name it `AgentPost` → **Create**.

3. **Configure the OAuth consent screen:**
   - Left menu → **APIs & Services → OAuth consent screen**.
   - User type: **External** → **Create**.
   - App name: `AgentPost`, support email: your email → **Save and continue**
     through the screens (you can skip scopes and test users for now).

4. **Create credentials:**
   - **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
   - Application type: **Android**.
     - Package name: `in.agentpost.app`
     - SHA-1 certificate fingerprint: run this command in the `app/` folder
       (the same computer that builds the app):
       ```bash
       cd android && ./gradlew signingReport
       ```
       Copy the `SHA1` value of the `debug` variant (proper release SHA-1
       comes when Play Store signing is set up).
   - Click **Create** again, this time application type: **Web application**.
     - Name: `AgentPost-server`.
     - Add your email under **Authorized redirect URIs** as:
       `https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback`
       (replace with your Supabase project URL).
   - Note down the **Web client ID** (ends in `.apps.googleusercontent.com`).

5. **Tell Supabase about Google:**
   - Supabase dashboard → **Authentication → Sign In / Providers → Google**.
   - Paste the Web client ID and the Web client secret from step 4 → **Save**.

6. **Tell the app about Google** — when running/building the app, add one
   more flag to the `flutter run` / `flutter build` command:
   ```
   --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```
   The "Continue with Google" button appears automatically.

That's it. If anything is unclear, this official Supabase guide covers the
same steps with screenshots:
[Supabase → Sign in with Google (Android)](https://supabase.com/docs/guides/auth/social-login/auth-google)
