import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/domain/profile.dart';
import '../../domain/brand_kit.dart';
import 'color_field.dart';

/// A small sample card showing how the brand kit looks — updates instantly
/// as the agent changes colours, font or logo. (A simple brand sample for
/// Phase 1; full marketing templates come in a later phase.)
class BrandPreviewCard extends StatelessWidget {
  const BrandPreviewCard({
    super.key,
    required this.brandKit,
    required this.profile,
  });

  /// Current (possibly unsaved) brand kit values.
  final BrandKit brandKit;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final primary = parseHex(brandKit.primaryColor);
    final secondary = parseHex(brandKit.secondaryColor);
    final font = BrandFonts.byKey(brandKit.fontPreference);
    final name = profile?.fullName?.isNotEmpty == true
        ? profile!.fullName!
        : 'Your name';
    final designation = profile?.designation ?? 'Insurance Agent';

    // Brand font (falls back to the app font if it cannot load).
    TextStyle brandStyle(TextStyle? base, {Color? color, FontWeight? weight}) {
      final merged = (base ?? const TextStyle()).copyWith(color: color, fontWeight: weight);
      return GoogleFonts.getFont(font.googleFontName, textStyle: merged);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coloured header band with logo and name.
          Container(
            color: primary,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                if (brandKit.logoUrl != null)
                  UserAvatar(photoPath: brandKit.logoUrl, bucket: 'logos', radius: 28)
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: TextStyle(
                        color: primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: brandStyle(
                          Theme.of(context).textTheme.titleLarge,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        designation,
                        style: brandStyle(
                          Theme.of(context).textTheme.bodyMedium,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body sample text in the brand font.
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Protecting what matters most to your family.',
              style: brandStyle(
                Theme.of(context).textTheme.titleMedium,
                color: const Color(0xFF1A2233),
              ),
            ),
          ),

          // Contact strip in the secondary colour.
          if (brandKit.showContactDetails)
            Container(
              color: secondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Text(
                [
                  if (brandKit.contactMobile != null && brandKit.contactMobile!.isNotEmpty)
                    brandKit.contactMobile!,
                  if (brandKit.contactEmail != null && brandKit.contactEmail!.isNotEmpty)
                    brandKit.contactEmail!,
                  if (brandKit.contactWebsite != null && brandKit.contactWebsite!.isNotEmpty)
                    brandKit.contactWebsite!,
                ].join('   •   '),
                style: brandStyle(
                  Theme.of(context).textTheme.bodySmall,
                  color: Colors.white,
                  weight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
