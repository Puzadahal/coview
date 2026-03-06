import 'package:equatable/equatable.dart';

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

