import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

/// Access to the profile repository.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

/// The signed-in agent's profile; reloads automatically when the user changes.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(authControllerProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
});

/// Saves a profile and refreshes everything that shows it.
class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> save(Profile profile) async {
    state = const AsyncLoading();
    try {
      await _ref.read(profileRepositoryProvider).saveProfile(profile);
      _ref.invalidate(profileProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// "Skip for now" during onboarding: only flips the completed flag.
  Future<bool> completeOnboarding() async {
    final user = _ref.read(authControllerProvider);
    if (user == null) return false;
    state = const AsyncLoading();
    try {
      await _ref.read(profileRepositoryProvider).completeOnboarding(user.id);
      _ref.invalidate(profileProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref);
});
