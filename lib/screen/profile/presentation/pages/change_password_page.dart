import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/custom_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newPass = _newController.text.trim();
    final confirm = _confirmController.text.trim();
    if (newPass.length < 8) {
      AppSnackBar.error(context, 'New password must be at least 8 chars.');
      return;
    }
    if (newPass != confirm) {
      AppSnackBar.error(context, 'New password and confirm do not match.');
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      AppSnackBar.error(
        context,
        'Password change is available for email users only.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: _currentController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);
      if (!mounted) return;
      AppSnackBar.success(context, 'Password updated successfully.');
      context.pop();
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.message ?? 'Failed to update password.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppConstants.spacingLarge,
          AppConstants.spacingLarge,
          AppConstants.spacingLarge,
          AppConstants.spacingLarge + keyboardHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            const SizedBox(height: AppConstants.spacingXLarge),
            CustomButton(
              text: 'Update Password',
              isLoading: _saving,
              onPressed: _saving ? null : _changePassword,
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.textWhite,
            ),
          ],
        ),
      ),
    );
  }
}
