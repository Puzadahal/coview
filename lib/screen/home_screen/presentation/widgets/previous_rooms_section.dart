import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Previous Rooms section - Only visible for registered users
class PreviousRoomsSection extends StatelessWidget {
  const PreviousRoomsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDarkVariant.withValues(alpha: 0.5)
            : AppColors.backgroundWhite.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Previous Rooms',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'View and rejoin your previous watch parties',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textWhite.withValues(alpha: 0.7)
                  : AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 20),
          // TODO: Replace with actual room list from backend
          _EmptyState(),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: AppColors.primaryAccent.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No previous rooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first room to get started!',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textWhite.withValues(alpha: 0.6)
                  : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
