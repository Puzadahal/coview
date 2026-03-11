import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_event.dart';
import 'room_state.dart';

/// BLoC that manages basic room UI state (chat messages, status).
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc(String roomId) : super(RoomState.initial(roomId)) {
    _firestore = FirebaseFirestore.instance;
    on<RoomInitialized>(_onInitialized);
    on<RoomMessageSent>(_onMessageSent);
  }

  late final FirebaseFirestore _firestore;

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

  void _onMessageSent(RoomMessageSent event, Emitter<RoomState> emit) {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty) return;
    final updated = List<RoomMessage>.from(state.messages)
      ..add(RoomMessage(author: 'You', text: trimmed));
    emit(state.copyWith(messages: updated));
  }
}

