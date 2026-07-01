import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'join_room_event.dart';
import 'join_room_state.dart';

class JoinRoomBloc extends Bloc<JoinRoomEvent, JoinRoomState> {
  JoinRoomBloc() : super(const JoinRoomState()) {
    on<JoinRoomInputChanged>(_onInputChanged);
    on<JoinRoomSubmitted>(_onSubmitted);
  }

  void _onInputChanged(
    JoinRoomInputChanged event,
    Emitter<JoinRoomState> emit,
  ) {
    if (state.status == JoinRoomStatus.validating) return;
    emit(
      state.copyWith(
        rawInput: event.value,
        error: null,
        status: JoinRoomStatus.initial,
      ),
    );
  }

  Future<void> _onSubmitted(
    JoinRoomSubmitted event,
    Emitter<JoinRoomState> emit,
  ) async {
    if (state.status == JoinRoomStatus.validating) return;

    final raw = state.rawInput.trim();
    if (raw.isEmpty) {
      emit(
        state.copyWith(
          error: 'Please paste an invite link or room code.',
          status: JoinRoomStatus.failure,
        ),
      );
      return;
    }

    String roomId = raw;
    if (raw.contains('http')) {
      final uri = Uri.tryParse(raw);
      if (uri == null || uri.pathSegments.isEmpty) {
        emit(
          state.copyWith(
            error: 'Invalid invite link.',
            status: JoinRoomStatus.failure,
          ),
        );
        return;
      }
      roomId = uri.pathSegments.last;
    }

    if (!roomId.startsWith('room_')) {
      emit(
        state.copyWith(
          error: 'Invalid room code. It should look like "room_1234abcd".',
          status: JoinRoomStatus.failure,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        error: null,
        status: JoinRoomStatus.validating,
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      if (!doc.exists) {
        emit(
          state.copyWith(
            error:
                'Room not found. Check the code and make sure the host is online.',
            status: JoinRoomStatus.failure,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          resolvedRoomId: roomId,
          error: null,
          status: JoinRoomStatus.success,
        ),
      );
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          error: e.code == 'permission-denied'
              ? 'Could not verify room. Sign in and try again.'
              : 'Network error. Check your connection and try again.',
          status: JoinRoomStatus.failure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          error: 'Could not verify room. Check your connection and try again.',
          status: JoinRoomStatus.failure,
        ),
      );
    }
  }
}

