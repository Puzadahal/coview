import 'package:equatable/equatable.dart';

class RoomMessage extends Equatable {
  final String author;
  final String? authorId;
  final String text;
  final DateTime? createdAt;

  const RoomMessage({
    required this.author,
    this.authorId,
    required this.text,
    this.createdAt,
  });

  @override
  List<Object?> get props => [author, authorId, text, createdAt];
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
  final int playbackAnchorServerTimeMs;
  final int playbackVersion;
  final bool textChatEnabled;
  final bool videoCallEnabled;
  final bool videoBubblesEnabled;
  final bool sensitiveWordsFilterEnabled;
  final String? hostId;
  final bool roomDeleted;
  final String? actionMessage;

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
    this.textChatEnabled = true,
    this.videoCallEnabled = true,
    this.videoBubblesEnabled = false,
    this.sensitiveWordsFilterEnabled = true,
    this.hostId,
    this.roomDeleted = false,
    this.actionMessage,
  });

  factory RoomState.initial(String roomId) {
    return RoomState(roomId: roomId, messages: const []);
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
    bool? textChatEnabled,
    bool? videoCallEnabled,
    bool? videoBubblesEnabled,
    bool? sensitiveWordsFilterEnabled,
    String? hostId,
    bool? roomDeleted,
    String? actionMessage,
    bool clearActionMessage = false,
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
      textChatEnabled: textChatEnabled ?? this.textChatEnabled,
      videoCallEnabled: videoCallEnabled ?? this.videoCallEnabled,
      videoBubblesEnabled: videoBubblesEnabled ?? this.videoBubblesEnabled,
      sensitiveWordsFilterEnabled:
          sensitiveWordsFilterEnabled ?? this.sensitiveWordsFilterEnabled,
      hostId: hostId ?? this.hostId,
      roomDeleted: roomDeleted ?? this.roomDeleted,
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
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
    textChatEnabled,
    videoCallEnabled,
    videoBubblesEnabled,
    sensitiveWordsFilterEnabled,
    hostId,
    roomDeleted,
    actionMessage,
  ];
}
