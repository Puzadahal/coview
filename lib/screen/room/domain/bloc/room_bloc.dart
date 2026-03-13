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
  }

  late final FirebaseFirestore _firestore;
  late final fb.FirebaseAuth _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;

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

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    return super.close();
  }
}

