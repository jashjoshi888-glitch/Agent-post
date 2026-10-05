import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';

/// The "Profile" tab: shows the agent's details with edit / brand kit / sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView.fromError(
          e,
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return EmptyView(
              icon: Icons.person_outline_rounded,
              title: 'No profile found',
              message: 'Please sign out and sign in again.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ---- Header card ---------------------------------------
              AppCard(
                child: Column(
                  children: [
                    UserAvatar(
                      photoPath: profile.photoUrl,
                      fullName: profile.fullName,
                      radius: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      profile.fullName?.isNotEmpty == true
                          ? profile.fullName!
                          : 'Your name',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    if (profile.designation != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        profile.designation!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/profile/edit'),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/brand-kit'),
                            icon: const Icon(Icons.palette_outlined, size: 18),
                            label: const Text('Brand kit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ---- Details ------------------------------------------
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Mobile / WhatsApp',
                      value: profile.mobileWhatsapp == null
                          ? '—'
                          : Formatters.mobile(profile.mobileWhatsapp),
                    ),
                    _DetailRow(
                      icon: Icons.business_outlined,
                      label: 'Agency / company',
                      value: profile.agencyName ?? '—',
                    ),
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'Designation',
                      value: profile.designation ?? '—',
                    ),
                    _DetailRow(
                      icon: Icons.card_membership_outlined,
                      label: 'Licence number',
                      value: profile.licenceNumber ?? '—',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Areas served',
                      value: profile.areasServed.isEmpty
                          ? '—'
                          : Formatters.list(profile.areasServed),
                    ),
                    _DetailRow(
                      icon: Icons.translate_rounded,
                      label: 'Languages',
                      value: profile.languages.isEmpty
                          ? '—'
                          : Formatters.list(profile.languages),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ---- Sign out -----------------------------------------
              TextButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
