import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

class CreateRoomState extends Equatable {
  final String roomName;
  final String videoUrl;
  final bool isPrivate;
  final bool hostControlsOnly;
  final int participantLimit;
  final bool textChatEnabled;
  final bool voiceChatEnabled;
  final bool videoBubblesEnabled;
  final bool isAdvancedSettingsExpanded;
  final bool isUrlValid;
  final String? videoThumbnail;
  final CreateRoomStatus status;
  final String? errorMessage;
  final String? createdRoomId;
  final String? inviteLink;

  const CreateRoomState({
    this.roomName = '',
    this.videoUrl = '',
    this.isPrivate = false,
    this.hostControlsOnly = false,
    this.participantLimit = AppConstants.defaultParticipantLimit,
    this.textChatEnabled = true,
    this.voiceChatEnabled = false,
    this.videoBubblesEnabled = false,
    this.isAdvancedSettingsExpanded = false,
    this.isUrlValid = false,
    this.videoThumbnail,
    this.status = CreateRoomStatus.initial,
    this.errorMessage,
    this.createdRoomId,
    this.inviteLink,
  });

  bool get isFormValid {
    return roomName.trim().isNotEmpty && 
           videoUrl.trim().isNotEmpty && 
           isUrlValid;
  }

  CreateRoomState copyWith({
    String? roomName,
    String? videoUrl,
    bool? isPrivate,
    bool? hostControlsOnly,
    int? participantLimit,
    bool? textChatEnabled,
    bool? voiceChatEnabled,
    bool? videoBubblesEnabled,
    bool? isAdvancedSettingsExpanded,
    bool? isUrlValid,
    String? videoThumbnail,
    CreateRoomStatus? status,
    String? errorMessage,
    String? createdRoomId,
    String? inviteLink,
  }) {
    return CreateRoomState(
      roomName: roomName ?? this.roomName,
      videoUrl: videoUrl ?? this.videoUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      hostControlsOnly: hostControlsOnly ?? this.hostControlsOnly,
      participantLimit: participantLimit ?? this.participantLimit,
      textChatEnabled: textChatEnabled ?? this.textChatEnabled,
      voiceChatEnabled: voiceChatEnabled ?? this.voiceChatEnabled,
      videoBubblesEnabled: videoBubblesEnabled ?? this.videoBubblesEnabled,
      isAdvancedSettingsExpanded: isAdvancedSettingsExpanded ?? this.isAdvancedSettingsExpanded,
      isUrlValid: isUrlValid ?? this.isUrlValid,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdRoomId: createdRoomId ?? this.createdRoomId,
      inviteLink: inviteLink ?? this.inviteLink,
    );
  }

  @override
  List<Object?> get props => [
        roomName,
        videoUrl,
        isPrivate,
        hostControlsOnly,
        participantLimit,
        textChatEnabled,
        voiceChatEnabled,
        videoBubblesEnabled,
        isAdvancedSettingsExpanded,
        isUrlValid,
        videoThumbnail,
        status,
        errorMessage,
        createdRoomId,
        inviteLink,
      ];
}

enum CreateRoomStatus {
  initial,
  validating,
  loading,
  success,
  failure,
}
