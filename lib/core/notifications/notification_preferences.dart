import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  final bool pushEnabled;
  final bool messageNotifications;
  final bool roomInviteNotifications;
  final bool systemAlerts;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.messageNotifications = true,
    this.roomInviteNotifications = true,
    this.systemAlerts = true,
  });

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? messageNotifications,
    bool? roomInviteNotifications,
    bool? systemAlerts,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      messageNotifications:
          messageNotifications ?? this.messageNotifications,
      roomInviteNotifications:
          roomInviteNotifications ?? this.roomInviteNotifications,
      systemAlerts: systemAlerts ?? this.systemAlerts,
    );
  }

  static const prefsPushKey = 'notify_push_enabled';
  static const prefsMessagesKey = 'notify_recent_messages';
  static const prefsInvitesKey = 'notify_room_invites';
  static const prefsSystemKey = 'notify_system_alerts';

  Map<String, dynamic> toFirestoreMap() {
    return {
      'notificationsEnabled': pushEnabled,
      'messageNotifications': messageNotifications,
      'roomInviteNotifications': roomInviteNotifications,
      'systemAlerts': systemAlerts,
      'notificationChannels': ['push', 'inApp'],
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory NotificationPreferences.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const NotificationPreferences();
    return NotificationPreferences(
      pushEnabled: data['notificationsEnabled'] as bool? ?? true,
      messageNotifications: data['messageNotifications'] as bool? ?? true,
      roomInviteNotifications:
          data['roomInviteNotifications'] as bool? ?? true,
      systemAlerts: data['systemAlerts'] as bool? ?? true,
    );
  }

  static Future<NotificationPreferences> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      pushEnabled: prefs.getBool(prefsPushKey) ?? true,
      messageNotifications: prefs.getBool(prefsMessagesKey) ?? true,
      roomInviteNotifications: prefs.getBool(prefsInvitesKey) ?? true,
      systemAlerts: prefs.getBool(prefsSystemKey) ?? true,
    );
  }

  Future<void> saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsPushKey, pushEnabled);
    await prefs.setBool(prefsMessagesKey, messageNotifications);
    await prefs.setBool(prefsInvitesKey, roomInviteNotifications);
    await prefs.setBool(prefsSystemKey, systemAlerts);
  }
}
