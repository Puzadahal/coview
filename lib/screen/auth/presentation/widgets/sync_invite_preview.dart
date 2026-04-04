import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class SyncInvitePreview extends StatelessWidget {
  final String hostName;
  final String? hostAvatarUrl;

  const SyncInvitePreview({
    super.key,
    required this.hostName,
    this.hostAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMedium,
          vertical: AppConstants.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.primaryAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.primaryAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: hostAvatarUrl != null && hostAvatarUrl!.isNotEmpty
                  ? NetworkImage(hostAvatarUrl!)
                  : null,
              child: hostAvatarUrl == null || hostAvatarUrl!.isEmpty
                  ? Text(
                      hostName.isNotEmpty ? hostName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                "Join $hostName's Room",
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
