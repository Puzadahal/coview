import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Someone the user saves for quick re-invites from the room share sheet.
class RoomShareRecipient {
  RoomShareRecipient({
    required this.id,
    required this.name,
    this.phoneDigits,
    int? lastUsedMs,
  }) : lastUsedMs = lastUsedMs ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  final String name;
  /// Digits only, country code included (e.g. 14155552671) for wa.me links.
  final String? phoneDigits;
  final int lastUsedMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (phoneDigits != null && phoneDigits!.isNotEmpty)
          'phoneDigits': phoneDigits,
        'lastUsedMs': lastUsedMs,
      };

  static RoomShareRecipient fromJson(Map<String, dynamic> j) {
    return RoomShareRecipient(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? 'Guest',
      phoneDigits: j['phoneDigits'] as String?,
      lastUsedMs: (j['lastUsedMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Persists people shown in the room share sheet (device-local).
class RoomShareRecentsStore {
  RoomShareRecentsStore._();
  static const _key = 'room_share_recents_v1';
  static const int maxRecipients = 20;

  static Future<List<RoomShareRecipient>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((e) => RoomShareRecipient.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((r) => r.id.isNotEmpty && r.name.trim().isNotEmpty)
          .toList();
      list.sort((a, b) => b.lastUsedMs.compareTo(a.lastUsedMs));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<RoomShareRecipient> list) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = list.take(maxRecipients).toList();
    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> upsert(RoomShareRecipient recipient) async {
    final all = await load();
    all.removeWhere((r) => r.id == recipient.id);
    all.insert(0, recipient);
    await save(all);
  }

  static Future<void> remove(String id) async {
    final all = await load();
    all.removeWhere((r) => r.id == id);
    await save(all);
  }

  static Future<void> touch(String id) async {
    final all = await load();
    final i = all.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final r = all[i];
    all[i] = RoomShareRecipient(
      id: r.id,
      name: r.name,
      phoneDigits: r.phoneDigits,
      lastUsedMs: DateTime.now().millisecondsSinceEpoch,
    );
    all.sort((a, b) => b.lastUsedMs.compareTo(a.lastUsedMs));
    await save(all);
  }

  static String normalizePhoneDigits(String raw) {
    return raw.replaceAll(RegExp(r'\D'), '');
  }
}
