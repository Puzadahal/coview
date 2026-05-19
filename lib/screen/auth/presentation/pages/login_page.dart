// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:go_router/go_router.dart';
import 'package:coview/screen/auth/domain/bloc/login_event.dart';

import '../../domain/bloc/login_bloc.dart';
import '../../domain/bloc/login_state.dart';
import '../../../../core/widgets/glass_background.dart';
import '../../../../core/widgets/glass_form_card.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/fade_in_up.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/email_field_with_validation.dart';
import '../widgets/password_text_field.dart';
import '../widgets/social_auth_buttons.dart';
import '../widgets/sync_invite_preview.dart';
import '../widgets/kinetic_logo.dart';

class LoginPage extends StatelessWidget {
  final String? inviteHostName;
  final String? inviteHostAvatar;

  const LoginPage({super.key, this.inviteHostName, this.inviteHostAvatar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: _LoginPageContent(
        inviteHostName: inviteHostName,
        inviteHostAvatar: inviteHostAvatar,
      ),
    );
  }
}

class _LoginPageContent extends StatefulWidget {
  final String? inviteHostName;
  final String? inviteHostAvatar;

  const _LoginPageContent({this.inviteHostName, this.inviteHostAvatar});

  @override
  State<_LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<_LoginPageContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);

    if (widget.inviteHostName != null && widget.inviteHostName!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.read<LoginBloc>().add(const GuestLoginRequested());
          }
        });
      });
    }
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      context.read<LoginBloc>().add(const EmailFieldFocused());
    } else {
      context.read<LoginBloc>().add(const FieldUnfocused());
    }
  }

  void _onPasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) {
      context.read<LoginBloc>().add(const PasswordFieldFocused());
    } else {
      context.read<LoginBloc>().add(const FieldUnfocused());
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final loginEmail = context.read<LoginBloc>().state.email.trim();
    final initial = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : loginEmail;
    final emailField = TextEditingController(text: initial);
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailField,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your account email',
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
    final email = emailField.text.trim();
    emailField.dispose();
    if (sent != true || !mounted) return;
    if (!_emailLooksValid(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }
    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Password reset sent to $email')));
    } on fb_auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not send reset email')),
      );
    }
  }

  bool _emailLooksValid(String email) =>
      email.contains('@') &&
      email.length > 3 &&
      !email.startsWith('@') &&
      !email.endsWith('@');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final showInvite =
        widget.inviteHostName != null && widget.inviteHostName!.isNotEmpty;
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const GlassBackground(),
            SafeArea(
              child: BlocListener<LoginBloc, LoginState>(
                listener: (context, state) {
                  if (state.status == LoginStatus.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login successful!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.go('/home');
                  } else if (state.status == LoginStatus.guestSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: AppColors.textWhite,
                            ),
                            const SizedBox(width: 8),
                            const Text('Joined as guest'),
                          ],
                        ),
                        backgroundColor: AppColors.secondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    context.go('/home');
                  } else if (state.status == LoginStatus.failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage ?? 'Login failed'),
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
                      if (showInvite)
                        FadeInUp(
                          delayMs: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SyncInvitePreview(
                              hostName: widget.inviteHostName!,
                              hostAvatarUrl: widget.inviteHostAvatar,
                            ),
                          ),
                        ),
                      BlocBuilder<LoginBloc, LoginState>(
                        buildWhen: (p, c) => p.email != c.email,
                        builder: (context, state) {
                          return FadeInUp(
                            delayMs: 50,
                            child: KineticLogo(
                              keystrokeTrigger: state.email.length,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      FadeInUp(
                        delayMs: 100,
                        child: Text(
                          'Stay Connected',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textWhite.withValues(alpha: 0.75)
                                : AppColors.textDark.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeInUp(
                        delayMs: 150,
                        child: GlassFormCard(
                          children: [
                            BlocBuilder<LoginBloc, LoginState>(
                              buildWhen: (p, c) =>
                                  p.email != c.email ||
                                  p.isEmailValid != c.isEmailValid,
                              builder: (context, state) {
                                return EmailFieldWithValidation(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  emailValue: state.email,
                                  isEmailValid: state.isEmailValid,
                                  labelColor: isDark
                                      ? AppColors.textWhite.withValues(
                                          alpha: 0.95,
                                        )
                                      : AppColors.textDark,
                                  onChanged: (value) {
                                    context.read<LoginBloc>().add(
                                      EmailChanged(value),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            PasswordTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              labelColor: isDark
                                  ? AppColors.textWhite.withValues(alpha: 0.95)
                                  : AppColors.textDark,
                              onChanged: (value) {
                                context.read<LoginBloc>().add(
                                  PasswordChanged(value),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<LoginBloc, LoginState>(
                              buildWhen: (p, c) => p.rememberMe != c.rememberMe,
                              builder: (context, state) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    checkboxTheme: CheckboxThemeData(
                                      fillColor:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >((Set<MaterialState> states) {
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return AppColors.primaryDark;
                                            }
                                            return AppColors.textWhite
                                                .withValues(alpha: 0.4);
                                          }),

                                      checkColor: MaterialStateProperty.all(
                                        AppColors.textWhite,
                                      ),
                                      side: BorderSide(
                                        color: AppColors.textWhite.withValues(
                                          alpha: 0.8,
                                        ),
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: state.rememberMe,
                                          onChanged: (v) {
                                            context.read<LoginBloc>().add(
                                              RememberMeChanged(v ?? false),
                                            );
                                          },
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember Me',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? AppColors.textWhite.withValues(
                                                  alpha: 0.95,
                                                )
                                              : AppColors.textDark.withValues(
                                                  alpha: 0.9,
                                                ),
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          _showForgotPasswordDialog();
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.info,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            BlocBuilder<LoginBloc, LoginState>(
                              builder: (context, state) {
                                return CustomButton(
                                  text: 'Sign In',
                                  height: AppConstants.buttonHeightLarge + 2,
                                  isLoading:
                                      state.status == LoginStatus.loading,
                                  onPressed: state.isFormValid
                                      ? () {
                                          context.read<LoginBloc>().add(
                                            const LoginButtonPressed(),
                                          );
                                        }
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            SocialAuthButtons(
                              onGooglePressed: () {
                                context.read<LoginBloc>().add(
                                  const GoogleLoginRequested(),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textWhite.withValues(
                                            alpha: 0.8,
                                          )
                                        : AppColors.textDark.withValues(
                                            alpha: 0.8,
                                          ),
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textWhite
                                            : AppColors.primaryAccent,
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
