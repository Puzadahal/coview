import 'package:equatable/equatable.dart';
import 'room_state.dart';

/// Events for the Coview room (chat + playback shell).
abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class RoomInitialized extends RoomEvent {
  const RoomInitialized();
}

/// User sends a chat message.
class RoomMessageSent extends RoomEvent {
  final String text;

  const RoomMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

/// Incoming messages snapshot from backend.
class RoomMessagesUpdated extends RoomEvent {
  final List<RoomMessage> messages;

  const RoomMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

