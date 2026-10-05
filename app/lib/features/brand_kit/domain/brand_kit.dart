/// The agent's brand kit — matches the `brand_kits` table in Supabase.
class BrandKit {
  const BrandKit({
    required this.userId,
    this.logoUrl,
    this.primaryColor = '#173B63',
    this.secondaryColor = '#0FA3B1',
    this.fontPreference = 'noto_sans',
    this.showContactDetails = true,
    this.contactMobile,
    this.contactEmail,
    this.contactWebsite,
    this.contactAddress,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final String fontPreference;
  final bool showContactDetails;
  final String? contactMobile;
  final String? contactEmail;
  final String? contactWebsite;
  final String? contactAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BrandKit.fromMap(Map<String, dynamic> map) {
    return BrandKit(
      userId: map['user_id'] as String,
      logoUrl: map['logo_url'] as String?,
      primaryColor: map['primary_color'] as String? ?? '#173B63',
      secondaryColor: map['secondary_color'] as String? ?? '#0FA3B1',
      fontPreference: map['font_preference'] as String? ?? 'noto_sans',
      showContactDetails: map['show_contact_details'] as bool? ?? true,
      contactMobile: map['contact_mobile'] as String?,
      contactEmail: map['contact_email'] as String?,
      contactWebsite: map['contact_website'] as String?,
      contactAddress: map['contact_address'] as String?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'font_preference': fontPreference,
      'show_contact_details': showContactDetails,
      'contact_mobile': contactMobile,
      'contact_email': contactEmail,
      'contact_website': contactWebsite,
      'contact_address': contactAddress,
    };
  }
}

/// The curated brand font list (Decision 2.7.3, agreed with the owner).
/// Each key matches the `font_preference` values allowed by the database.
class BrandFonts {
  const BrandFonts._();

  static const List<BrandFont> all = [
    BrandFont(key: 'noto_sans', label: 'Noto Sans', googleFontName: 'Noto Sans'),
    BrandFont(key: 'poppins', label: 'Poppins', googleFontName: 'Poppins'),
    BrandFont(key: 'mukta_vaani', label: 'Mukta Vaani', googleFontName: 'Mukta Vaani'),
    BrandFont(key: 'hind_vadodara', label: 'Hind Vadodara', googleFontName: 'Hind Vadodara'),
    BrandFont(key: 'baloo_bhai_2', label: 'Baloo Bhai 2', googleFontName: 'Baloo Bhai 2'),
    BrandFont(key: 'tiro_gujarati', label: 'Tiro Gujarati', googleFontName: 'Tiro Gujarati'),
  ];

  static BrandFont byKey(String key) {
    for (final f in all) {
      if (f.key == key) return f;
    }
    return all.first;
  }
}

class BrandFont {
  const BrandFont({
    required this.key,
    required this.label,
    required this.googleFontName,
  });

  final String key;
  final String label;

  /// Name used with the google_fonts package when showing a preview.
  final String googleFontName;
}
