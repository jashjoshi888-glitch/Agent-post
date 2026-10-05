import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

/// Access to the auth repository (login/signup/logout).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

/// The current signed-in user, kept up to date automatically.
///
/// This is the single source of truth for "who is logged in":
/// the router and every screen watch this provider.
class AuthController extends StateNotifier<User?> {
  AuthController(this._repository) : super(_repository.currentUser) {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;

  Future<void> signOut() => _repository.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, User?>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
