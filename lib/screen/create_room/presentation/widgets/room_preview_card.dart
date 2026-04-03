import 'package:flutter/material.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Room Preview Card - Shows video thumbnail when URL is valid
class RoomPreviewCard extends StatelessWidget {
  final String thumbnailUrl;

  const RoomPreviewCard({
    super.key,
    required this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Stack(
          children: [
            // Thumbnail Image
            Image.network(
              thumbnailUrl,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 280,
                  color: isDark
                      ? AppColors.primaryDarkVariant
                      : AppColors.backgroundGrey,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.secondary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 280,
                  color: isDark
                      ? AppColors.primaryDarkVariant
                      : AppColors.backgroundGrey,
                  child: Center(
                    child: Icon(
                      Icons.video_library,
                      size: 48,
                      color: AppColors.secondary,
                    ),
                  ),
                );
              },
            ),
            // Overlay with play icon
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.9),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: AppColors.textDark,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
