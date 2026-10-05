import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

/// Everything to do with logging in and out, in one place.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  /// Email + password sign-up. [fullName] is stored so the app can greet the
  /// agent by name right away.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  /// Email + password login.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Google Sign-In (only when configured — see docs/SETUP_GOOGLE_SIGN_IN.md).
  ///
  /// Returns false when Google Sign-In is not configured, so the UI can show
  /// email-only login without breaking.
  Future<bool> signInWithGoogle() async {
    if (!Env.isGoogleSignInEnabled) return false;

    final googleSignIn = GoogleSignIn(
      scopes: const ['email'],
      serverClientId: Env.googleWebClientId,
    );
    final account = await googleSignIn.signIn();
    if (account == null) return false; // agent cancelled

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const AuthException('Google sign-in did not return a token. Please try again.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
    return true;
  }

  /// Sends a password-reset email.
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
