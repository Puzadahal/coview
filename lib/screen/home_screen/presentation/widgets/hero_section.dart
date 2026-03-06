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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Watch Together,\nAnywhere',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 56 : 42,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
            height: 1.1,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sync Your Screen, Share the Vibe',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18,
            color: AppColors.textWhite.withValues(alpha: 0.9),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CTAButton(
              text: 'Start Watching',
              isPrimary: true,
              onPressed: onStartWatching ??
                  onCreateRoom ??
                  () {
                    context.go('/create-room');
                  },
            ),
            const SizedBox(width: 16),
            _CTAButton(
              text: 'Create Room',
              isPrimary: false,
              onPressed: onCreateRoom ??
                  () {
                    context.go('/create-room');
                  },
            ),
          ],
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? const Color(0xFFFF6B35) // Vibrant orange
            : Colors.transparent,
        foregroundColor: AppColors.textWhite,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 24 : 32,
          vertical: isSmallScreen ? 16 : 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          side: BorderSide(
            color: isPrimary
                ? Colors.transparent
                : AppColors.textWhite.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        elevation: isPrimary ? 8 : 0,
        shadowColor: const Color(0xFFFF6B35).withValues(alpha: 0.4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmallScreen ? 16 : 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
