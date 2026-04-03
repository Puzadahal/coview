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
  final bool isPlaying;
  final double playbackPositionSeconds;
  /// Firestore `updatedAt` (ms since epoch) when [playbackPositionSeconds] was written.
  final int playbackAnchorServerTimeMs;
  final int playbackVersion;

  const RoomState({
    required this.roomId,
    required this.messages,
    this.status = RoomStatus.viewing,
    this.error,
    this.roomName,
    this.videoUrl,
    this.isPlaying = false,
    this.playbackPositionSeconds = 0,
    this.playbackAnchorServerTimeMs = 0,
    this.playbackVersion = 0,
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
    bool? isPlaying,
    double? playbackPositionSeconds,
    int? playbackAnchorServerTimeMs,
    int? playbackVersion,
  }) {
    return RoomState(
      roomId: roomId ?? this.roomId,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      error: error,
      roomName: roomName ?? this.roomName,
      videoUrl: videoUrl ?? this.videoUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackPositionSeconds:
          playbackPositionSeconds ?? this.playbackPositionSeconds,
      playbackAnchorServerTimeMs:
          playbackAnchorServerTimeMs ?? this.playbackAnchorServerTimeMs,
      playbackVersion: playbackVersion ?? this.playbackVersion,
    );
  }

  @override
  List<Object?> get props => [
        roomId,
        messages,
        status,
        error,
        roomName,
        videoUrl,
        isPlaying,
        playbackPositionSeconds,
        playbackAnchorServerTimeMs,
        playbackVersion,
      ];
}

