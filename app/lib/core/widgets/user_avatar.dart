import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

/// Resolves a private Storage path into a short-lived viewable link.
///
/// Files (photos/logos) are stored privately; the app asks Supabase for a
/// temporary signed link whenever it needs to display one.
final signedUrlProvider =
    FutureProvider.autoDispose.family<String, (String, String)>((ref, args) async {
  final (bucket, path) = args;
  return Supabase.instance.client.storage.from(bucket).createSignedUrl(path, 3600);
});

/// Circular profile photo with graceful fallbacks:
/// no photo → initials on a navy circle; loading → soft grey circle.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    this.photoPath,
    this.fullName,
    this.radius = 36,
    this.bucket = 'avatars',
  });

  /// Storage path (e.g. "avatars/<uid>/photo.jpg") or null when no photo.
  final String? photoPath;

  /// Used to draw initials when there is no photo.
  final String? fullName;

  final double radius;

  /// Which private bucket the file lives in ('avatars' or 'logos').
  final String bucket;

  String get _initials {
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return 'A';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = photoPath;

    if (path == null || path.isEmpty) {
      return _InitialsCircle(initials: _initials, radius: radius);
    }

    // The stored value may be a full path ("avatars/x/y.jpg") or just the
    // file name inside the user's folder ("x/y.jpg").
    final cleanPath = path.startsWith('$bucket/') ? path.substring(bucket.length + 1) : path;

    final signed = ref.watch(signedUrlProvider((bucket, cleanPath)));

    return signed.when(
      data: (url) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.navySoft,
        foregroundImage: NetworkImage(url),
        onForegroundImageError: (_, __) {},
        child: _InitialsCircle(initials: _initials, radius: radius, visible: false),
      ),
      loading: () => CircleAvatar(radius: radius, backgroundColor: AppColors.inputFill),
      error: (_, __) => _InitialsCircle(initials: _initials, radius: radius),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.initials,
    required this.radius,
    this.visible = true,
  });

  final String initials;
  final double radius;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navySoft, width: 2),
      ),
      alignment: Alignment.center,
      child: visible
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}
