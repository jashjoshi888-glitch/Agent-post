import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/brand_kit.dart';

/// Reads and writes the agent's brand kit row.
class BrandKitRepository {
  BrandKitRepository(this._client);

  final SupabaseClient _client;

  /// Loads the brand kit of [userId]. Falls back to sensible defaults when
  /// the row does not exist yet (the row is created at sign-up, but the app
  /// must never crash if it is missing).
  Future<BrandKit> fetchBrandKit(String userId) async {
    final row = await _client
        .from('brand_kits')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return BrandKit(userId: userId);
    return BrandKit.fromMap(Map<String, dynamic>.from(row));
  }

  /// Saves the brand kit (insert or update).
  Future<void> saveBrandKit(BrandKit kit) async {
    await _client.from('brand_kits').upsert(kit.toMap());
  }
}
