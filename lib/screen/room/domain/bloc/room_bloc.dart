import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'room_event.dart';
import 'room_state.dart';

/// BLoC that manages basic room UI state (chat messages, status).
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc(String roomId) : super(RoomState.initial(roomId)) {
    _firestore = FirebaseFirestore.instance;
    _auth = fb.FirebaseAuth.instance;
    on<RoomInitialized>(_onInitialized);
    on<RoomMessageSent>(_onMessageSent);
    on<RoomMessagesUpdated>(_onMessagesUpdated);
    on<RoomPlaybackSetRequested>(_onPlaybackSetRequested);
    on<RoomPlaybackUpdated>(_onPlaybackUpdated);
  }

  late final FirebaseFirestore _firestore;
  late final fb.FirebaseAuth _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _playbackSub;

  Future<void> _onInitialized(
    RoomInitialized event,
    Emitter<RoomState> emit,
  ) async {
    emit(state.copyWith(status: RoomStatus.loading, error: null));

    try {
      final doc =
          await _firestore.collection('rooms').doc(state.roomId).get();

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

      // Start listening to room messages in Firestore
      _messagesSub?.cancel();
      _messagesSub = _firestore
          .collection('rooms')
          .doc(state.roomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen((snapshot) {
        final messages = snapshot.docs.map((doc) {
          final data = doc.data();
          final ts = data['createdAt'];
          DateTime? createdAt;
          if (ts is Timestamp) {
            createdAt = ts.toDate();
          }
          return RoomMessage(
            author: (data['author'] as String?) ?? 'Guest',
            text: (data['text'] as String?) ?? '',
            createdAt: createdAt,
          );
        }).toList();
        add(RoomMessagesUpdated(messages));
      });

      _playbackSub?.cancel();
      _playbackSub = _firestore
          .collection('rooms')
          .doc(state.roomId)
          .collection('playback')
          .doc('state')
          .snapshots()
          .listen((snap) {
        final data = snap.data();
        if (data == null) return;
        add(
          RoomPlaybackUpdated(
            isPlaying: (data['isPlaying'] as bool?) ?? false,
            positionSeconds: (data['positionSeconds'] as num?)?.toDouble() ?? 0,
            version: (data['version'] as num?)?.toInt() ?? 0,
          ),
        );
      });

      emit(
        state.copyWith(
          status: RoomStatus.viewing,
          error: null,
          roomName: name,
          videoUrl: videoUrl,
        ),
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

  Future<void> _onMessageSent(
    RoomMessageSent event,
    Emitter<RoomState> emit,
  ) async {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty) return;

    final user = _auth.currentUser;
    final authorName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Guest');

    await _firestore
        .collection('rooms')
        .doc(state.roomId)
        .collection('messages')
        .add({
      'text': trimmed,
      'author': authorName,
      'authorId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _onMessagesUpdated(
    RoomMessagesUpdated event,
    Emitter<RoomState> emit,
  ) {
    emit(state.copyWith(messages: event.messages));
  }

  Future<void> _onPlaybackSetRequested(
    RoomPlaybackSetRequested event,
    Emitter<RoomState> emit,
  ) async {
    final nextVersion = state.playbackVersion + 1;
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
      'version': nextVersion,
    }, SetOptions(merge: true));
  }

  void _onPlaybackUpdated(
    RoomPlaybackUpdated event,
    Emitter<RoomState> emit,
  ) {
    emit(
      state.copyWith(
        isPlaying: event.isPlaying,
        playbackPositionSeconds: event.positionSeconds,
        playbackVersion: event.version,
      ),
    );
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    _playbackSub?.cancel();
    return super.close();
  }
}

