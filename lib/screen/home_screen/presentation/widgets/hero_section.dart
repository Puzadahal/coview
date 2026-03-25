import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Hero section with headline and CTA button.
class HeroSection extends StatelessWidget {
  final VoidCallback? onStartWatching;
  final VoidCallback? onCreateRoom;

  const HeroSection({
    super.key,
    this.onStartWatching,
    this.onCreateRoom,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 36 : 20,
            vertical: isDesktop ? 42 : 28,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryDarkVariant.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Watch Parties Made Simple',
                  style: TextStyle(
                    color: AppColors.secondaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Stream Together.\nChat Live.\nStay In Sync.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 56 : 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textWhite,
                  height: 1.05,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create a room in seconds, invite friends, and watch YouTube or your own video links with live room chat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 15,
                  color: AppColors.textWhite.withValues(alpha: 0.82),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _CTAButton(
                    text: 'Create Room',
                    isPrimary: true,
                    onPressed: onCreateRoom ??
                        () {
                          context.go('/create-room');
                        },
                  ),
                  _CTAButton(
                    text: 'Join Existing Room',
                    isPrimary: false,
                    onPressed: onStartWatching ??
                        () {
                          context.go('/join-room');
                        },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CTAButton extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _CTAButton({
    required this.text,
    required this.isPrimary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [AppColors.primaryAccent, AppColors.secondary],
              )
            : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? Colors.transparent : AppColors.primaryDarkVariant,
          foregroundColor: AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusLarge),
            side: BorderSide(
              color: isPrimary
                  ? Colors.transparent
                  : AppColors.textWhite.withValues(alpha: 0.25),
              width: 1.4,
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
