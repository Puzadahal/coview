import 'package:equatable/equatable.dart';

class RoomMessage extends Equatable {
  final String author;
  final String text;
  final DateTime? createdAt;

  const RoomMessage({
    required this.author,
    required this.text,
    this.createdAt,
  });

  @override
  List<Object?> get props => [author, text, createdAt];
}

enum RoomStatus { viewing, loading, error }

class RoomState extends Equatable {
  final String roomId;
  final List<RoomMessage> messages;
  final RoomStatus status;
  final String? error;
  final String? roomName;
  final String? videoUrl;

  const RoomState({
    required this.roomId,
    required this.messages,
    this.status = RoomStatus.viewing,
    this.error,
    this.roomName,
    this.videoUrl,
  });

  factory RoomState.initial(String roomId) {
    return RoomState(
      roomId: roomId,
      messages: const [],
    );
  }

  RoomState copyWith({
    String? roomId,
    List<RoomMessage>? messages,
    RoomStatus? status,
    String? error,
    String? roomName,
    String? videoUrl,
  }) {
    return RoomState(
      roomId: roomId ?? this.roomId,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      error: error,
      roomName: roomName ?? this.roomName,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  List<Object?> get props => [roomId, messages, status, error, roomName, videoUrl];
}

