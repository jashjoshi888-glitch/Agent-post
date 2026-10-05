import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

/// Handles the full photo pipeline in one place:
/// pick from gallery → crop → compress → upload to private storage.
///
/// The uploaded file's *path* (not a web link) is what the app saves on the
/// profile / brand kit; a viewable link is created whenever the image is shown.
class ImageUploader {
  ImageUploader({
    ImagePicker? picker,
    ImageCropper? cropper,
    SupabaseClient? client,
  })  : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper(),
        _client = client ?? Supabase.instance.client;

  final ImagePicker _picker;
  final ImageCropper _cropper;
  final SupabaseClient _client;

  /// Full flow: returns the uploaded file's storage path, or null if the
  /// agent cancelled at any step.
  ///
  /// [bucket] is 'avatars' or 'logos'; files are always stored under a folder
  /// named after the user's id so database rules can protect them.
  Future<String?> pickCropCompressAndUpload({
    required BuildContext context,
    required String bucket,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // 1) Pick.
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 95,
    );
    if (picked == null) return null;

    if (!context.mounted) return null;

    // 2) Crop to a friendly square.
    final cropped = await _cropper.cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust photo',
          toolbarColor: AppColors.navy,
          toolbarWidgetColor: Colors.white,
          statusBarColor: AppColors.navyDark,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
      ],
    );
    if (cropped == null) return null;

    // 3) Compress (keeps uploads fast on slow mobile networks).
    final originalBytes = await cropped.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 82,
      minWidth: 720,
      minHeight: 720,
    );

    // 4) Upload into the user's own folder inside the private bucket.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/img_$timestamp.jpg';
    await _client.storage.from(bucket).upload(
          path,
          Uint8List.fromList(compressed),
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return path;
  }

  /// Deletes an uploaded file (used when replacing/removing a photo).
  /// Failures are ignored: an orphan file is harmless.
  Future<void> deleteQuietly(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (_) {
      // Intentionally ignored.
    }
  }
}
