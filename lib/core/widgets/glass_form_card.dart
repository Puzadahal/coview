import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/colors/app_colors.dart';
import '../constants/app_constants.dart';

/// Semi-transparent frosted glass card for form content (Glassmorphic Cinema).
/// Theme-aware: adapts to light/dark mode.
/// If [maxHeight] is set, the card content scrolls when it overflows.
class GlassFormCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  /// Max height for the card body; when set, content scrolls to prevent overflow.
  final double? maxHeight;

  const GlassFormCard({
    super.key,
    required this.children,
    this.padding,
    this.margin,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = padding ?? const EdgeInsets.symmetric(
      horizontal: AppConstants.spacingXLarge,
      vertical: AppConstants.spacingXLarge + 4,
    );
    final inner = Container(
      padding: content,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundWhite.withValues(alpha: 0.12) // Dark mode: translucent white
            : AppColors.backgroundWhite.withValues(alpha: 0.85), // Light mode: semi-opaque white
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
    final body = maxHeight != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight!),
            child: SingleChildScrollView(
              child: inner,
            ),
          )
        : inner;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
        border: Border.all(
          color: isDark
              ? AppColors.primaryAccent.withValues(alpha: 0.3) // Dark mode: purple border
              : AppColors.primaryAccent.withValues(alpha: 0.5), // Light mode: more visible purple
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 3,
          ),
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: isDark ? 0.1 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // More blur for translucency
          child: Material(
            color: Colors.transparent,
            child: body,
          ),
        ),
      ),
    );
  }
}
