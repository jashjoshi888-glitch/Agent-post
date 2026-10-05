import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/image_uploader.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/profile.dart';
import '../application/brand_kit_controller.dart';
import '../domain/brand_kit.dart';
import 'widgets/brand_preview_card.dart';
import 'widgets/color_field.dart';

/// The brand kit screen: logo, colours, font and contact display, with a
/// live preview that updates as the agent makes changes.
class BrandKitScreen extends ConsumerWidget {
  const BrandKitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitAsync = ref.watch(brandKitProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Brand kit')),
      body: SafeArea(
        child: kitAsync.when(
          loading: () => const LoadingView(message: 'Loading your brand kit…'),
          error: (e, _) => ErrorView.fromError(
            e,
            onRetry: () => ref.invalidate(brandKitProvider),
          ),
          data: (kit) => _BrandKitForm(
            kit: kit,
            profile: profileAsync.valueOrNull,
          ),
        ),
      ),
    );
  }
}

class _BrandKitForm extends ConsumerStatefulWidget {
  const _BrandKitForm({required this.kit, required this.profile});

  final BrandKit kit;
  final Profile? profile;

  @override
  ConsumerState<_BrandKitForm> createState() => _BrandKitFormState();
}

class _BrandKitFormState extends ConsumerState<_BrandKitForm> {
  final _formKey = GlobalKey<FormState>();

  late String _primary;
  late String _secondary;
  late String _font;
  late bool _showContact;
  late String? _logoPath;

  late final TextEditingController _contactMobile;
  late final TextEditingController _contactEmail;
  late final TextEditingController _contactWebsite;
  late final TextEditingController _contactAddress;

  bool _saving = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final kit = widget.kit;
    _primary = kit.primaryColor;
    _secondary = kit.secondaryColor;
    _font = kit.fontPreference;
    _showContact = kit.showContactDetails;
    _logoPath = kit.logoUrl;
    _contactMobile = TextEditingController(text: kit.contactMobile ?? '');
    _contactEmail = TextEditingController(text: kit.contactEmail ?? '');
    _contactWebsite = TextEditingController(text: kit.contactWebsite ?? '');
    _contactAddress = TextEditingController(text: kit.contactAddress ?? '');
  }

  @override
  void dispose() {
    _contactMobile.dispose();
    _contactEmail.dispose();
    _contactWebsite.dispose();
    _contactAddress.dispose();
    super.dispose();
  }

  BrandKit get _draft => BrandKit(
        userId: widget.kit.userId,
        logoUrl: _logoPath,
        primaryColor: _primary,
        secondaryColor: _secondary,
        fontPreference: _font,
        showContactDetails: _showContact,
        contactMobile: _contactMobile.text.trim().isEmpty
            ? null
            : _contactMobile.text.trim(),
        contactEmail:
            _contactEmail.text.trim().isEmpty ? null : _contactEmail.text.trim(),
        contactWebsite: _contactWebsite.text.trim().isEmpty
            ? null
            : _contactWebsite.text.trim(),
        contactAddress: _contactAddress.text.trim().isEmpty
            ? null
            : _contactAddress.text.trim(),
      );

  Future<void> _changeLogo() async {
    setState(() => _uploadingLogo = true);
    try {
      final uploader = ImageUploader();
      final oldPath = _logoPath;
      final newPath = await uploader.pickCropCompressAndUpload(
        context: context,
        bucket: 'logos',
      );
      if (newPath != null) {
        if (oldPath != null && oldPath != newPath) {
          await uploader.deleteQuietly('logos', _stripBucket(oldPath));
        }
        setState(() => _logoPath = newPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  String _stripBucket(String path) =>
      path.startsWith('logos/') ? path.substring('logos/'.length) : path;

  Future<void> _removeLogo() async {
    final oldPath = _logoPath;
    setState(() => _logoPath = null);
    if (oldPath != null) {
      await ImageUploader().deleteQuietly('logos', _stripBucket(oldPath));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final ok = await ref.read(brandKitControllerProvider.notifier).save(_draft);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand kit saved.')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Please check your connection and try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fonts = BrandFonts.all;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Live preview --------------------------------------
                Text('Preview', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                BrandPreviewCard(
                  brandKit: _draft,
                  profile: widget.profile,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Logo ---------------------------------------------
                Text('Logo', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Row(
                    children: [
                      UserAvatar(
                        photoPath: _logoPath,
                        fullName: 'Logo',
                        radius: 32,
                        bucket: 'logos',
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _logoPath == null ? 'No logo yet' : 'Logo uploaded',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Square image works best (PNG or JPG).',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _uploadingLogo || _saving ? null : _changeLogo,
                        child: Text(_logoPath == null ? 'Upload' : 'Replace'),
                      ),
                      if (_logoPath != null)
                        TextButton(
                          onPressed: _uploadingLogo || _saving ? null : _removeLogo,
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Colours ------------------------------------------
                Text('Colours', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ColorField(
                        label: 'Primary colour',
                        value: _primary,
                        onChanged: (hex) => setState(() => _primary = hex),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ColorField(
                        label: 'Secondary colour',
                        value: _secondary,
                        onChanged: (hex) => setState(() => _secondary = hex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Font ---------------------------------------------
                Text('Font style', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final font in fonts)
                      ChoiceChip(
                        label: Text(font.label),
                        selected: _font == font.key,
                        onSelected: (_) => setState(() => _font = font.key),
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ---- Contact display ---------------------------------
                Text('Contact details on materials',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  value: _showContact,
                  onChanged: (v) => setState(() => _showContact = v),
                  title: const Text('Show my contact details'),
                  subtitle: const Text(
                    'Turn off to keep the material text-only.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_showContact) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _contactMobile,
                    label: 'Contact mobile',
                    hint: 'e.g. 98765 43210',
                    keyboardType: TextInputType.phone,
                    validator: Validators.optionalMobile,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _contactEmail,
                    label: 'Contact email',
                    hint: 'e.g. you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.optionalEmail,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _contactWebsite,
                    label: 'Website',
                    hint: 'e.g. yoursite.com',
                    validator: (v) => Validators.optionalText(
                      v,
                      label: 'Website',
                      max: 254,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _contactAddress,
                    label: 'Office address',
                    maxLines: 2,
                    validator: (v) => Validators.optionalText(
                      v,
                      label: 'Address',
                      max: 300,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                // ---- Save ---------------------------------------------
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save brand kit'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
