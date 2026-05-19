import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart' as fs;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _syncIntervalController = TextEditingController(text: '60');
  String? _currentPhotoUrl;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoExtension;
  bool _loading = true;
  bool _saving = false;
  bool _autoSyncEnabled = true;
  bool _syncOnWifiOnly = false;
  bool _backgroundSyncEnabled = true;
  bool _notifySyncFailures = true;
  bool _notifyConflicts = true;
  bool _notifyNewDeviceLogin = true;
  bool _notifyRoomInvites = true;
  bool _notifyMessages = true;
  String _conflictHandlingStrategy = 'lastWriteWins';
  String _deviceId = '';
  List<String> _deviceIds = const [];
  int _profileVersion = 0;

  static const _conflictStrategies = [
    'lastWriteWins',
    'manualReview',
    'serverWins',
    'clientWins',
    'mergeFields',
  ];

  @override
  void initState() {
    super.initState();
    final user = fb.FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _currentPhotoUrl = user?.photoURL;
    _loadProfileSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _syncIntervalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileSettings() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await _currentDeviceId(prefs, user.uid);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      final syncSettings = _mapValue(data['syncSettings']);
      final devices = _mapValue(data['devices']);
      final notifications = _mapValue(data['notifications']);
      final existingDeviceIds =
          (devices['deviceIds'] as List?)?.whereType<String>().toSet() ??
          <String>{};
      existingDeviceIds.add(deviceId);

      if (!mounted) return;
      setState(() {
        _bioController.text = (data['bio'] as String?) ?? '';
        _autoSyncEnabled = (syncSettings['autoSyncEnabled'] as bool?) ?? true;
        _syncIntervalController.text =
            ((syncSettings['autoSyncIntervalSeconds'] as num?)?.toInt() ?? 60)
                .toString();
        _syncOnWifiOnly = (syncSettings['syncOnWifiOnly'] as bool?) ?? false;
        _backgroundSyncEnabled =
            (syncSettings['backgroundSyncEnabled'] as bool?) ?? true;
        _conflictHandlingStrategy =
            (syncSettings['conflictHandlingStrategy'] as String?) ??
            'lastWriteWins';
        if (!_conflictStrategies.contains(_conflictHandlingStrategy)) {
          _conflictHandlingStrategy = 'lastWriteWins';
        }
        _profileVersion =
            (syncSettings['profileVersion'] as num?)?.toInt() ?? 0;
        _notifySyncFailures =
            (notifications['notifyOnSyncFailure'] as bool?) ?? true;
        _notifyConflicts =
            (notifications['notifyOnConflictDetected'] as bool?) ?? true;
        _notifyNewDeviceLogin =
            (notifications['notifyOnNewDeviceLogin'] as bool?) ?? true;
        _notifyRoomInvites =
            (notifications['roomInviteNotifications'] as bool?) ??
            (prefs.getBool('notify_room_invites') ?? true);
        _notifyMessages =
            (notifications['messageNotifications'] as bool?) ??
            (prefs.getBool('notify_recent_messages') ?? true);
        _deviceId = deviceId;
        _deviceIds = existingDeviceIds.toList()..sort();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load profile settings: $e')),
      );
    }
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Future<String> _currentDeviceId(SharedPreferences prefs, String uid) async {
    final existing = prefs.getString('current_device_id');
    if (existing != null && existing.isNotEmpty) return existing;

    final uidPrefix = uid.length > 8 ? uid.substring(0, 8) : uid;
    final deviceId =
        'device_${uidPrefix}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('current_device_id', deviceId);
    return deviceId;
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected image.')),
      );
      return;
    }

    setState(() {
      _selectedPhotoBytes = bytes;
      _selectedPhotoExtension = file.extension;
    });
  }

  Future<String?> _uploadProfilePhoto(fb.User user) async {
    final bytes = _selectedPhotoBytes;
    if (bytes == null) {
      return _currentPhotoUrl;
    }

    final extension = _safeImageExtension(_selectedPhotoExtension);
    final ref = fs.FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(user.uid)
        .child('avatar_${DateTime.now().millisecondsSinceEpoch}.$extension');

    final upload = await ref.putData(
      bytes,
      fs.SettableMetadata(contentType: _contentTypeForExtension(extension)),
    );

    return upload.ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final displayName = _nameController.text.trim();
      final bio = _bioController.text.trim();
      final syncIntervalSeconds =
          (int.tryParse(_syncIntervalController.text.trim()) ?? 60)
              .clamp(15, 86400)
              .toInt();
      final uploadedPhotoUrl = _selectedPhotoBytes == null
          ? _currentPhotoUrl
          : await _uploadProfilePhoto(user);

      await user.updateDisplayName(displayName.isEmpty ? null : displayName);
      if (uploadedPhotoUrl != user.photoURL) {
        await user.updatePhotoURL(uploadedPhotoUrl);
      }
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool('notify_recent_messages', _notifyMessages),
        prefs.setBool('notify_room_invites', _notifyRoomInvites),
        prefs.setBool('notify_system_alerts', _notifySyncFailures),
        prefs.setBool('auto_sync_enabled', _autoSyncEnabled),
        prefs.setInt('auto_sync_interval_seconds', syncIntervalSeconds),
      ]);

      final nextProfileVersion = _profileVersion + 1;
      final deviceIds = {..._deviceIds, _deviceId}.where((id) => id.isNotEmpty);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': displayName.isEmpty ? 'User' : displayName,
        'displayName': displayName.isEmpty ? 'User' : displayName,
        'bio': bio,
        'photo': uploadedPhotoUrl,
        'avatarUrl': uploadedPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'syncSettings': {
          'autoSyncEnabled': _autoSyncEnabled,
          'autoSyncIntervalSeconds': syncIntervalSeconds,
          'syncOnWifiOnly': _syncOnWifiOnly,
          'backgroundSyncEnabled': _backgroundSyncEnabled,
          'conflictHandlingStrategy': _conflictHandlingStrategy,
          'profileVersion': nextProfileVersion,
          'syncStatus': 'synced',
        },
        'devices': {
          'primaryDeviceId': _deviceId,
          'currentDeviceId': _deviceId,
          'deviceIds': deviceIds.toList()..sort(),
          'lastActiveDeviceAt': FieldValue.serverTimestamp(),
        },
        'notifications': {
          'notificationsEnabled': true,
          'notifyOnSyncFailure': _notifySyncFailures,
          'notifyOnConflictDetected': _notifyConflicts,
          'notifyOnNewDeviceLogin': _notifyNewDeviceLogin,
          'roomInviteNotifications': _notifyRoomInvites,
          'messageNotifications': _notifyMessages,
          'notificationChannels': ['push', 'inApp'],
        },
      }, SetOptions(merge: true));
      await user.reload();
      if (!mounted) return;
      setState(() {
        _currentPhotoUrl = uploadedPhotoUrl;
        _selectedPhotoBytes = null;
        _profileVersion = nextProfileVersion;
        _syncIntervalController.text = syncIntervalSeconds.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      context.pop();
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update profile.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ImageProvider? get _avatarImage {
    final selectedBytes = _selectedPhotoBytes;
    if (selectedBytes != null) return MemoryImage(selectedBytes);

    final photoUrl = _currentPhotoUrl?.trim();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return NetworkImage(photoUrl);
    }

    return null;
  }

  String _safeImageExtension(String? extension) {
    final value = extension?.toLowerCase().replaceFirst('.', '') ?? '';
    return switch (value) {
      'jpg' || 'jpeg' || 'png' || 'webp' => value,
      _ => 'jpg',
    };
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpeg' || 'jpg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarImage = _avatarImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingLarge),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        title: 'Identity',
                        subtitle:
                            'These fields identify you in rooms and sync logs.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundImage: avatarImage,
                                    onForegroundImageError:
                                        avatarImage is NetworkImage
                                        ? (_, _) {}
                                        : null,
                                    child: const Icon(
                                      Icons.person,
                                      size: 56,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Material(
                                      color: AppColors.primaryAccent,
                                      shape: const CircleBorder(),
                                      elevation: 2,
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: _saving
                                            ? null
                                            : _pickProfilePhoto,
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: AppColors.textWhite,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingLarge),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                helperText:
                                    'Shown in rooms, chat, and sync activity.',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMedium),
                            TextField(
                              controller: _bioController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                helperText:
                                    'Synced profile metadata visible from your account.',
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMedium),
                      _SectionCard(
                        title: 'Synchronization',
                        subtitle:
                            'Controls how this profile and app settings stay aligned across devices.',
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Auto-sync'),
                              subtitle: const Text(
                                'Automatically checks for profile and room updates.',
                              ),
                              value: _autoSyncEnabled,
                              onChanged: (value) =>
                                  setState(() => _autoSyncEnabled = value),
                            ),
                            TextField(
                              controller: _syncIntervalController,
                              enabled: _autoSyncEnabled,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Auto-sync interval',
                                suffixText: 'seconds',
                                helperText:
                                    'Minimum 15 seconds. Lower values sync faster but use more network.',
                                prefixIcon: Icon(Icons.sync_outlined),
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMedium),
                            DropdownButtonFormField<String>(
                              initialValue: _conflictHandlingStrategy,
                              decoration: const InputDecoration(
                                labelText: 'Conflict handling',
                                helperText:
                                    'Defines what happens when two devices edit the profile.',
                                prefixIcon: Icon(Icons.merge_type_outlined),
                              ),
                              items: _conflictStrategies
                                  .map(
                                    (strategy) => DropdownMenuItem(
                                      value: strategy,
                                      child: Text(
                                        _conflictStrategyLabel(strategy),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(
                                  () => _conflictHandlingStrategy = value,
                                );
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Sync on Wi-Fi only'),
                              subtitle: const Text(
                                'Reduces mobile data usage for background sync.',
                              ),
                              value: _syncOnWifiOnly,
                              onChanged: (value) =>
                                  setState(() => _syncOnWifiOnly = value),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Background sync'),
                              subtitle: const Text(
                                'Keeps profile and settings fresh while the app is not active.',
                              ),
                              value: _backgroundSyncEnabled,
                              onChanged: (value) => setState(
                                () => _backgroundSyncEnabled = value,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMedium),
                      _SectionCard(
                        title: 'Device Identity',
                        subtitle:
                            'Device IDs help SyncView know which client changed synced data.',
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.devices_outlined,
                              label: 'Current device ID',
                              value: _deviceId.isEmpty ? 'Pending' : _deviceId,
                            ),
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.verified_user_outlined,
                              label: 'Registered devices',
                              value: '${_deviceIds.length} device(s)',
                            ),
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.history_outlined,
                              label: 'Profile sync version',
                              value: 'v$_profileVersion',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMedium),
                      _SectionCard(
                        title: 'Notifications',
                        subtitle:
                            'Choose which sync and room events should alert you.',
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Sync failures'),
                              subtitle: const Text(
                                'Alert when profile or room data cannot sync.',
                              ),
                              value: _notifySyncFailures,
                              onChanged: (value) =>
                                  setState(() => _notifySyncFailures = value),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Conflict detected'),
                              subtitle: const Text(
                                'Alert when another device creates a sync conflict.',
                              ),
                              value: _notifyConflicts,
                              onChanged: (value) =>
                                  setState(() => _notifyConflicts = value),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('New device login'),
                              subtitle: const Text(
                                'Alert when a new device is linked to your account.',
                              ),
                              value: _notifyNewDeviceLogin,
                              onChanged: (value) =>
                                  setState(() => _notifyNewDeviceLogin = value),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Room invites'),
                              subtitle: const Text(
                                'Alert when someone invites you to a room.',
                              ),
                              value: _notifyRoomInvites,
                              onChanged: (value) =>
                                  setState(() => _notifyRoomInvites = value),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Room messages'),
                              subtitle: const Text(
                                'Alert for chat activity in synced rooms.',
                              ),
                              value: _notifyMessages,
                              onChanged: (value) =>
                                  setState(() => _notifyMessages = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingLarge),
                      ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textWhite,
                                ),
                              )
                            : const Text('Save Profile Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _conflictStrategyLabel(String strategy) {
    return switch (strategy) {
      'manualReview' => 'Manual review',
      'serverWins' => 'Server wins',
      'clientWins' => 'This device wins',
      'mergeFields' => 'Merge compatible fields',
      _ => 'Last write wins',
    };
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark
          ? AppColors.primaryDarkVariant.withValues(alpha: 0.55)
          : AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXSmall),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: AppConstants.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelLarge),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
