import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/bloc/login_bloc.dart';
import '../../domain/bloc/login_event.dart';
import '../../domain/bloc/login_state.dart';
import '../../../../core/widgets/custom_text_field.dart';

class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final Color? labelColor;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) =>
          previous.isPasswordVisible != current.isPasswordVisible,
      builder: (context, state) {
        return CustomTextField(
          controller: controller,
          focusNode: focusNode,
          label: 'Password',
          hintText: 'Enter your password..',
          labelColor: labelColor,
          obscureText: !state.isPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              state.isPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () {
              context.read<LoginBloc>().add(const PasswordVisibilityToggled());
            },
          ),
          onChanged: onChanged,
        );
      },
    );
  }
}
