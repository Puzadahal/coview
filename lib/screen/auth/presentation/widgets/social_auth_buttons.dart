import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// One-tap social login with Google.
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
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata_rounded,
          onPressed: onGooglePressed,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          height: AppConstants.buttonHeightSmall + 4,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textWhite, size: 18),
              const SizedBox(height: 0),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
