import 'package:flutter/material.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Host induction card - explains benefits of signing up
class HostInductionCard extends StatelessWidget {
  const HostInductionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.2),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.video_library,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Host Your Own Party',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textWhite : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to unlock premium features',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textWhite.withValues(alpha: 0.8)
                            : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BenefitItem(
            icon: Icons.play_circle_outline,
            text: 'Control playback as host',
          ),
          const SizedBox(height: 8),
          _BenefitItem(
            icon: Icons.people_outline,
            text: 'Manage participants',
          ),
          const SizedBox(height: 8),
          _BenefitItem(
            icon: Icons.history,
            text: 'View previous rooms',
          ),
          const SizedBox(height: 8),
          _BenefitItem(
            icon: Icons.save,
            text: 'Save watch history',
          ),
          const SizedBox(height: 8),
          _BenefitItem(
            icon: Icons.person_outline,
            text: 'Customize your profile',
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textWhite.withValues(alpha: 0.9)
                : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
