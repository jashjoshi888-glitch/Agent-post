import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

/// Reads and writes the agent's profile row.
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Loads the profile of [userId]. Returns null when the row does not exist
  /// (should not happen — rows are created automatically at sign-up).
  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(row));
  }

  /// Saves the profile (insert or update — either works with these fields).
  Future<void> saveProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toMap());
  }

  /// Marks onboarding as complete WITHOUT touching any other field
  /// (used by the "Skip for now" button).
  Future<void> completeOnboarding(String userId) async {
    await _client
        .from('profiles')
        .update({'onboarding_completed': true}).eq('id', userId);
  }
}
