import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/constants/app_constants.dart';
import 'create_room_event.dart';
import 'create_room_state.dart';

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
    on<VideoCallEnabledChanged>(_onVideoCallEnabledChanged);
    on<VideoBubblesEnabledChanged>(_onVideoBubblesEnabledChanged);
    on<SensitiveWordsFilterChanged>(_onSensitiveWordsFilterChanged);
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
    final normalized = _normalizeVideoUrl(event.url);
    emit(
      state.copyWith(
        videoUrl: normalized,
        isUrlValid: false,
        videoThumbnail: null,
        status: CreateRoomStatus.validating,
      ),
    );

    if (normalized.trim().isNotEmpty) {
      final isValid = _validateUrl(normalized);
      String? thumbnail;

      if (isValid) {
        thumbnail = _getThumbnailUrl(normalized);
      }

      emit(
        state.copyWith(
          isUrlValid: isValid,
          videoThumbnail: thumbnail,
          status: CreateRoomStatus.initial,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isUrlValid: false,
          videoThumbnail: null,
          status: CreateRoomStatus.initial,
        ),
      );
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

  void _onVideoCallEnabledChanged(
    VideoCallEnabledChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(videoCallEnabled: event.enabled));
  }

  void _onVideoBubblesEnabledChanged(
    VideoBubblesEnabledChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(videoBubblesEnabled: event.enabled));
  }

  void _onSensitiveWordsFilterChanged(
    SensitiveWordsFilterChanged event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(state.copyWith(sensitiveWordsFilterEnabled: event.enabled));
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
      emit(
        state.copyWith(
          status: CreateRoomStatus.failure,
          errorMessage: 'Please fill all required fields correctly',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CreateRoomStatus.loading));

    try {
      fb.User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        try {
          final cred = await _auth.signInAnonymously();
          currentUser = cred.user;
        } on fb.FirebaseAuthException catch (e) {
          emit(
            state.copyWith(
              status: CreateRoomStatus.failure,
              errorMessage: e.code == 'operation-not-allowed'
                  ? 'Anonymous sign-in is disabled. Enable it in Firebase Console → Authentication → Sign-in method, or log in with Google.'
                  : 'Could not start a guest session (${e.message ?? e.code}).',
            ),
          );
          return;
        }
      }

      final roomId = _generateRoomId();

      final roomData = <String, dynamic>{
        'roomId': roomId,
        'name': state.roomName.trim(),
        'videoUrl': _normalizeVideoUrl(state.videoUrl),
        'isPrivate': state.isPrivate,
        'hostControlsOnly': state.hostControlsOnly,
        'participantLimit': state.participantLimit,
        'textChatEnabled': state.textChatEnabled,
        'voiceChatEnabled': state.voiceChatEnabled,
        'videoCallEnabled': state.videoCallEnabled,
        'videoBubblesEnabled': state.videoBubblesEnabled,
        'sensitiveWordsFilterEnabled': state.sensitiveWordsFilterEnabled,
        'createdAt': FieldValue.serverTimestamp(),
        'hostId': currentUser?.uid,
        'hostName': currentUser?.displayName ?? currentUser?.email ?? 'Guest',
      };
      final storagePath = _extractFirebaseStoragePath(state.videoUrl);
      if (storagePath != null) {
        roomData['videoStoragePath'] = storagePath;
      }

      await _firestore.collection('rooms').doc(roomId).set(roomData);

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('playback')
          .doc('state')
          .set({
            'isPlaying': false,
            'positionSeconds': 0.0,
            'updatedAt': FieldValue.serverTimestamp(),
            'version': 1,
            'actorId': currentUser?.uid,
          }, SetOptions(merge: true));

      if (currentUser != null) {
        try {
          final userRoomsRef = _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('rooms')
              .doc(roomId);
          await userRoomsRef.set({
            'roomId': roomId,
            'name': state.roomName.trim(),
            'videoUrl': _normalizeVideoUrl(state.videoUrl),
            'isHost': true,
            'lastJoinedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e, st) {
          debugPrint('CreateRoom: could not save user room history: $e\n$st');
        }
      }

      final inviteLink = '/join/$roomId';

      emit(
        state.copyWith(
          status: CreateRoomStatus.success,
          createdRoomId: roomId,
          inviteLink: inviteLink,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('CreateRoom Firestore/Auth error: ${e.code} ${e.message}');
      emit(
        state.copyWith(
          status: CreateRoomStatus.failure,
          errorMessage: _firestoreErrorMessage(e),
        ),
      );
    } catch (e, st) {
      debugPrint('CreateRoom error: $e\n$st');
      emit(
        state.copyWith(
          status: CreateRoomStatus.failure,
          errorMessage: 'Failed to create room: $e',
        ),
      );
    }
  }

  String _firestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. Publish the Firestore rules (rooms + users/.../rooms) and try again.';
      case 'unavailable':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message?.isNotEmpty == true
            ? '${e.code}: ${e.message}'
            : 'Failed to create room (${e.code}).';
    }
  }

  void _onCreateRoomFormReset(
    CreateRoomFormReset event,
    Emitter<CreateRoomState> emit,
  ) {
    emit(const CreateRoomState());
  }

  bool _validateUrl(String url) {
    if (url.trim().isEmpty) return false;
    if (_isLikelyLocalVideoPath(url)) return true;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    if (uri.host.isEmpty) return false;

    return true;
  }

  bool _isLikelyLocalVideoPath(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return false;

    final uri = Uri.tryParse(raw);
    final hasLocalScheme = uri?.scheme == 'file';
    final hasWindowsDrive = RegExp(r'^[a-zA-Z]:\\').hasMatch(raw);
    final hasUnixLikePath = raw.startsWith('/') || raw.startsWith('./');
    if (!hasLocalScheme && !hasWindowsDrive && !hasUnixLikePath) return false;

    final lower = raw.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.wmv') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m3u8');
  }

  String _normalizeVideoUrl(String input) {
    final raw = input.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      if (id.isNotEmpty) return 'https://www.youtube.com/watch?v=$id';
    }
    if (host.contains('youtube.com')) {
      final id = uri.queryParameters['v'];
      if (id != null && id.isNotEmpty) {
        return 'https://www.youtube.com/watch?v=$id';
      }
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments.first == 'shorts') {
        return 'https://www.youtube.com/watch?v=${segments[1]}';
      }
    }
    return raw;
  }

  String? _getThumbnailUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

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

    return null;
  }

  String _generateRoomId() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'room_${random.substring(random.length - 8)}';
  }

  String? _extractFirebaseStoragePath(String input) {
    final raw = input.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return null;
    final host = uri.host.toLowerCase();
    if (!(host.contains('firebasestorage.googleapis.com') ||
        host.contains('storage.googleapis.com'))) {
      return null;
    }
    final marker = '/o/';
    final idx = uri.path.indexOf(marker);
    if (idx == -1) return null;
    final encoded = uri.path.substring(idx + marker.length);
    if (encoded.isEmpty) return null;
    return Uri.decodeComponent(encoded);
  }
}
