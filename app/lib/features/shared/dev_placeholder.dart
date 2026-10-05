import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Developer-only placeholder for tabs that are built in later phases
/// (Home content, Social Media Studio, CRM).
///
/// NOTE: this is NOT a user-facing "coming soon" screen — these tabs are
/// filled in by later project phases before launch.
class DevPlaceholder extends StatelessWidget {
  const DevPlaceholder({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33C9A227), // gold at 20% opacity
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'DEV BUILD',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Icon(icon, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '$title is under development',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This area will be filled in during a later development phase.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
