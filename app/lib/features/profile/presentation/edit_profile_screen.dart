import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../application/profile_controller.dart';
import '../domain/profile.dart';
import 'widgets/profile_form.dart';

/// Edit the agent profile — same form as onboarding.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref, Profile profile) async {
    final ok = await ref.read(profileControllerProvider.notifier).save(profile);
    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView.fromError(
            e,
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (profile) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ProfileForm(
                  initial: profile,
                  submitLabel: 'Save changes',
                  onSubmit: (p) => _save(context, ref, p),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
