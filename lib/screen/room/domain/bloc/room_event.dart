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

/// User requests play/pause for room-wide sync.
class RoomPlaybackSetRequested extends RoomEvent {
  final bool isPlaying;
  final double positionSeconds;

  const RoomPlaybackSetRequested({
    required this.isPlaying,
    required this.positionSeconds,
  });

  @override
  List<Object?> get props => [isPlaying, positionSeconds];
}

/// Incoming playback state from backend.
class RoomPlaybackUpdated extends RoomEvent {
  final bool isPlaying;
  final double positionSeconds;
  /// [Timestamp.millisecondsSinceEpoch] from the same document write.
  final int anchorServerTimeMs;
  final int version;

  const RoomPlaybackUpdated({
    required this.isPlaying,
    required this.positionSeconds,
    required this.anchorServerTimeMs,
    required this.version,
  });

  @override
  List<Object?> get props => [isPlaying, positionSeconds, anchorServerTimeMs, version];
}

