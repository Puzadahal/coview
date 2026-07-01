import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/notifications/notification_preferences.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/theme/domain/bloc/theme_bloc.dart';
import '../../../../core/theme/domain/bloc/theme_state.dart';
import '../../../../core/theme/domain/bloc/theme_event.dart';
import '../../../../core/widgets/app_back_app_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/constants/app_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _loadingPrefs = true;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs =
          await NotificationService.instance.loadPreferencesForUi();
      final pkg = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _loadingPrefs = false;
        _appVersion = '${pkg.version}+${pkg.buildNumber}';
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _updatePref(
    NotificationPreferences Function(NotificationPreferences) update,
  ) async {
    final next = update(_prefs);
    setState(() => _prefs = next);
    await NotificationService.instance.updatePreferences(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppBackAppBar(title: 'Profile', transparent: true),
      body: StreamBuilder<fb.User?>(
        stream: fb.FirebaseAuth.instance.userChanges(),
        initialData: fb.FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          final currentUser = snapshot.data;
          final displayName =
              (currentUser?.displayName?.trim().isNotEmpty ?? false)
              ? currentUser!.displayName!.trim()
              : 'User';
          final emailText = currentUser?.email ?? 'No email';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                        photoUrl: currentUser?.photoURL,
                        radius: 60,
                        backgroundColor: theme.colorScheme.primary,
                        iconSize: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emailText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'Settings',
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
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusLarge,
                    ),
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
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
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

                Card(
                  elevation: 0,
                  color: isDark
                      ? AppColors.primaryDarkVariant.withValues(alpha: 0.5)
                      : AppColors.backgroundWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusLarge,
                    ),
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
                          context.push('/profile/edit');
                        },
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
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
                          context.push('/profile/change-password');
                        },
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.notifications_active_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          'In-app alerts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Show alerts while you are using SyncView',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                        trailing: _loadingPrefs
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Switch(
                                value: _prefs.pushEnabled,
                                onChanged: (value) => _updatePref(
                                  (p) => p.copyWith(pushEnabled: value),
                                ),
                              ),
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.chat_bubble_outline,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          'Room messages',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text('Chat activity in your watch rooms'),
                        value: _prefs.messageNotifications,
                        onChanged: _loadingPrefs || !_prefs.pushEnabled
                            ? null
                            : (value) => _updatePref(
                                  (p) => p.copyWith(messageNotifications: value),
                                ),
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.group_add_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          'Room Invites',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _prefs.roomInviteNotifications,
                        onChanged: _loadingPrefs || !_prefs.pushEnabled
                            ? null
                            : (value) => _updatePref(
                                  (p) =>
                                      p.copyWith(roomInviteNotifications: value),
                                ),
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.warning_amber_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          'System Alerts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _prefs.systemAlerts,
                        onChanged: _loadingPrefs || !_prefs.pushEnabled
                            ? null
                            : (value) => _updatePref(
                                  (p) => p.copyWith(systemAlerts: value),
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

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
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusLarge,
                    ),
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
                          _appVersion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
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
                          context.push('/profile/privacy-policy');
                        },
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
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
                          context.push('/profile/terms');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

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
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
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
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool('logged_in', false);
                                  } catch (_) {}
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
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium,
                        ),
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
          );
        },
      ),
    );
  }
}
