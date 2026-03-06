import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../config/colors/app_colors.dart';

/// Email field with real-time inline validation (green check when valid).
class EmailFieldWithValidation extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool isEmailValid;
  final String emailValue;
  final Color? labelColor;

  const EmailFieldWithValidation({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    required this.isEmailValid,
    required this.emailValue,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      focusNode: focusNode,
      label: 'Email',
      hintText: 'Enter your email',
      keyboardType: TextInputType.emailAddress,
      labelColor: labelColor,
      onChanged: onChanged,
      suffixIcon: emailValue.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isEmailValid ? Icons.check_circle : Icons.cancel_outlined,
                color: isEmailValid ? AppColors.success : Colors.grey,
                size: 22,
              ),
            ),
      focusedBorderColor: isEmailValid ? AppColors.success : null,
    );
  }
}
