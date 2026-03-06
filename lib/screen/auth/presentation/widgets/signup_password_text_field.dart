import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/bloc/signup_event.dart';
import '../../domain/bloc/signup_bloc.dart';
import '../../domain/bloc/signup_state.dart';
import '../../../../core/widgets/custom_text_field.dart';

class SignupPasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool isConfirmPassword;
  final Color? labelColor;

  const SignupPasswordTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.isConfirmPassword = false,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupBloc, SignupState>(
      buildWhen: (previous, current) => isConfirmPassword
          ? previous.isConfirmPasswordVisible != current.isConfirmPasswordVisible
          : previous.isPasswordVisible != current.isPasswordVisible,
      builder: (context, state) {
        final isVisible = isConfirmPassword
            ? state.isConfirmPasswordVisible
            : state.isPasswordVisible;

        return CustomTextField(
          controller: controller,
          focusNode: focusNode,
          label: isConfirmPassword ? 'Confirm Password' : 'Password',
          hintText: isConfirmPassword
              ? 'Confirm your password..'
              : 'Enter your password..',
          labelColor: labelColor,
          obscureText: !isVisible,
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () {
              if (isConfirmPassword) {
                context.read<SignupBloc>().add(
                    const SignupConfirmPasswordVisibilityToggled());
              } else {
                context
                    .read<SignupBloc>()
                    .add(const SignupPasswordVisibilityToggled());
              }
            },
          ),
          onChanged: onChanged,
        );
      },
    );
  }
}
