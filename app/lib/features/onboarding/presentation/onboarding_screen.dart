import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/widgets/profile_form.dart';

/// Guided first-time setup: the agent fills in their professional details
/// once, and the app uses them everywhere.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _complete(BuildContext context, WidgetRef ref, Profile profile) async {
    final ok = await ref.read(profileControllerProvider.notifier).save(profile);
    if (!context.mounted) return;

    if (ok) {
      // The router notices the saved profile and moves to the home screen.
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your details. Please check your connection and try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const LoadingView(message: 'Preparing your profile…'),
          error: (e, _) => ErrorView.fromError(
            e,
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (profile) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome! 👋',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tell us a little about yourself. These details appear on '
                      'your marketing materials and business card — you can '
                      'change them any time.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ProfileForm(
                      initial: profile,
                      submitLabel: 'Save and continue',
                      onSubmit: (p) => _complete(context, ref, p),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () async {
                        final ok = await ref
                            .read(profileControllerProvider.notifier)
                            .completeOnboarding();
                        if (!context.mounted) return;
                        if (ok) {
                          context.go('/');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not skip. Please check your connection.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
