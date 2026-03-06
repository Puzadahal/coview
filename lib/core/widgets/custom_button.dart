import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/colors/app_colors.dart';
import '../constants/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final double? width;
  final double height;
  final double borderRadius;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.width,
    this.height = AppConstants.buttonHeightLarge,
    this.borderRadius = AppConstants.borderRadiusMedium,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor =
        backgroundColor ?? theme.colorScheme.primary;
    final defaultForegroundColor = foregroundColor ?? theme.colorScheme.onPrimary;
    final defaultDisabledBackgroundColor =
        disabledBackgroundColor ?? AppColors.disabledGrey;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading || onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultBackgroundColor,
          foregroundColor: defaultForegroundColor,
          disabledBackgroundColor: defaultDisabledBackgroundColor,
          disabledForegroundColor: defaultForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: backgroundColor == Colors.transparent
                ? BorderSide(color: defaultForegroundColor, width: 2)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    defaultForegroundColor,
                  ),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: fontSize ?? AppConstants.fontSizeXLarge,
                  fontWeight: fontWeight ?? FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
