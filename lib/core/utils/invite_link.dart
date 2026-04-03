/// Resolves a path-style invite (e.g. `/join/room_abc`) into a full URL on web,
/// or returns the room id when running as a non-http `Uri.base` (mobile/desktop).
String buildShareableInviteLink({
  required String inviteLink,
  required String roomId,
}) {
  if (inviteLink.startsWith('http')) return inviteLink;
  final base = Uri.base;
  final scheme = base.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return '${base.origin}/#/join/$roomId';
  }
  return roomId;
}
