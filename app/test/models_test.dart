import 'package:agent_post/features/brand_kit/domain/brand_kit.dart';
import 'package:agent_post/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile model', () {
    test('reads a database row correctly', () {
      final profile = Profile.fromMap({
        'id': 'abc-123',
        'full_name': 'Ramesh Patel',
        'photo_url': 'abc-123/img_1.jpg',
        'mobile_whatsapp': '9876543210',
        'agency_name': 'Patel Insurance',
        'designation': 'Agent',
        'licence_number': 'IRDAI/1',
        'areas_served': ['Surat', 'Vadodara'],
        'languages': ['Gujarati', 'Hindi'],
        'social_links': {'instagram': 'ramesh'},
        'onboarding_completed': true,
        'created_at': '2026-10-05T10:00:00Z',
      });

      expect(profile.id, 'abc-123');
      expect(profile.fullName, 'Ramesh Patel');
      expect(profile.areasServed, ['Surat', 'Vadodara']);
      expect(profile.languages, ['Gujarati', 'Hindi']);
      expect(profile.onboardingCompleted, isTrue);
      expect(profile.createdAt, isNotNull);
    });

    test('handles missing optional fields safely', () {
      final profile = Profile.fromMap({'id': 'x'});
      expect(profile.fullName, isNull);
      expect(profile.areasServed, isEmpty);
      expect(profile.languages, isEmpty);
      expect(profile.onboardingCompleted, isFalse);
    });

    test('toMap writes the correct column names', () {
      const profile = Profile(
        id: 'abc',
        fullName: 'Ramesh',
        mobileWhatsapp: '9876543210',
        areasServed: ['Surat'],
      );
      final map = profile.toMap();
      expect(map['id'], 'abc');
      expect(map['full_name'], 'Ramesh');
      expect(map['mobile_whatsapp'], '9876543210');
      expect(map['areas_served'], ['Surat']);
      expect(map['onboarding_completed'], isFalse);
    });
  });

  group('BrandKit model', () {
    test('comes with sensible defaults', () {
      const kit = BrandKit(userId: 'abc');
      expect(kit.primaryColor, '#173B63');
      expect(kit.secondaryColor, '#0FA3B1');
      expect(kit.fontPreference, 'noto_sans');
      expect(kit.showContactDetails, isTrue);
    });

    test('reads a database row correctly', () {
      final kit = BrandKit.fromMap({
        'user_id': 'abc',
        'logo_url': 'abc/logo.png',
        'primary_color': '#7B2D26',
        'secondary_color': '#C9A227',
        'font_preference': 'mukta_vaani',
        'show_contact_details': false,
        'contact_mobile': '9876543210',
      });
      expect(kit.primaryColor, '#7B2D26');
      expect(kit.fontPreference, 'mukta_vaani');
      expect(kit.showContactDetails, isFalse);
      expect(kit.contactMobile, '9876543210');
    });
  });

  group('BrandFonts list', () {
    test('has the 6 curated fonts (decision 2.7.3)', () {
      expect(BrandFonts.all.length, 6);
      final keys = BrandFonts.all.map((f) => f.key).toList();
      expect(keys, [
        'noto_sans',
        'poppins',
        'mukta_vaani',
        'hind_vadodara',
        'baloo_bhai_2',
        'tiro_gujarati',
      ]);
    });

    test('falls back to the first font for unknown keys', () {
      expect(BrandFonts.byKey('does_not_exist').key, 'noto_sans');
    });
  });
}
