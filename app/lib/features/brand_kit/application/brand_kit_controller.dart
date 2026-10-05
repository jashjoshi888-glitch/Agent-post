import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_controller.dart';
import '../data/brand_kit_repository.dart';
import '../domain/brand_kit.dart';

/// Access to the brand kit repository.
final brandKitRepositoryProvider = Provider<BrandKitRepository>((ref) {
  return BrandKitRepository(Supabase.instance.client);
});

/// The signed-in agent's brand kit; reloads when the user changes.
final brandKitProvider = FutureProvider<BrandKit>((ref) async {
  final user = ref.watch(authControllerProvider);
  if (user == null) return BrandKit(userId: '');
  return ref.watch(brandKitRepositoryProvider).fetchBrandKit(user.id);
});

/// Saves the brand kit and refreshes everything that shows it.
class BrandKitController extends StateNotifier<AsyncValue<void>> {
  BrandKitController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> save(BrandKit kit) async {
    state = const AsyncLoading();
    try {
      await _ref.read(brandKitRepositoryProvider).saveBrandKit(kit);
      _ref.invalidate(brandKitProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final brandKitControllerProvider =
    StateNotifierProvider<BrandKitController, AsyncValue<void>>((ref) {
  return BrandKitController(ref);
});
