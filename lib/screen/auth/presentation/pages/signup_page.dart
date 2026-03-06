import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/bloc/signup_bloc.dart';
import '../../domain/bloc/signup_event.dart';
import '../../domain/bloc/signup_state.dart';
import '../../../../core/widgets/glass_background.dart';
import '../../../../core/widgets/glass_form_card.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/fade_in_up.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/email_field_with_validation.dart';
import '../widgets/signup_password_text_field.dart';
import '../widgets/social_auth_buttons.dart';
import '../widgets/kinetic_logo.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupBloc(),
      child: const _SignupPageContent(),
    );
  }
}

class _SignupPageContent extends StatefulWidget {
  const _SignupPageContent();

  @override
  State<_SignupPageContent> createState() => _SignupPageContentState();
}

class _SignupPageContentState extends State<_SignupPageContent> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      context.read<SignupBloc>().add(const SignupEmailFieldFocused());
    } else {
      context.read<SignupBloc>().add(const SignupFieldUnfocused());
    }
  }

  void _onPasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) {
      context.read<SignupBloc>().add(const SignupPasswordFieldFocused());
    } else {
      context.read<SignupBloc>().add(const SignupFieldUnfocused());
    }
  }

  String _getValidationMessage(SignupState state) {
    if (state.name.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (!state.isEmailValid) {
      return 'Please enter a valid email';
    }
    if (state.password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!state.doPasswordsMatch) {
      return 'Passwords do not match';
    }
    if (!state.agreedToTerms) {
      return 'Please agree to Terms & Privacy Policy';
    }
    return 'Please fill all fields correctly';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _confirmPasswordFocusNode.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.sizeOf(context);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const GlassBackground(),
            SafeArea(
            child: BlocListener<SignupBloc, SignupState>(
              listenWhen: (previous, current) => 
                  previous.status != current.status,
              listener: (context, state) {
                print('[SignupPage] Status changed: ${state.status}');
                if (state.status == SignupStatus.success) {
                  print('[SignupPage] Success! Navigating to login...');
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signup successful! Please login to continue.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // Navigate to login after a short delay to show snackbar
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      print('[SignupPage] Executing navigation to /login');
                      context.go('/login');
                    } else {
                      print('[SignupPage] Context not mounted, cannot navigate');
                    }
                  });
                } else if (state.status == SignupStatus.failure) {
                  print('[SignupPage] Signup failed: ${state.errorMessage}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'Signup failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 24,
                  bottom: 24 + keyboardHeight,
                ),
                child: Column(
                  children: [
                    BlocBuilder<SignupBloc, SignupState>(
                      buildWhen: (p, c) => p.name != c.name,
                      builder: (context, state) {
                        return FadeInUp(
                          delayMs: 0,
                          child: KineticLogo(
                            keystrokeTrigger: state.name.length,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    FadeInUp(
                      delayMs: 50,
                      child: Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textWhite.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delayMs: 100,
                      child: GlassFormCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            label: 'Name',
                            hintText: 'Enter your name',
                            keyboardType: TextInputType.name,
                            labelColor: AppColors.textWhite.withValues(alpha: 0.95),
                            onChanged: (value) {
                              context
                                  .read<SignupBloc>()
                                  .add(SignupNameChanged(value));
                            },
                          ),
                          const SizedBox(height: 10),
                          BlocBuilder<SignupBloc, SignupState>(
                            buildWhen: (p, c) =>
                                p.email != c.email || p.isEmailValid != c.isEmailValid,
                            builder: (context, state) {
                              return EmailFieldWithValidation(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                emailValue: state.email,
                                isEmailValid: state.isEmailValid,
                                labelColor: AppColors.textWhite.withValues(alpha: 0.95),
                                onChanged: (value) {
                                  context
                                      .read<SignupBloc>()
                                      .add(SignupEmailChanged(value));
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          SignupPasswordTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            labelColor: AppColors.textWhite.withValues(alpha: 0.95),
                            onChanged: (value) {
                              context
                                  .read<SignupBloc>()
                                  .add(SignupPasswordChanged(value));
                            },
                          ),
                          const SizedBox(height: 10),
                          SignupPasswordTextField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocusNode,
                            isConfirmPassword: true,
                            labelColor: AppColors.textWhite.withValues(alpha: 0.95),
                            onChanged: (value) {
                              context
                                  .read<SignupBloc>()
                                  .add(SignupConfirmPasswordChanged(value));
                            },
                          ),
                          const SizedBox(height: 8),
                          BlocBuilder<SignupBloc, SignupState>(
                            buildWhen: (previous, current) =>
                                previous.password != current.password ||
                                previous.confirmPassword !=
                                    current.confirmPassword,
                            builder: (context, state) {
                              if (state.confirmPassword.isNotEmpty &&
                                  state.password.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        state.doPasswordsMatch
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: state.doPasswordsMatch
                                            ? AppColors.success
                                            : AppColors.error,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        state.doPasswordsMatch
                                            ? 'Passwords match'
                                            : 'Passwords do not match',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: state.doPasswordsMatch
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 6),
                          BlocBuilder<SignupBloc, SignupState>(
                            buildWhen: (p, c) => p.agreedToTerms != c.agreedToTerms,
                            builder: (context, state) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  checkboxTheme: CheckboxThemeData(
                                    fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return AppColors.primaryDark;
                                      }
                                      return AppColors.textWhite.withValues(alpha: 0.4);
                                    }),
                                    checkColor: MaterialStateProperty.all(AppColors.textWhite),
                                    side: BorderSide(
                                      color: AppColors.textWhite.withValues(alpha: 0.8),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: CheckboxListTile(
                                    value: state.agreedToTerms,
                                    onChanged: (v) {
                                      context.read<SignupBloc>().add(
                                          SignupAgreedToTermsChanged(v ?? false));
                                    },
                                    title: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textWhite.withValues(alpha: 0.95),
                                        ),
                                        children: [
                                          const TextSpan(text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: AppColors.info,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppColors.info,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    activeColor: AppColors.primaryDark,
                                    tileColor: Colors.transparent,
                                  ),
                                ),
                              );
                            },
                          ),
                          BlocBuilder<SignupBloc, SignupState>(
                            builder: (context, state) {
                              return CustomButton(
                                text: 'Sign Up',
                                height: AppConstants.buttonHeightMedium + 4,
                                isLoading:
                                    state.status == SignupStatus.loading,
                                onPressed: state.isFormValid
                                    ? () {
                                        // Debug: Check form validity
                                        print('Form valid: ${state.isFormValid}');
                                        print('Name: ${state.name}');
                                        print('Email valid: ${state.isEmailValid}');
                                        print('Password length: ${state.password.length}');
                                        print('Passwords match: ${state.doPasswordsMatch}');
                                        print('Agreed to terms: ${state.agreedToTerms}');
                                        context.read<SignupBloc>().add(
                                            const SignupButtonPressed());
                                      }
                                    : () {
                                        // Show why button is disabled
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _getValidationMessage(state),
                                            ),
                                            backgroundColor: Colors.orange,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                // TODO: Magic link / passkey
                              },
                              child: Text(
                                'Sign up with magic link',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 18),
                          // Social auth (Google only)
                          SocialAuthButtons(
                            onGooglePressed: () {},
                            onApplePressed: () {},
                            onFacebookPressed: () {},
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: AppColors.textWhite.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
