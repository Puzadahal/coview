import 'package:flutter/material.dart';
import '../../config/colors/app_colors.dart';
import '../constants/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFocusChange;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? labelColor;

  const CustomTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.onFocusChange,
    this.borderColor,
    this.focusedBorderColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = borderColor ?? AppColors.borderGrey;
    final defaultFocusedBorderColor =
        focusedBorderColor ?? AppColors.primaryDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppConstants.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: labelColor ?? Colors.grey[800],
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.backgroundWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMedium,
              vertical: AppConstants.spacingMedium,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: defaultBorderColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: defaultBorderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(
                color: defaultFocusedBorderColor,
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
          onTap: onFocusChange,
        ),
      ],
    );
  }
}
