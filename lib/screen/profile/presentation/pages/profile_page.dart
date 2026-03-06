import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../config/colors/app_colors.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/theme/domain/bloc/theme_bloc.dart';
import '../../../../core/theme/domain/bloc/theme_state.dart';
import '../../../../core/theme/domain/bloc/theme_event.dart';
import '../../../../core/constants/app_constants.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User Name', // TODO: Replace with actual user name
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com', // TODO: Replace with actual email
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Settings Section
            Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Theme Settings Card
            Card(
              elevation: 0,
              color: isDark
                  ? AppColors.primaryDarkVariant.withValues(alpha: 0.5)
                  : AppColors.backgroundWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMedium),
                child: Row(
                  children: [
                    Icon(
                      Icons.brightness_6,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          BlocBuilder<ThemeBloc, ThemeState>(
                            builder: (context, state) {
                              String themeText = '';
                              switch (state.mode) {
                                case ThemeModeType.light:
                                  themeText = 'Light Mode';
                                  break;
                                case ThemeModeType.dark:
                                  themeText = 'Dark Mode';
                                  break;
                                case ThemeModeType.system:
                                  themeText = 'System Default';
                                  break;
                              }
                              return Text(
                                themeText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Settings Card
            Card(
              elevation: 0,
              color: isDark
                  ? AppColors.primaryDarkVariant.withValues(alpha: 0.5)
                  : AppColors.backgroundWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.edit,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Edit Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to edit profile page
                    },
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.lock,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Change Password',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to change password page
                    },
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Notifications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Switch(
                      value: true, // TODO: Get from state/preferences
                      onChanged: (value) {
                        // TODO: Update notification settings
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // About Section
            Text(
              'About',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              color: isDark
                  ? AppColors.primaryDarkVariant.withValues(alpha: 0.5)
                  : AppColors.backgroundWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'App Version',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      '1.0.0', // TODO: Get from package info
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to privacy policy
                    },
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.description,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Terms of Service',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to terms of service
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Logout'),
                        content: const Text(
                          'Are you sure you want to logout?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.textWhite,
                            ),
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await fb.FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
