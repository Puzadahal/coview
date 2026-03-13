import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/glass_form_card.dart';

/// Success Dialog shown after room creation with copyable invite link
class CreateRoomSuccessDialog extends StatelessWidget {
  final String roomName;
  final String inviteLink;
  final String roomId;

  const CreateRoomSuccessDialog({
    super.key,
    required this.roomName,
    required this.inviteLink,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build a shareable link based on the current app URL.
    // On web with hash routing this will look like:
    //   http://host/#/join/room_xxx
    final base = Uri.base;
    final origin = base.origin; // scheme://host:port
    final resolvedLink = inviteLink.startsWith('http')
        ? inviteLink
        : '$origin/#/join/$roomId';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassFormCard(
        padding: const EdgeInsets.all(AppConstants.spacingXLarge),
        children: [
          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.secondary,
                ],
              ),
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.textWhite,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),

          // Success Message
          Text(
            'Room Created!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            roomName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppColors.textWhite.withValues(alpha: 0.8)
                  : AppColors.textDark.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Invite Link Section
          Text(
            'Share this link to invite friends:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textWhite.withValues(alpha: 0.9)
                  : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // Copyable Invite Link
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: resolvedLink));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.textWhite),
                      SizedBox(width: 8),
                      Text('Link copied to clipboard!'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDarkVariant.withValues(alpha: 0.5)
                    : AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      resolvedLink,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.copy,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.pop();
                    context.pop(); // Close dialog and go back
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.pop(); // close dialog
                    if (roomId.isNotEmpty) {
                      // Navigate into the Coview room
                      context.go('/join/$roomId');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Enter Room',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
