import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// One-tap social login with Google, using the branded logo asset.
class SocialAuthButtons extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final VoidCallback? onFacebookPressed;

  const SocialAuthButtons({
    super.key,
    this.onGooglePressed,
    this.onApplePressed,
    this.onFacebookPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: _GoogleButton(
        label: 'Continue with Google',
        onPressed: onGooglePressed,
        isDark: isDark,
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isDark;

  const _GoogleButton({
    required this.label,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? Colors.white : Colors.white;
    final textColor = isDark ? AppColors.textDark : AppColors.textDark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          height: AppConstants.buttonHeightMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo/google.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
