/// The agent's profile — matches the `profiles` table in Supabase.
class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.photoUrl,
    this.mobileWhatsapp,
    this.agencyName,
    this.designation,
    this.licenceNumber,
    this.areasServed = const [],
    this.languages = const [],
    this.socialLinks = const {},
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String? photoUrl;
  final String? mobileWhatsapp;
  final String? agencyName;
  final String? designation;
  final String? licenceNumber;
  final List<String> areasServed;
  final List<String> languages;
  final Map<String, dynamic> socialLinks;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      mobileWhatsapp: map['mobile_whatsapp'] as String?,
      agencyName: map['agency_name'] as String?,
      designation: map['designation'] as String?,
      licenceNumber: map['licence_number'] as String?,
      areasServed: _stringList(map['areas_served']),
      languages: _stringList(map['languages']),
      socialLinks: Map<String, dynamic>.from(map['social_links'] as Map? ?? {}),
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
    );
  }

  /// Only the fields the app may write — matches the table's column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'photo_url': photoUrl,
      'mobile_whatsapp': mobileWhatsapp,
      'agency_name': agencyName,
      'designation': designation,
      'licence_number': licenceNumber,
      'areas_served': areasServed,
      'languages': languages,
      'social_links': socialLinks,
      'onboarding_completed': onboardingCompleted,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}
