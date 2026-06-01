const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

async function loadUserNotificationPrefs(userId) {
  const snap = await db.collection('users').doc(userId).get();
  const notifications = snap.data()?.notifications || {};
  return {
    pushEnabled: notifications.notificationsEnabled !== false,
    messageNotifications: notifications.messageNotifications !== false,
    roomInviteNotifications: notifications.roomInviteNotifications !== false,
    systemAlerts: notifications.systemAlerts !== false,
  };
}

async function loadUserTokens(userId) {
  const snap = await db.collection('users').doc(userId).collection('fcmTokens').get();
  return snap.docs.map((doc) => doc.data().token).filter(Boolean);
}

async function sendPushToUser(userId, { title, body, type, route, extraData = {} }) {
  const prefs = await loadUserNotificationPrefs(userId);
  if (!prefs.pushEnabled) return;

  const allowed =
    (type === 'room_message' && prefs.messageNotifications) ||
    (type === 'room_invite' && prefs.roomInviteNotifications) ||
    (type === 'system_alert' && prefs.systemAlerts);

  if (!allowed) return;

  const tokens = await loadUserTokens(userId);
  if (tokens.length === 0) return;

  await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: {
      type,
      route: route || '',
      ...extraData,
    },
    android: {
      notification: {
        channelId: 'syncview_alerts',
      },
    },
  });
}

exports.onRoomMessageCreated = onDocumentCreated(
  'rooms/{roomId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const roomId = event.params.roomId;
    const authorId = message.authorId || '';
    const author = message.author || 'Someone';
    const text = message.text || '';

    const roomSnap = await db.collection('rooms').doc(roomId).get();
    const roomName = roomSnap.data()?.name || 'Watch Room';

    const participantsSnap = await db
      .collection('rooms')
      .doc(roomId)
      .collection('participants')
      .get();

    const sends = participantsSnap.docs
      .filter((doc) => doc.id !== authorId)
      .map((doc) =>
        sendPushToUser(doc.id, {
          title: roomName,
          body: `${author}: ${text}`,
          type: 'room_message',
          route: `/join/${roomId}`,
          extraData: { roomId },
        }),
      );

    await Promise.all(sends);
  },
);

exports.onPendingInviteCreated = onDocumentCreated(
  'users/{userId}/pendingInvites/{inviteId}',
  async (event) => {
    const invite = event.data?.data();
    if (!invite) return;

    const userId = event.params.userId;
    const roomId = invite.roomId || '';
    const roomName = invite.roomName || 'Watch Room';
    const hostName = invite.hostName || 'Someone';

    await sendPushToUser(userId, {
      title: 'Room invite',
      body: `${hostName} invited you to "${roomName}"`,
      type: 'room_invite',
      route: roomId ? `/join/${roomId}` : '/join-room',
      extraData: { roomId },
    });
  },
);

exports.onSystemAlertCreated = onDocumentCreated(
  'users/{userId}/systemAlerts/{alertId}',
  async (event) => {
    const alert = event.data?.data();
    if (!alert) return;

    const userId = event.params.userId;
    await sendPushToUser(userId, {
      title: alert.title || 'SyncView',
      body: alert.body || 'You have a new alert.',
      type: 'system_alert',
      route: alert.route || '/profile',
    });
  },
);
