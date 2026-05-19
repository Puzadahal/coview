import 'package:equatable/equatable.dart';
import 'room_state.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class RoomInitialized extends RoomEvent {
  const RoomInitialized();
}

class RoomMessageSent extends RoomEvent {
  final String text;

  const RoomMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

class RoomMessagesUpdated extends RoomEvent {
  final List<RoomMessage> messages;

  const RoomMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

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

class RoomPlaybackUpdated extends RoomEvent {
  final bool isPlaying;
  final double positionSeconds;
  final int anchorServerTimeMs;
  final int version;

  const RoomPlaybackUpdated({
    required this.isPlaying,
    required this.positionSeconds,
    required this.anchorServerTimeMs,
    required this.version,
  });

  @override
  List<Object?> get props => [
    isPlaying,
    positionSeconds,
    anchorServerTimeMs,
    version,
  ];
}

class RoomDeleteRequested extends RoomEvent {
  const RoomDeleteRequested();
}

class RoomActionMessageConsumed extends RoomEvent {
  const RoomActionMessageConsumed();
}
