import 'package:flutter_bloc/flutter_bloc.dart';
import 'room_event.dart';
import 'room_state.dart';

/// BLoC that manages basic room UI state (chat messages, status).
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc(String roomId) : super(RoomState.initial(roomId)) {
    on<RoomInitialized>(_onInitialized);
    on<RoomMessageSent>(_onMessageSent);
  }

  void _onInitialized(RoomInitialized event, Emitter<RoomState> emit) {
    // Placeholder for future initialization logic (e.g. join WS, load history).
    emit(state.copyWith(status: RoomStatus.viewing, error: null));
  }

  void _onMessageSent(RoomMessageSent event, Emitter<RoomState> emit) {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty) return;
    final updated = List<RoomMessage>.from(state.messages)
      ..add(RoomMessage(author: 'You', text: trimmed));
    emit(state.copyWith(messages: updated));
  }
}

