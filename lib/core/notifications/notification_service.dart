import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/routes/app_router.dart';
import 'notification_preferences.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'syncview_alerts',
    'SyncView Alerts',
    description: 'Room invites, chat messages, and app alerts',
    importance: Importance.high,
  );

  bool _initialized = false;
  NotificationPreferences _preferences = const NotificationPreferences();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inviteSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _systemAlertSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _roomsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _roomMessageSubs = {};
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _roomCallInviteSubs = {};
  final Map<String, DateTime> _roomLastSeen = {};
  final Set<String> _seenInviteIds = {};
  final Set<String> _seenSystemAlertIds = {};
  final Set<String> _seenCallInviteKeys = {};
  final Map<String, int> _roomCallInviteGeneration = {};

  NotificationPreferences get preferences => _preferences;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _configureLocalNotifications();
    await _loadPreferences();
    await _requestLocalPermission();

    fb.FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null && !user.isAnonymous) {
        await _startInAppListeners(user.uid);
      } else {
        await _stopInAppListeners();
      }
    });

    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await _startInAppListeners(user.uid);
    }
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.startsWith('/')) {
          appRouter.go(payload);
        }
      },
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _requestLocalPermission() async {
    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    await macPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _loadPreferences() async {
    _preferences = await NotificationPreferences.loadLocal();
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final remote = NotificationPreferences.fromFirestore(
        doc.data()?['notifications'] as Map<String, dynamic>?,
      );
      _preferences = remote;
      await _preferences.saveLocal();
    } catch (e) {
      debugPrint('NotificationService: load prefs failed: $e');
    }
  }

  Future<NotificationPreferences> loadPreferencesForUi() async {
    await _loadPreferences();
    return _preferences;
  }

  Future<void> updatePreferences(NotificationPreferences prefs) async {
    _preferences = prefs;
    await prefs.saveLocal();

    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'notifications': prefs.toFirestoreMap()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('NotificationService: save prefs failed: $e');
    }
  }

  Future<void> _startInAppListeners(String userId) async {
    await _stopInAppListeners();

    _inviteSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('pendingInvites')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final id = change.doc.id;
        if (_seenInviteIds.contains(id)) continue;
        _seenInviteIds.add(id);

        if (!_preferences.pushEnabled || !_preferences.roomInviteNotifications) {
          continue;
        }
        final data = change.doc.data() ?? {};
        final hostName = data['hostName'] as String? ?? 'Someone';
        final roomName = data['roomName'] as String? ?? 'Watch Room';
        final roomId = data['roomId'] as String? ?? '';
        _showLocalNotification(
          title: 'Room invite',
          body: '$hostName invited you to "$roomName".',
          payload: roomId.isNotEmpty ? '/join/$roomId' : '/join-room',
        );
      }
    });

    _systemAlertSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('systemAlerts')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final id = change.doc.id;
        if (_seenSystemAlertIds.contains(id)) continue;
        _seenSystemAlertIds.add(id);

        if (!_preferences.pushEnabled || !_preferences.systemAlerts) continue;
        final data = change.doc.data() ?? {};
        _showLocalNotification(
          title: data['title'] as String? ?? 'SyncView',
          body: data['body'] as String? ?? 'You have a new alert.',
          payload: data['route'] as String? ?? '/profile',
        );
      }
    });

    _roomsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final roomId = change.doc.id;
        if (change.type == DocumentChangeType.removed) {
          _roomMessageSubs.remove(roomId)?.cancel();
          _roomCallInviteSubs.remove(roomId)?.cancel();
          _roomLastSeen.remove(roomId);
          _roomCallInviteGeneration.remove(roomId);
          continue;
        }
        final roomData = change.doc.data() ?? {};
        final roomName = roomData['name'] as String? ?? 'Watch Room';
        _roomMessageSubs[roomId]?.cancel();
        _roomLastSeen[roomId] ??= DateTime.now();
        _roomMessageSubs[roomId] = FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((msgSnap) {
          if (msgSnap.docs.isEmpty) return;
          final data = msgSnap.docs.first.data();
          final ts = data['createdAt'];
          if (ts is! Timestamp) return;

          final createdAt = ts.toDate();
          final lastSeen = _roomLastSeen[roomId] ?? DateTime.now();
          if (!createdAt.isAfter(lastSeen)) return;
          _roomLastSeen[roomId] = createdAt;

          if (!_preferences.pushEnabled || !_preferences.messageNotifications) {
            return;
          }
          if ((data['authorId'] as String?) == userId) return;

          final author = data['author'] as String? ?? 'Someone';
          final text = data['text'] as String? ?? '';
          _showLocalNotification(
            title: roomName,
            body: '$author: $text',
            payload: '/join/$roomId',
          );
        });
        _roomCallInviteSubs[roomId]?.cancel();
        _roomCallInviteSubs[roomId] = FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('call')
            .doc('invite')
            .snapshots()
            .listen((inviteDoc) {
          final data = inviteDoc.data();
          if (data == null) return;
          final active = data['active'] == true;
          final generation = data['generation'] as int? ?? 0;
          final hostId = data['hostId'] as String? ?? '';
          if (hostId == userId) return;

          final lastGen = _roomCallInviteGeneration[roomId];
          if (lastGen == null) {
            _roomCallInviteGeneration[roomId] = generation;
            return;
          }
          if (!active || generation <= lastGen) {
            if (!active) _roomCallInviteGeneration[roomId] = 0;
            return;
          }
          _roomCallInviteGeneration[roomId] = generation;

          final key = '$roomId-$generation';
          if (_seenCallInviteKeys.contains(key)) return;
          _seenCallInviteKeys.add(key);

          if (!_preferences.pushEnabled || !_preferences.systemAlerts) return;

          final hostName = data['hostName'] as String? ?? 'Someone';
          _showLocalNotification(
            title: 'Video call in $roomName',
            body: '$hostName started a video call. Tap to join.',
            payload: '/join/$roomId',
          );
        });
      }
    });
  }

  Future<void> _stopInAppListeners() async {
    await _inviteSub?.cancel();
    await _systemAlertSub?.cancel();
    await _roomsSub?.cancel();
    _inviteSub = null;
    _systemAlertSub = null;
    _roomsSub = null;
    for (final sub in _roomMessageSubs.values) {
      await sub.cancel();
    }
    for (final sub in _roomCallInviteSubs.values) {
      await sub.cancel();
    }
    _roomMessageSubs.clear();
    _roomCallInviteSubs.clear();
    _roomLastSeen.clear();
    _roomCallInviteGeneration.clear();
    _seenInviteIds.clear();
    _seenSystemAlertIds.clear();
    _seenCallInviteKeys.clear();
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'syncview_alerts',
        'SyncView Alerts',
        channelDescription: 'Room invites, chat messages, and app alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
