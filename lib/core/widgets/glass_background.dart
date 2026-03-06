import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/colors/app_colors.dart';

/// Glassmorphic Cinema background: mesh gradient + blur + bokeh-style orbs.
/// Theme-aware: adapts to light/dark mode
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Theme-aware gradient background
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark, // Deep space blue-black
                      const Color(0xFF1A1B3A), // Rich dark purple-blue
                      const Color(0xFF2D1B69), // Deep purple
                      const Color(0xFF0A0E27), // Back to deep space
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE8EAF6), // Light purple-tinted
                      const Color(0xFFF3E5F5), // Light lavender
                      const Color(0xFFE1F5FE), // Light cyan-tinted
                      const Color(0xFFF5F5F5), // Light grey
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
          ),
        ),
        // Bokeh-style soft orbs - theme-aware
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryAccent.withValues(alpha: isDark ? 0.4 : 0.2),
                  AppColors.primaryAccent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: isDark ? 0.3 : 0.15),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.4,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryAccentLight.withValues(alpha: isDark ? 0.25 : 0.12),
                  AppColors.primaryAccentLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Frosted blur overlay (subtle)
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}
