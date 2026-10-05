import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/image_uploader.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/profile.dart';

/// The one and only profile form — used by onboarding and by the
/// "Edit profile" screen so both always ask for exactly the same details.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    required this.initial,
    required this.onSubmit,
    this.submitLabel = 'Save',
  });

  /// Existing values to edit (null = empty form).
  final Profile? initial;

  /// Called with the finished profile when the agent taps the main button.
  final Future<void> Function(Profile profile) onSubmit;

  final String submitLabel;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _agency;
  late final TextEditingController _designation;
  late final TextEditingController _licence;
  late final TextEditingController _areas;
  late final TextEditingController _languages;

  String? _photoPath;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.fullName ?? '');
    _mobile = TextEditingController(text: p?.mobileWhatsapp ?? '');
    _agency = TextEditingController(text: p?.agencyName ?? '');
    _designation = TextEditingController(text: p?.designation ?? '');
    _licence = TextEditingController(text: p?.licenceNumber ?? '');
    _areas = TextEditingController(text: (p?.areasServed ?? []).join(', '));
    _languages = TextEditingController(text: (p?.languages ?? []).join(', '));
    _photoPath = p?.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _agency.dispose();
    _designation.dispose();
    _licence.dispose();
    _areas.dispose();
    _languages.dispose();
    super.dispose();
  }

  /// "Surat, Vadodara, Rajkot" → ['Surat', 'Vadodara', 'Rajkot']
  List<String> _splitList(String text) {
    return text
        .split(RegExp(r'[,;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _changePhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      final uploader = ImageUploader();
      final oldPath = _photoPath;
      final newPath = await uploader.pickCropCompressAndUpload(
        context: context,
        bucket: 'avatars',
      );
      if (newPath != null) {
        if (oldPath != null && oldPath != newPath) {
          await uploader.deleteQuietly('avatars', _stripBucket(oldPath));
        }
        setState(() => _photoPath = newPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  String _stripBucket(String path) =>
      path.startsWith('avatars/') ? path.substring('avatars/'.length) : path;

  Future<void> _removePhoto() async {
    final oldPath = _photoPath;
    setState(() => _photoPath = null);
    if (oldPath != null) {
      await ImageUploader().deleteQuietly('avatars', _stripBucket(oldPath));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profile = Profile(
        id: user.id,
        fullName: _name.text.trim(),
        photoUrl: _photoPath,
        mobileWhatsapp: Validators.normalizeMobile(_mobile.text.trim()),
        agencyName: _agency.text.trim().isEmpty ? null : _agency.text.trim(),
        designation:
            _designation.text.trim().isEmpty ? null : _designation.text.trim(),
        licenceNumber:
            _licence.text.trim().isEmpty ? null : _licence.text.trim(),
        areasServed: _splitList(_areas.text),
        languages: _splitList(_languages.text),
        socialLinks: widget.initial?.socialLinks ?? const {},
        onboardingCompleted: true,
      );
      await widget.onSubmit(profile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Photo -------------------------------------------------
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    UserAvatar(
                      photoPath: _photoPath,
                      fullName: _name.text.isEmpty ? null : _name.text,
                      radius: 48,
                    ),
                    if (_uploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: _uploadingPhoto || _saving ? null : _changePhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Change photo'),
                    ),
                    if (_photoPath != null)
                      TextButton(
                        onPressed: _uploadingPhoto || _saving ? null : _removePhoto,
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ---- Details ----------------------------------------------
          AppTextField(
            controller: _name,
            label: 'Full name',
            required: true,
            hint: 'e.g. Ramesh Patel',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: Validators.fullName,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _mobile,
            label: 'Mobile / WhatsApp number',
            required: true,
            hint: 'e.g. 98765 43210',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: Validators.mobile,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _agency,
            label: 'Agency / company',
            hint: 'e.g. Patel Insurance Services',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                Validators.optionalText(v, label: 'Agency name', max: 120),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _designation,
            label: 'Designation',
            hint: 'e.g. LIC Development Officer',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                Validators.optionalText(v, label: 'Designation', max: 80),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _licence,
            label: 'Licence / registration number',
            hint: 'e.g. IRDAI/12345',
            textInputAction: TextInputAction.next,
            validator: (v) =>
                Validators.optionalText(v, label: 'Licence number', max: 60),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _areas,
            label: 'Areas served',
            hint: 'e.g. Surat, Vadodara, Rajkot',
            helper: 'Separate areas with commas.',
            textInputAction: TextInputAction.next,
            validator: (v) => _splitList(v ?? '').length > 25
                ? 'Please list at most 25 areas'
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _languages,
            label: 'Languages',
            hint: 'e.g. Gujarati, Hindi, English',
            helper: 'Separate languages with commas.',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) => _splitList(v ?? '').length > 12
                ? 'Please list at most 12 languages'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ---- Save -------------------------------------------------
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.submitLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
