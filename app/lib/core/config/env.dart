/// App configuration values that are passed in when the app is built/run.
///
/// These are NOT secrets: the Supabase URL and the "anon" key are designed to
/// be visible inside the app (real security lives in the database rules).
/// The service-role key must NEVER be put here — see the repository README.
///
/// How values arrive (from the run command):
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class Env {
  const Env._();

  /// Address of your Supabase project.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Public "anon" API key of your Supabase project.
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Optional: Sentry crash-reporting key. When empty, crash reporting is
  /// simply switched off (perfectly fine for development).
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Optional: Google Sign-In client id. When empty, the "Google" button is
  /// hidden and email login still works. See docs/SETUP_GOOGLE_SIGN_IN.md.
  static const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// True when the two required values were provided.
  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// True when Google Sign-In was configured.
  static bool get isGoogleSignInEnabled => googleWebClientId.isNotEmpty;
}
