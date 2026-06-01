import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc(String roomId) : super(RoomState.initial(roomId)) {
    _firestore = FirebaseFirestore.instance;
    _auth = fb.FirebaseAuth.instance;
    on<RoomInitialized>(_onInitialized);
    on<RoomMessageSent>(_onMessageSent);
    on<RoomMessagesUpdated>(_onMessagesUpdated);
    on<RoomPlaybackSetRequested>(_onPlaybackSetRequested);
    on<RoomPlaybackUpdated>(_onPlaybackUpdated);
    on<RoomDeleteRequested>(_onRoomDeleteRequested);
    on<RoomActionMessageConsumed>(_onActionMessageConsumed);
  }

  late final FirebaseFirestore _firestore;
  late final fb.FirebaseAuth _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _playbackSub;

  DateTime? _guestChatSessionStart;
  static final RegExp _wordBoundary = RegExp(r'(^|[^a-zA-Z0-9])');
  static const List<String> _sensitiveWords = [
    'abuse',
    'nude',
    'porn',
    'kill',
    'suicide',
    'hate',
  ];

  bool _isGuestForChatSession(fb.User? user) =>
      user == null || user.isAnonymous;

  List<RoomMessage> _filterMessagesForGuestSession(List<RoomMessage> all) {
    final start = _guestChatSessionStart;
    if (start == null) return all;
    return all.where((m) {
      final t = m.createdAt;
      if (t == null) {
        return true;
      }
      return !t.isBefore(start);
    }).toList();
  }

  Future<void> _onInitialized(
    RoomInitialized event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.loading, error: null));

    try {
      final doc = await _firestore.collection('rooms').doc(state.roomId).get();

      if (!doc.exists) {
        emit(
          state.copyWith(
            status: RoomStatus.error,
            error: 'Room not found. The invite may be invalid or expired.',
          ),
        );
        return;
      }

      final data = doc.data() ?? {};
      final name = data['name'] as String? ?? 'Watch Room';
      final videoUrl = data['videoUrl'] as String?;
      final hostId = data['hostId'] as String?;
      final textChatEnabled = data['textChatEnabled'] as bool? ?? true;
      final videoCallEnabled = data['videoCallEnabled'] as bool? ?? true;
      final videoBubblesEnabled = data['videoBubblesEnabled'] as bool? ?? false;
      final sensitiveWordsFilterEnabled =
          data['sensitiveWordsFilterEnabled'] as bool? ?? true;

      // Firestore rules require request.auth != null for playback/* (see firestore.rules).
      // "Continue as guest" has no Firebase user until we sign in anonymously.
      var playbackSyncEnabled = true;
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
        } on fb.FirebaseAuthException catch (e) {
          debugPrint(
            'RoomBloc: anonymous sign-in failed (playback sync disabled): $e',
          );
          playbackSyncEnabled = false;
        }
      }
      if (_auth.currentUser == null) {
        playbackSyncEnabled = false;
      }

      final user = _auth.currentUser;
      _guestChatSessionStart = _isGuestForChatSession(user)
          ? DateTime.now().subtract(const Duration(seconds: 30))
          : null;

      if (playbackSyncEnabled && _auth.currentUser != null) {
        final playbackRef = _firestore
            .collection('rooms')
            .doc(state.roomId)
            .collection('playback')
            .doc('state');
        final existing = await playbackRef.get();
        if (!existing.exists) {
          await playbackRef.set({
            'isPlaying': false,
            'positionSeconds': 0.0,
            'updatedAt': FieldValue.serverTimestamp(),
            'version': 1,
            'actorId': _auth.currentUser!.uid,
          }, SetOptions(merge: true));
        }
      }

      _messagesSub?.cancel();
      _messagesSub = _firestore
          .collection('rooms')
          .doc(state.roomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              final messages = snapshot.docs.map((doc) {
                final data = doc.data();
                final ts = data['createdAt'];
                DateTime? createdAt;
                if (ts is Timestamp) {
                  createdAt = ts.toDate();
                }
                return RoomMessage(
                  author: (data['author'] as String?) ?? 'Guest',
                  authorId: data['authorId'] as String?,
                  text: (data['text'] as String?) ?? '',
                  createdAt: createdAt,
                );
              }).toList();
              add(
                RoomMessagesUpdated(_filterMessagesForGuestSession(messages)),
              );
            },
            onError: (Object e, StackTrace st) {
              debugPrint('RoomBloc: messages subscription error: $e\n$st');
            },
          );

      _playbackSub?.cancel();
      if (playbackSyncEnabled) {
        _playbackSub = _firestore
            .collection('rooms')
            .doc(state.roomId)
            .collection('playback')
            .doc('state')
            .snapshots()
            .listen(
              (snap) {
                final snapData = snap.data();
                if (snapData == null) return;
                final updatedAt = snapData['updatedAt'];
                int anchorMs = 0;
                if (updatedAt is Timestamp) {
                  anchorMs = updatedAt.millisecondsSinceEpoch;
                }
                add(
                  RoomPlaybackUpdated(
                    isPlaying: (snapData['isPlaying'] as bool?) ?? false,
                    positionSeconds:
                        (snapData['positionSeconds'] as num?)?.toDouble() ?? 0,
                    anchorServerTimeMs: anchorMs,
                    version: (snapData['version'] as num?)?.toInt() ?? 0,
                  ),
                );
              },
              onError: (Object e, StackTrace st) {
                debugPrint('RoomBloc: playback subscription error: $e\n$st');
              },
            );
      }

      emit(
        state.copyWith(
          status: RoomStatus.viewing,
          error: null,
          roomName: name,
          videoUrl: videoUrl,
          hostId: hostId,
          textChatEnabled: textChatEnabled,
          videoCallEnabled: videoCallEnabled,
          videoBubblesEnabled: videoBubblesEnabled,
          sensitiveWordsFilterEnabled: sensitiveWordsFilterEnabled,
        ),
      );

      await _registerParticipant(
        user: user,
        roomId: state.roomId,
        roomName: name,
        videoUrl: videoUrl,
        hostId: hostId,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RoomStatus.error,
          error: 'Failed to load room. Please try again.',
        ),
      );
    }
  }

  Future<void> _registerParticipant({
    required fb.User? user,
    required String roomId,
    required String roomName,
    required String? videoUrl,
    required String? hostId,
  }) async {
    if (user == null || user.isAnonymous) return;

    final displayName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email ?? 'User');

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'displayName': displayName,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final isHost = hostId != null && hostId == user.uid;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('rooms')
          .doc(roomId)
          .set({
        'roomId': roomId,
        'name': roomName,
        'videoUrl': videoUrl ?? '',
        'isHost': isHost,
        'lastJoinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('RoomBloc: participant registration failed: $e\n$st');
    }
  }

  Future<void> _onMessageSent(
    RoomMessageSent event,
    Emitter<RoomState> emit,
  ) async {
    if (!state.textChatEnabled) return;

    final trimmed = event.text.trim();
    if (trimmed.isEmpty) return;
    final sanitized = state.sensitiveWordsFilterEnabled
        ? _sanitizeSensitiveContent(trimmed)
        : trimmed;

    final user = _auth.currentUser;
    final authorName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Guest');

    await _firestore
        .collection('rooms')
        .doc(state.roomId)
        .collection('messages')
        .add({
          'text': sanitized,
          'author': authorName,
          'authorId': user?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  void _onMessagesUpdated(RoomMessagesUpdated event, Emitter<RoomState> emit) {
    emit(state.copyWith(messages: event.messages));
  }

  Future<void> _onPlaybackSetRequested(
    RoomPlaybackSetRequested event,
    Emitter<RoomState> emit,
  ) async {
    if (_auth.currentUser == null) {
      debugPrint('RoomBloc: skip playback write (no Firebase user)');
      return;
    }
    try {
      await _firestore
          .collection('rooms')
          .doc(state.roomId)
          .collection('playback')
          .doc('state')
          .set({
            'isPlaying': event.isPlaying,
            'positionSeconds': event.positionSeconds,
            'updatedAt': FieldValue.serverTimestamp(),
            'actorId': _auth.currentUser?.uid,
            'version': FieldValue.increment(1),
          }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('RoomBloc: playback write failed: ${e.code} ${e.message}');
    }
  }

  void _onPlaybackUpdated(RoomPlaybackUpdated event, Emitter<RoomState> emit) {
    emit(
      state.copyWith(
        isPlaying: event.isPlaying,
        playbackPositionSeconds: event.positionSeconds,
        playbackAnchorServerTimeMs: event.anchorServerTimeMs,
        playbackVersion: event.version,
      ),
    );
  }

  Future<void> _onRoomDeleteRequested(
    RoomDeleteRequested event,
    Emitter<RoomState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(actionMessage: 'Please sign in first.'));
      return;
    }
    if (state.hostId == null || state.hostId != user.uid) {
      emit(
        state.copyWith(actionMessage: 'Only the room host can delete room.'),
      );
      return;
    }

    try {
      final roomRef = _firestore.collection('rooms').doc(state.roomId);
      final roomSnap = await roomRef.get();
      final data = roomSnap.data() ?? <String, dynamic>{};
      final storagePath = data['videoStoragePath'] as String?;
      final videoUrl = data['videoUrl'] as String?;

      await _deleteSubcollection(roomRef.collection('messages'));
      await _deleteSubcollection(roomRef.collection('playback'));
      await _deleteCallTree(roomRef);
      await roomRef.delete();

      if (storagePath != null && storagePath.trim().isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(storagePath).delete();
        } catch (e, st) {
          debugPrint('RoomBloc: storage delete by path failed: $e\n$st');
        }
      } else if (videoUrl != null && _looksLikeStorageUrl(videoUrl)) {
        try {
          await FirebaseStorage.instance.refFromURL(videoUrl).delete();
        } catch (e, st) {
          debugPrint('RoomBloc: storage delete by url failed: $e\n$st');
        }
      }

      emit(
        state.copyWith(
          roomDeleted: true,
          actionMessage: 'Room deleted successfully.',
        ),
      );
    } catch (e, st) {
      debugPrint('RoomBloc: delete room failed: $e\n$st');
      emit(state.copyWith(actionMessage: 'Failed to delete room.'));
    }
  }

  void _onActionMessageConsumed(
    RoomActionMessageConsumed event,
    Emitter<RoomState> emit,
  ) {
    emit(state.copyWith(clearActionMessage: true));
  }

  /// Deletes `call/{peerDoc}` docs and nested `call/{peerDoc}/candidates/*`.
  Future<void> _deleteCallTree(
    DocumentReference<Map<String, dynamic>> roomRef,
  ) async {
    final snap = await roomRef.collection('call').get();
    for (final doc in snap.docs) {
      await _deleteSubcollection(doc.reference.collection('candidates'));
      await doc.reference.delete();
    }
  }

  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> colRef,
  ) async {
    while (true) {
      final snap = await colRef.limit(50).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  bool _looksLikeStorageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('firebasestorage.googleapis.com') ||
        host.contains('storage.googleapis.com');
  }

  String _sanitizeSensitiveContent(String value) {
    var output = value;
    for (final word in _sensitiveWords) {
      final pattern = RegExp(
        '${_wordBoundary.pattern}${RegExp.escape(word)}(?=\$|[^a-zA-Z0-9])',
        caseSensitive: false,
      );
      output = output.replaceAllMapped(pattern, (match) {
        final prefix = match.group(1) ?? '';
        final masked = '*' * word.length;
        return '$prefix$masked';
      });
    }
    return output;
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    _playbackSub?.cancel();
    return super.close();
  }
}
