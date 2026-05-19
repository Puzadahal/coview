import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/theme/domain/bloc/theme_bloc.dart';
import '../../../../core/theme/domain/bloc/theme_state.dart';
import '../../../../core/theme/domain/bloc/theme_event.dart';
import '../../../../core/constants/app_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifyRecentMessages = true;
  bool _notifyRoomInvites = true;
  bool _notifySystemAlerts = true;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pkg = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _notifyRecentMessages = prefs.getBool('notify_recent_messages') ?? true;
        _notifyRoomInvites = prefs.getBool('notify_room_invites') ?? true;
        _notifySystemAlerts = prefs.getBool('notify_system_alerts') ?? true;
        _appVersion = '${pkg.version}+${pkg.buildNumber}';
      });
    } catch (_) {}
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

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
                      _UserAvatar(
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
                          value: _notifyRecentMessages,
                          onChanged: (value) {
                            setState(() => _notifyRecentMessages = value);
                            _saveNotificationSetting(
                              'notify_recent_messages',
                              value,
                            );
                          },
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
                        value: _notifyRoomInvites,
                        onChanged: (value) {
                          setState(() => _notifyRoomInvites = value);
                          _saveNotificationSetting(
                            'notify_room_invites',
                            value,
                          );
                        },
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
                        value: _notifySystemAlerts,
                        onChanged: (value) {
                          setState(() => _notifySystemAlerts = value);
                          _saveNotificationSetting(
                            'notify_system_alerts',
                            value,
                          );
                        },
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

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final double iconSize;

  const _UserAvatar({
    required this.photoUrl,
    required this.radius,
    required this.backgroundColor,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPhotoUrl = photoUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundImage: trimmedPhotoUrl == null || trimmedPhotoUrl.isEmpty
          ? null
          : NetworkImage(trimmedPhotoUrl),
      onForegroundImageError: trimmedPhotoUrl == null || trimmedPhotoUrl.isEmpty
          ? null
          : (_, _) {},
      child: Icon(Icons.person, size: iconSize, color: AppColors.textWhite),
    );
  }
}
