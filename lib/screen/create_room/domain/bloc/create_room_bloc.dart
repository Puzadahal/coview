import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/constants/app_constants.dart';
import 'create_room_event.dart';
import 'create_room_state.dart';

/// BLoC for managing Create Room state
class CreateRoomBloc extends Bloc<CreateRoomEvent, CreateRoomState> {
  CreateRoomBloc() : super(const CreateRoomState()) {
    _firestore = FirebaseFirestore.instance;
    _auth = fb.FirebaseAuth.instance;

    on<RoomNameChanged>(_onRoomNameChanged);
    on<VideoUrlChanged>(_onVideoUrlChanged);
    on<PrivacySettingChanged>(_onPrivacySettingChanged);
    on<HostControlsOnlyChanged>(_onHostControlsOnlyChanged);
    on<ParticipantLimitChanged>(_onParticipantLimitChanged);
    on<TextChatEnabledChanged>(_onTextChatEnabledChanged);
    on<VoiceChatEnabledChanged>(_onVoiceChatEnabledChanged);
    on<VideoBubblesEnabledChanged>(_onVideoBubblesEnabledChanged);
    on<AdvancedSettingsToggled>(_onAdvancedSettingsToggled);
    on<CreateRoomButtonPressed>(_onCreateRoomButtonPressed);
    on<CreateRoomFormReset>(_onCreateRoomFormReset);
  }

  late final FirebaseFirestore _firestore;
  late final fb.FirebaseAuth _auth;

  void _onRoomNameChanged(
    RoomNameChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(roomName: event.name));
  }

  void _onVideoUrlChanged(
    VideoUrlChanged event,
    Emitter<CreateRoomState> emit,
  ) async {
    emit(state.copyWith(
      videoUrl: event.url,
      isUrlValid: false,
      videoThumbnail: null,
      status: CreateRoomStatus.validating,
    ));

    // Validate URL and get thumbnail
    if (event.url.trim().isNotEmpty) {
      final isValid = _validateUrl(event.url);
      String? thumbnail;

      if (isValid) {
        thumbnail = _getThumbnailUrl(event.url);
      }

      emit(state.copyWith(
        isUrlValid: isValid,
        videoThumbnail: thumbnail,
        status: CreateRoomStatus.initial,
      ));
    } else {
      emit(state.copyWith(
        isUrlValid: false,
        videoThumbnail: null,
        status: CreateRoomStatus.initial,
      ));
    }
  }

  void _onPrivacySettingChanged(
    PrivacySettingChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(isPrivate: event.isPrivate));
  }

  void _onHostControlsOnlyChanged(
    HostControlsOnlyChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(hostControlsOnly: event.hostControlsOnly));
  }

  void _onParticipantLimitChanged(
    ParticipantLimitChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    // Clamp the limit between min and max to enforce server constraints
    final clampedLimit = event.limit.clamp(
      AppConstants.minParticipantLimit,
      AppConstants.maxParticipantLimit,
    );
    emit(state.copyWith(participantLimit: clampedLimit));
  }

  void _onTextChatEnabledChanged(
    TextChatEnabledChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(textChatEnabled: event.enabled));
  }

  void _onVoiceChatEnabledChanged(
    VoiceChatEnabledChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(voiceChatEnabled: event.enabled));
  }

  void _onVideoBubblesEnabledChanged(
    VideoBubblesEnabledChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(videoBubblesEnabled: event.enabled));
  }

  void _onAdvancedSettingsToggled(
    AdvancedSettingsToggled event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(isAdvancedSettingsExpanded: event.isExpanded));
  }

  Future<void> _onCreateRoomButtonPressed(
    CreateRoomButtonPressed event,
    Emitter<CreateRoomState> emit,
  ) async {
    if (!state.isFormValid) {
      emit(state.copyWith(
        status: CreateRoomStatus.failure,
        errorMessage: 'Please fill all required fields correctly',
      ));
      return;
    }

    emit(state.copyWith(status: CreateRoomStatus.loading));

    try {
      final fb.User? currentUser = _auth.currentUser;

      final roomId = _generateRoomId();

      final roomData = <String, dynamic>{
        'roomId': roomId,
        'name': state.roomName.trim(),
        'videoUrl': state.videoUrl.trim(),
        'isPrivate': state.isPrivate,
        'hostControlsOnly': state.hostControlsOnly,
        'participantLimit': state.participantLimit,
        'textChatEnabled': state.textChatEnabled,
        'voiceChatEnabled': state.voiceChatEnabled,
        'videoBubblesEnabled': state.videoBubblesEnabled,
        'createdAt': FieldValue.serverTimestamp(),
        'hostId': currentUser?.uid,
        'hostName': currentUser?.displayName ??
            currentUser?.email ??
            'Guest',
      };

      await _firestore.collection('rooms').doc(roomId).set(roomData);

      final inviteLink = 'https://syncview.app/join/$roomId';

      emit(state.copyWith(
        status: CreateRoomStatus.success,
        createdRoomId: roomId,
        inviteLink: inviteLink,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateRoomStatus.failure,
        errorMessage: 'Failed to create room. Please try again.',
      ));
    }
  }

  void _onCreateRoomFormReset(
    CreateRoomFormReset event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(const CreateRoomState());
  }

  /// Validate video URL (supports YouTube, Netflix, and other common formats)
  bool _validateUrl(String url) {
    if (url.trim().isEmpty) return false;

    // Basic URL validation
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    // Check for YouTube
    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      return true;
    }

    // Check for Netflix
    if (uri.host.contains('netflix.com')) {
      return true;
    }

    // Check for other video platforms
    final videoHosts = [
      'vimeo.com',
      'dailymotion.com',
      'twitch.tv',
      'facebook.com',
      'instagram.com',
    ];

    for (final host in videoHosts) {
      if (uri.host.contains(host)) {
        return true;
      }
    }

    // Allow local file paths or other valid URLs
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'file');
  }

  /// Get thumbnail URL from video URL
  String? _getThumbnailUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // YouTube thumbnail
    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      String? videoId;
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else {
        videoId = uri.queryParameters['v'];
      }
      if (videoId != null) {
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    }

    // For other platforms, return null (would need platform-specific APIs)
    return null;
  }

  /// Generate a random room ID
  String _generateRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'room_${random.substring(random.length - 8)}';
  }
}
