import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/moderation/chat_moderation.dart';
import '../../../../core/permissions/call_permissions.dart';
import '../../../../core/sync/ntp_clock.dart';
import '../../../../core/sync/playback_sync_math.dart';
import '../../../../core/utils/invite_link.dart';
import '../../../../core/video/video_url_classifier.dart';
import '../../../../core/video/web_video_resolver.dart';
import '../../domain/bloc/room_bloc.dart';
import '../../domain/bloc/room_event.dart';
import '../../domain/bloc/room_state.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/report_message_dialog.dart';
import '../widgets/room_share_sheet.dart';
import '../widgets/room_video_call_bubbles.dart';
import '../widgets/web_page_player_view.dart';
import '../widgets/youtube_player_view.dart';
import '../../domain/room_call_service.dart';

class RoomPage extends StatefulWidget {
  final String roomId;

  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoFuture;
  String? _currentVideoUrl;
  String? _preparedSourceUrl;
  VideoPlaybackKind _playbackKind = VideoPlaybackKind.unsupported;
  bool _resolvingPlayback = false;
  final WebVideoResolver _webVideoResolver = WebVideoResolver();
  final GlobalKey<YoutubePlayerViewState> _youtubeKey =
      GlobalKey<YoutubePlayerViewState>();
  final GlobalKey<WebPagePlayerViewState> _webPageKey =
      GlobalKey<WebPagePlayerViewState>();
  RoomCallService? _callService;
  StreamSubscription<MediaStream>? _remoteStreamSub;
  StreamSubscription<RoomCallConnectionState>? _callConnectionSub;
  MediaStream? _localCallStream;
  MediaStream? _remoteCallStream;
  RoomCallConnectionState _callConnectionState = RoomCallConnectionState.idle;
  bool _micMuted = false;
  bool _cameraMuted = false;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;
  bool _isCallConnecting = false;
  bool _videoBubbleVisible = false;
  Offset _remoteBubbleOffset = const Offset(12, 12);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _incomingCallSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remoteNameSub;
  bool _incomingCallPrimed = false;
  int _lastSeenCallGeneration = 0;
  String _remoteParticipantName = 'Guest';
  int _remoteStreamVersion = 0;
  Timer? _callConnectWatchdog;
  int _lastPlaybackVersionApplied = -1;
  //Avoid back-to-back YouTube drift seeks; each seek shows buffering/loading.
  DateTime? _lastYoutubeDriftSeekWallClock;
  Timer? _driftTimer;
  Timer? _playbackSpeedResetTimer;
  RoomStatus _listenerPrevStatus = RoomStatus.viewing;
  // YouTube in-player fullscreen: hide chat, show video only.
  bool _youtubeImmersive = false;
  // Non-YouTube: user tapped app fullscreen control.
  bool _manualVideoOnly = false;
  bool _notifyRecentMessages = true;
  bool _notifyRoomInvites = true;
  bool _notifySystemAlerts = true;
  int _lastKnownMessageCount = 0;

  bool get _videoOnlyLayout => _youtubeImmersive || _manualVideoOnly;

  bool get _hasRemoteVideo {
    final stream = _remoteCallStream;
    if (stream == null) return false;
    final tracks = stream.getVideoTracks();
    return tracks.isNotEmpty &&
        tracks.any((track) => track.enabled && !(track.muted ?? false));
  }

  String _fallbackRemoteName(RoomState state, bool isRoomHost) {
    if (!isRoomHost && state.hostId != null) {
      for (final message in state.messages.reversed) {
        if (message.authorId == state.hostId) {
          return message.author;
        }
      }
      return 'Host';
    }
    for (final message in state.messages.reversed) {
      if (message.authorId != null && message.authorId != state.hostId) {
        return message.author;
      }
    }
    return 'Guest';
  }

  void _listenForRemoteParticipantName(bool isRoomHost) {
    _remoteNameSub?.cancel();
    final peerDoc = isRoomHost ? 'guest' : 'host';
    _remoteNameSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('call')
        .doc(peerDoc)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final name = doc.data()?['participantName'] as String?;
      if (name == null || name.trim().isEmpty) return;
      setState(() => _remoteParticipantName = name.trim());
    });
  }

  void _primeRemoteParticipantName(RoomState state, bool isRoomHost) {
    _remoteParticipantName = _fallbackRemoteName(state, isRoomHost);
    if (!isRoomHost) {
      unawaited(
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('call')
            .doc('invite')
            .get()
            .then((doc) {
          if (!mounted) return;
          final inviteName = doc.data()?['hostName'] as String?;
          if (inviteName != null && inviteName.trim().isNotEmpty) {
            setState(() => _remoteParticipantName = inviteName.trim());
          }
        }),
      );
    }
    _listenForRemoteParticipantName(isRoomHost);
  }

  void _dismissCallSnackBars() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _startCallConnectWatchdog() {
    _callConnectWatchdog?.cancel();
    _callConnectWatchdog = Timer(const Duration(seconds: 25), () {
      if (!mounted) return;
      if (_callConnectionState != RoomCallConnectionState.connecting) return;
      setState(() => _callConnectionState = RoomCallConnectionState.failed);
      AppSnackBar.error(
        context,
        'Call timed out. On different networks, both phones need internet '
        'and may take longer to connect.',
      );
    });
  }

  void _cancelCallConnectWatchdog() {
    _callConnectWatchdog?.cancel();
    _callConnectWatchdog = null;
  }

  void _bindRemoteRenderer({bool bumpVersion = true}) {
    if (!_renderersInitialized || _remoteCallStream == null) return;
    final stream = _remoteCallStream!;
    for (final track in stream.getVideoTracks()) {
      track.enabled = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_renderersInitialized) return;
      try {
        _remoteRenderer.srcObject = null;
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted || !_renderersInitialized) return;
        _remoteRenderer.srcObject = stream;
        if (bumpVersion) _remoteStreamVersion++;
        setState(() {});
      } catch (e) {
        debugPrint('RoomPage: bind remote renderer failed: $e');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NtpClock.instance.refresh();
    unawaited(_loadNotificationPrefs());
    _driftTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_correctDriftOnce());
    });
  }

  Future<void> _loadNotificationPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _notifyRecentMessages = prefs.getBool('notify_recent_messages') ?? true;
        _notifyRoomInvites = prefs.getBool('notify_room_invites') ?? true;
        _notifySystemAlerts = prefs.getBool('notify_system_alerts') ?? true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancelCallConnectWatchdog();
    _driftTimer?.cancel();
    _playbackSpeedResetTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _videoController?.dispose();
    _remoteStreamSub?.cancel();
    _callConnectionSub?.cancel();
    _incomingCallSub?.cancel();
    _remoteNameSub?.cancel();
    unawaited(_callService?.dispose());
    if (_renderersInitialized) {
      _localRenderer.dispose();
      _remoteRenderer.dispose();
      _renderersInitialized = false;
    }
    super.dispose();
  }

  Future<void> _initializeCallRenderers() async {
    if (_renderersInitialized) return;
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      _remoteRenderer.onResize = () {
        if (mounted) setState(() {});
      };
    } catch (e) {
      _renderersInitialized = false;
      rethrow;
    }
    if (!mounted) return;
    _renderersInitialized = true;
  }

  Future<void> _startOrJoinCall(RoomState state) async {
    if (_isCallConnecting) return;
    _isCallConnecting = true;
    _dismissCallSnackBars();
    if (mounted) {
      setState(() => _callConnectionState = RoomCallConnectionState.connecting);
    }
    _startCallConnectWatchdog();
    try {
      await _initializeCallRenderers();

      if (_callService != null) {
        await _callService!.dispose();
        _callService = null;
      }
      await _remoteStreamSub?.cancel();
      await _callConnectionSub?.cancel();
      _remoteStreamSub = null;
      _callConnectionSub = null;

      _callService = RoomCallService(state.roomId);

      _remoteStreamSub = _callService!.remoteStreamUpdates.listen((stream) {
        if (!mounted) return;
        setState(() {
          _remoteCallStream = stream;
          _bindRemoteRenderer();
          _videoBubbleVisible = true;
        });
      });

      _callConnectionSub =
          _callService!.connectionStateUpdates.listen((callState) {
        if (!mounted) return;
        if (callState == RoomCallConnectionState.connected) {
          _cancelCallConnectWatchdog();
          _bindRemoteRenderer(bumpVersion: true);
          Future<void>.delayed(const Duration(seconds: 1), () {
            if (mounted && _remoteCallStream != null) {
              _bindRemoteRenderer(bumpVersion: true);
            }
          });
          Future<void>.delayed(const Duration(seconds: 3), () {
            if (mounted && _remoteCallStream != null) {
              _bindRemoteRenderer(bumpVersion: true);
            }
          });
        } else if (callState == RoomCallConnectionState.failed &&
            _notifySystemAlerts) {
          _cancelCallConnectWatchdog();
          AppSnackBar.error(
            context,
            'Video call failed to connect. On different Wi‑Fi/mobile networks '
            'both phones need internet — end call and try again.',
          );
        }
        setState(() => _callConnectionState = callState);
      });

      final uid = fb.FirebaseAuth.instance.currentUser?.uid;
      final isRoomHost = uid != null && uid == state.hostId;

      if (isRoomHost) {
        final hostName = fb.FirebaseAuth.instance.currentUser?.displayName ??
            'Room host';
        _primeRemoteParticipantName(state, true);
        await _callService!.startCall(
          clearExisting: true,
          hostId: uid,
          hostName: hostName,
          roomName: state.roomName,
        );
        if (mounted) {
          setState(() {
            _localCallStream = _callService!.localStream;
            if (_renderersInitialized) {
              _localRenderer.srcObject = _localCallStream;
            }
            _videoBubbleVisible = true;
          });
        }
      } else {
        _primeRemoteParticipantName(state, false);
        final ready = await _callService!.waitForHostOffer();
        if (!ready) {
          throw Exception(
            'The room host has not started the video call yet. Ask them to tap the camera icon first.',
          );
        }
        final guestName =
            fb.FirebaseAuth.instance.currentUser?.displayName ?? 'Guest';
        await _callService!.joinCall(
          guestId: uid,
          guestName: guestName,
        );
      }

      if (!mounted) return;
      setState(() {
        _localCallStream = _callService!.localStream;
        _remoteCallStream = _callService!.remoteStream;
        if (_renderersInitialized) {
          _localRenderer.srcObject = _localCallStream;
          _bindRemoteRenderer();
        }
        _videoBubbleVisible = true;
        _callConnectionState = RoomCallConnectionState.connecting;
      });
    } catch (e, st) {
      debugPrint('RoomPage: video call failed: $e\n$st');
      _cancelCallConnectWatchdog();
      await _remoteStreamSub?.cancel();
      await _callConnectionSub?.cancel();
      _remoteStreamSub = null;
      _callConnectionSub = null;
      await _callService?.dispose();
      _callService = null;
      if (mounted) {
        setState(() {
          _localCallStream = null;
          _remoteCallStream = null;
          _videoBubbleVisible = false;
          _callConnectionState = RoomCallConnectionState.idle;
          if (_renderersInitialized) {
            _localRenderer.srcObject = null;
            _remoteRenderer.srcObject = null;
          }
        });
      }
      rethrow;
    } finally {
      _isCallConnecting = false;
    }
  }

  Future<void> _endVideoCall() async {
    _dismissCallSnackBars();
    _cancelCallConnectWatchdog();
    await _callService?.clearCallInvite();
    await _remoteStreamSub?.cancel();
    await _callConnectionSub?.cancel();
    _remoteStreamSub = null;
    _callConnectionSub = null;
    await _remoteNameSub?.cancel();
    _remoteNameSub = null;
    await _callService?.dispose();
    _callService = null;

    if (!mounted) return;
    setState(() {
      _localCallStream = null;
      _remoteCallStream = null;
      _videoBubbleVisible = false;
      _callConnectionState = RoomCallConnectionState.idle;
      _micMuted = false;
      _cameraMuted = false;
      _remoteParticipantName = 'Guest';
      _remoteStreamVersion = 0;
      if (_renderersInitialized) {
        _localRenderer.srcObject = null;
        _remoteRenderer.srcObject = null;
      }
    });
  }

  void _listenForIncomingCall(RoomState state) {
    if (_incomingCallSub != null) return;
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == state.hostId) return;
    if (!state.videoCallEnabled) return;

    _incomingCallSub?.cancel();
    _incomingCallSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('call')
        .doc('invite')
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data();
      final active = data?['active'] == true;
      final generation = data?['generation'] as int? ?? 0;

      if (!_incomingCallPrimed) {
        _incomingCallPrimed = true;
        _lastSeenCallGeneration = generation;
        return;
      }

      if (!active || generation <= _lastSeenCallGeneration) {
        if (!active) {
          _lastSeenCallGeneration = 0;
          _dismissCallSnackBars();
        }
        return;
      }
      if (_localCallStream != null || _isCallConnecting) return;

      _lastSeenCallGeneration = generation;
      _showIncomingCallPrompt(state, data ?? {});
    });
  }

  void _showIncomingCallPrompt(RoomState state, Map<String, dynamic> data) {
    if (!_notifySystemAlerts) return;
    final hostName = data['hostName'] as String? ?? 'The host';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 30),
        content: Text('$hostName started a video call. Join now?'),
        action: SnackBarAction(
          label: 'Join',
          onPressed: () {
            _dismissCallSnackBars();
            unawaited(_toggleCallBubble(state));
          },
        ),
      ),
    );
  }

  void _toggleCallMic() {
    final muted = !_micMuted;
    _callService?.toggleAudioMuted(muted);
    setState(() => _micMuted = muted);
  }

  void _toggleCallCamera() {
    final muted = !_cameraMuted;
    _callService?.toggleVideoMuted(muted);
    setState(() => _cameraMuted = muted);
  }

  Future<void> _toggleCallBubble(RoomState state) async {
    if (!state.videoCallEnabled) {
      if (_notifySystemAlerts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video call is disabled for this room.'),
          ),
        );
      }
      return;
    }
    try {
      if (_localCallStream == null) {
        _dismissCallSnackBars();
        await _startOrJoinCall(state);
        if (!mounted) return;
        final uid = fb.FirebaseAuth.instance.currentUser?.uid;
        final isRoomHost = uid != null && uid == state.hostId;
        if (isRoomHost && _notifySystemAlerts) {
          AppSnackBar.info(
            context,
            'Call started. Friend should tap Join on the banner or camera icon.',
          );
        }
      } else {
        if (!mounted) return;
        setState(() => _videoBubbleVisible = !_videoBubbleVisible);
      }
    } on CallPermissionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 5),
          action: e.permanentlyDenied
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video call failed: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      NtpClock.instance.refresh();
      final s = context.read<RoomBloc>().state;
      unawaited(_applyPlaybackFromFirestore(s, force: true));
    }
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    final roomState = context.read<RoomBloc>().state;
    final moderation = ChatModeration.moderate(
      text,
      enabled: roomState.sensitiveWordsFilterEnabled,
    );

    if (moderation.wasBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            moderation.blockReason ??
                'This message was blocked by chat moderation.',
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    context.read<RoomBloc>().add(RoomMessageSent(text));
    _messageController.clear();
  }

  Future<void> _reportMessage(RoomMessage message) async {
    final reason = await ReportMessageDialog.show(
      context,
      authorName: message.author,
      messagePreview: message.text,
    );
    if (!mounted || reason == null) return;

    context.read<RoomBloc>().add(
      RoomMessageReported(
        messageId: message.id,
        messageText: message.text,
        reportedAuthor: message.author,
        reportedAuthorId: message.authorId,
        reason: reason,
      ),
    );
  }

  Future<double> _currentPositionSeconds(RoomState state) async {
    if (_playbackKind == VideoPlaybackKind.youtube) {
      final yt = _youtubeKey.currentState;
      if (yt != null) return await yt.currentPositionSeconds();
      return 0;
    }
    if (_playbackKind == VideoPlaybackKind.webPage) {
      return await _webPageKey.currentState?.currentPositionSeconds() ?? 0;
    }
    final pos = _videoController?.value.position ?? Duration.zero;
    return pos.inMilliseconds / 1000.0;
  }

  Future<void> _setPlaying(RoomState state, bool playing) async {
    if (_playbackKind == VideoPlaybackKind.youtube) {
      final yt = _youtubeKey.currentState;
      if (yt == null) return;
      if (playing) {
        await yt.play();
      } else {
        await yt.pause();
      }
      return;
    }
    if (_playbackKind == VideoPlaybackKind.webPage) {
      final web = _webPageKey.currentState;
      if (web == null) return;
      if (playing) {
        await web.play();
      } else {
        await web.pause();
      }
      return;
    }

    final vc = _videoController;
    if (vc == null) return;
    if (playing) {
      await vc.play();
    } else {
      await vc.pause();
    }
  }

  double _targetPositionSeconds(RoomState state) {
    return PlaybackSyncMath.expectedPositionSeconds(
      anchorPositionSeconds: state.playbackPositionSeconds,
      isPlaying: state.isPlaying,
      anchorServerTimeMs: state.playbackAnchorServerTimeMs,
      ntpNowMs: NtpClock.instance.nowMs,
    );
  }

  bool _hasRemotePlaybackState(RoomState state) => state.playbackVersion > 0;

  // When [playbackAnchorServerTimeMs] is 0 (e.g. `updatedAt` not resolved yet) or
  // this device's clock (with NTP offset) is **behind** the server anchor,
  // [PlaybackSyncMath.expectedPositionSeconds] stays frozen at
  // [RoomState.playbackPositionSeconds] while the player keeps moving. Drift
  // correction then sees a large gap and seeks backward — on a phone this
  // often looks like the video only plays for ~1 second.
  bool _playbackAnchorCoherentForDrift(RoomState state) {
    final anchor = state.playbackAnchorServerTimeMs;
    if (anchor <= 0) return false;
    return NtpClock.instance.nowMs >= anchor;
  }

  //Apply playback state from Firestore to local player, unless we already applied this version or there's no remote state. On YouTube we only apply if the anchor time is coherent to avoid seeking into the future.
  Future<void> _applyPlaybackFromFirestore(
    RoomState state, {
    bool force = false,
  }) async {
    if (!_hasRemotePlaybackState(state)) {
      return;
    }
    if (!force && state.playbackVersion == _lastPlaybackVersionApplied) {
      return;
    }

    final target = _targetPositionSeconds(state);
    if (target >= 0) {
      await _seekLocalTo(state, target);
    }
    await _setPlaying(state, state.isPlaying);
    if (!mounted) return;
    _lastPlaybackVersionApplied = state.playbackVersion;
  }

  Future<void> _seekLocalTo(RoomState state, double seconds) async {
    if (seconds.isNaN) return;
    final safe = seconds < 0 ? 0.0 : seconds;
    if (_playbackKind == VideoPlaybackKind.youtube) {
      await _youtubeKey.currentState?.seekToSeconds(safe);
    } else if (_playbackKind == VideoPlaybackKind.webPage) {
      await _webPageKey.currentState?.seekToSeconds(safe);
    } else if (_videoController != null &&
        _videoController!.value.isInitialized) {
      await _videoController!.seekTo(
        Duration(milliseconds: (safe * 1000).round()),
      );
    }
  }

  Future<void> _seekRoomBy(RoomState state, double deltaSeconds) async {
    final cur = await _currentPositionSeconds(state);
    final next = cur + deltaSeconds;
    final clamped = next < 0 ? 0.0 : next;
    await _seekLocalTo(state, clamped);
    if (!mounted) return;
    context.read<RoomBloc>().add(
      RoomPlaybackSetRequested(
        isPlaying: state.isPlaying,
        positionSeconds: clamped,
      ),
    );
  }

  Future<void> _seekRoomToStart(RoomState state) async {
    await _seekLocalTo(state, 0);
    if (!mounted) return;
    context.read<RoomBloc>().add(
      RoomPlaybackSetRequested(isPlaying: state.isPlaying, positionSeconds: 0),
    );
  }

  void _schedulePlaybackSpeedReset(VideoPlayerController vc) {
    _playbackSpeedResetTimer?.cancel();
    _playbackSpeedResetTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      vc.setPlaybackSpeed(1.0);
    });
  }

  //Drift correction
  Future<void> _correctDriftOnce() async {
    if (!mounted) return;
    final state = context.read<RoomBloc>().state;
    if (state.status != RoomStatus.viewing) return;
    if (!_hasRemotePlaybackState(state)) {
      return;
    }
    final url = state.videoUrl?.trim() ?? '';
    if (url.isEmpty || _isLikelyLocalPath(url)) return;

    final expected = _targetPositionSeconds(state);
    final local = await _currentPositionSeconds(state);

    if (_playbackKind == VideoPlaybackKind.youtube) {
      final playing = await _youtubeKey.currentState?.isPlaying() ?? false;
      if (state.isPlaying != playing) {
        await _setPlaying(state, state.isPlaying);
      }
      if (!_playbackAnchorCoherentForDrift(state)) {
        return;
      }
      // Previously we sought whenever |drift| > 0.5s every 2s. YouTube's reported
      // position lags real playback, so that caused endless seeks → constant loading.
      // Match file-player "hard seek" threshold only, plus a cooldown after seeks.
      final decision = PlaybackSyncMath.driftDecision(
        expectedSeconds: expected,
        localSeconds: local,
      );
      if (decision.kind != DriftKind.hardSeek) {
        return;
      }
      final now = DateTime.now();
      final last = _lastYoutubeDriftSeekWallClock;
      if (last != null && now.difference(last) < const Duration(seconds: 5)) {
        return;
      }
      _lastYoutubeDriftSeekWallClock = now;
      final to = decision.seekToSeconds ?? expected;
      await _youtubeKey.currentState?.seekToSeconds(to);
      return;
    }

    if (_playbackKind == VideoPlaybackKind.webPage) {
      final playing = await _webPageKey.currentState?.isPlaying() ?? false;
      if (state.isPlaying != playing) {
        await _setPlaying(state, state.isPlaying);
      }
      if (!_playbackAnchorCoherentForDrift(state)) return;
      final decision = PlaybackSyncMath.driftDecision(
        expectedSeconds: expected,
        localSeconds: local,
      );
      if (decision.kind == DriftKind.hardSeek) {
        final to = decision.seekToSeconds ?? expected;
        await _webPageKey.currentState?.syncTo(
          seconds: to,
          playing: state.isPlaying,
        );
      }
      return;
    }

    final vc = _videoController;
    if (vc == null || !vc.value.isInitialized) return;

    if (state.isPlaying != vc.value.isPlaying) {
      await _setPlaying(state, state.isPlaying);
    }

    if (!_playbackAnchorCoherentForDrift(state)) {
      return;
    }

    final decision = PlaybackSyncMath.driftDecision(
      expectedSeconds: expected,
      localSeconds: local,
    );
    switch (decision.kind) {
      case DriftKind.none:
        break;
      case DriftKind.hardSeek:
        final to = decision.seekToSeconds ?? expected;
        await vc.seekTo(Duration(milliseconds: (to * 1000).round()));
        _schedulePlaybackSpeedReset(vc);
        break;
      case DriftKind.softRate:
        if (!state.isPlaying) break;
        final rate = decision.catchUp ? 1.06 : 0.94;
        await vc.setPlaybackSpeed(rate);
        _schedulePlaybackSpeedReset(vc);
        break;
    }
  }

  Future<void> _inviteFriends(BuildContext context) async {
    final roomName =
        context.read<RoomBloc>().state.roomName ?? 'Coview watch room';
    final roomId = widget.roomId;
    final pathLink = '/join/$roomId';
    final resolved = buildShareableInviteLink(
      inviteLink: pathLink,
      roomId: roomId,
    );

    final isFullUrl = resolved.startsWith('http');
    final body = isFullUrl
        ? 'You\'re invited to watch together: "$roomName"\n\n$resolved\n\nOpen the link to join this room in Coview.'
        : 'You\'re invited to watch together: "$roomName"\n\nRoom code: $resolved\n\nIn Coview, open Join Room and paste this code (or any invite link).';

    if (!context.mounted) return;
    await showRoomShareSheet(
      context,
      roomName: roomName,
      shareBody: body,
      resolvedLink: resolved,
      isFullUrl: isFullUrl,
    );
    if (!context.mounted) return;
    if (_notifyRoomInvites) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invite options opened.')));
    }
  }

  Future<void> _handleRoomBack(BuildContext context) async {
    if (_manualVideoOnly) {
      setState(() => _manualVideoOnly = false);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return;
    }
    final videoUrl = context.read<RoomBloc>().state.videoUrl ?? '';
    if (_isYouTubeUrl(videoUrl)) {
      final yt = _youtubeKey.currentState;
      if (yt != null && yt.isYoutubeFullscreen) {
        await yt.exitYoutubeFullscreen();
        return;
      }
    }
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _togglePlayback(RoomState state) async {
    final currentlyPlaying = switch (_playbackKind) {
      VideoPlaybackKind.youtube =>
        await _youtubeKey.currentState?.isPlaying() ?? false,
      VideoPlaybackKind.webPage =>
        await _webPageKey.currentState?.isPlaying() ?? false,
      _ => _videoController?.value.isPlaying ?? false,
    };
    final target = !currentlyPlaying;

    await _setPlaying(state, target);
    final positionSeconds = await _currentPositionSeconds(state);
    if (!mounted) return;
    context.read<RoomBloc>().add(
      RoomPlaybackSetRequested(
        isPlaying: target,
        positionSeconds: positionSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final videoOnly = _videoOnlyLayout;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.primaryDark
          : AppColors.backgroundWhite,
      appBar: videoOnly
          ? null
          : AppBar(
              backgroundColor: isDark
                  ? AppColors.primaryDarkVariant
                  : AppColors.backgroundWhite,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => unawaited(_handleRoomBack(context)),
              ),
              title: BlocBuilder<RoomBloc, RoomState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.roomName ?? 'Coview Room',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '#${widget.roomId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                BlocBuilder<RoomBloc, RoomState>(
                  buildWhen: (p, c) => p.hostId != c.hostId,
                  builder: (context, state) {
                    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
                    final isHost = uid != null && state.hostId == uid;
                    if (!isHost) return const SizedBox.shrink();
                    return IconButton(
                      tooltip: 'Delete room',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Room?'),
                            content: const Text(
                              'This will remove the room and delete uploaded video file from storage.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        context.read<RoomBloc>().add(
                          const RoomDeleteRequested(),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Invite friends',
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => unawaited(_inviteFriends(context)),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: Stack(
        children: [
          Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF1A0B2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ]
                : const [Color(0xFFE6E9FF), Color(0xFFF5F7FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: videoOnly
                ? EdgeInsets.zero
                : const EdgeInsets.all(AppConstants.spacingMedium),
            child: BlocListener<RoomBloc, RoomState>(
              listenWhen: (p, c) =>
                  c.status != p.status ||
                  c.videoUrl != p.videoUrl ||
                  c.actionMessage != p.actionMessage ||
                  c.roomDeleted != p.roomDeleted ||
                  c.playbackVersion != p.playbackVersion ||
                  c.isPlaying != p.isPlaying ||
                  c.playbackPositionSeconds != p.playbackPositionSeconds ||
                  c.playbackAnchorServerTimeMs != p.playbackAnchorServerTimeMs,
              listener: (context, state) {
                if (state.actionMessage != null &&
                    state.actionMessage!.trim().isNotEmpty) {
                  final isModeration = state.actionMessage!.contains('filtered') ||
                      state.actionMessage!.contains('blocked') ||
                      state.actionMessage!.contains('Report');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.actionMessage!),
                      backgroundColor: isModeration
                          ? Colors.orange.shade800
                          : null,
                      duration: Duration(seconds: isModeration ? 4 : 3),
                    ),
                  );
                  context.read<RoomBloc>().add(
                    const RoomActionMessageConsumed(),
                  );
                }
                if (state.roomDeleted) {
                  context.go('/home');
                  return;
                }
                if (state.messages.length > _lastKnownMessageCount &&
                    _notifyRecentMessages &&
                    state.messages.isNotEmpty) {
                  final latest = state.messages.last;
                  final myUid = fb.FirebaseAuth.instance.currentUser?.uid;
                  final isMyMessage = myUid != null && myUid == latest.authorId;
                  if (!isMyMessage) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${latest.author}: ${latest.text}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
                _lastKnownMessageCount = state.messages.length;
                final cameFromLoading =
                    _listenerPrevStatus == RoomStatus.loading &&
                    state.status == RoomStatus.viewing;
                _listenerPrevStatus = state.status;
                if (state.status != RoomStatus.viewing) return;
                if (cameFromLoading) {
                  _listenForIncomingCall(state);
                }
                unawaited(_preparePlaybackSource(state.videoUrl));
                final force = cameFromLoading;
                unawaited(_applyPlaybackFromFirestore(state, force: force));
              },
              child: BlocBuilder<RoomBloc, RoomState>(
                builder: (context, state) {
                  if (state.status == RoomStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == RoomStatus.error) {
                    return Center(
                      child: Text(
                        state.error ?? 'Failed to load room.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (_videoOnlyLayout) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _buildVideoPane(
                              theme,
                              isDark,
                              state,
                              immersive: true,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          right: 4,
                          child: SafeArea(
                            bottom: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  tooltip: 'Exit fullscreen',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  onPressed: () =>
                                      unawaited(_handleRoomBack(context)),
                                  icon: const Icon(
                                    Icons.fullscreen_exit,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Invite friends',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  onPressed: () =>
                                      unawaited(_inviteFriends(context)),
                                  icon: const Icon(
                                    Icons.ios_share,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final content = isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildVideoPane(theme, isDark, state),
                            ),
                            const SizedBox(width: AppConstants.spacingMedium),
                            Expanded(
                              flex: 2,
                              child: _buildChatPane(
                                theme,
                                isDark,
                                textChatEnabled: state.textChatEnabled,
                                compactInput: false,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildVideoPane(theme, isDark, state),
                            ),
                            const SizedBox(height: AppConstants.spacingMedium),
                            Expanded(
                              flex: 3,
                              child: _buildChatPane(
                                theme,
                                isDark,
                                textChatEnabled: state.textChatEnabled,
                                compactInput:
                                    MediaQuery.orientationOf(context) ==
                                        Orientation.landscape &&
                                    MediaQuery.sizeOf(context).height < 520,
                              ),
                            ),
                          ],
                        );

                  return Stack(
                    children: [
                      content,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }

  Future<void> _preparePlaybackSource(String? url) async {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      _resetPlayback();
      if (mounted) setState(() {});
      return;
    }
    if (_preparedSourceUrl == trimmed) return;
    _preparedSourceUrl = trimmed;

    final kind = VideoUrlClassifier.classify(trimmed);
    switch (kind) {
      case VideoPlaybackKind.youtube:
        _playbackKind = kind;
        _disposeDirectPlayer();
        if (mounted) setState(() => _resolvingPlayback = false);
        return;
      case VideoPlaybackKind.localFile:
        _playbackKind = kind;
        _setupDirectPlayer(trimmed, isLocal: true);
        if (mounted) setState(() => _resolvingPlayback = false);
        return;
      case VideoPlaybackKind.directStream:
        _playbackKind = kind;
        _setupDirectPlayer(trimmed);
        if (mounted) setState(() => _resolvingPlayback = false);
        return;
      case VideoPlaybackKind.webPage:
        if (mounted) setState(() => _resolvingPlayback = true);
        _disposeDirectPlayer();
        final result = await _webVideoResolver.resolve(trimmed);
        if (!mounted || _preparedSourceUrl != trimmed) return;
        if (result.hasDirectStream) {
          _playbackKind = VideoPlaybackKind.directStream;
          _setupDirectPlayer(result.directStreamUrl!);
        } else {
          _playbackKind = VideoPlaybackKind.webPage;
        }
        if (mounted) setState(() => _resolvingPlayback = false);
        return;
      case VideoPlaybackKind.unsupported:
        _playbackKind = kind;
        _disposeDirectPlayer();
        if (mounted) setState(() => _resolvingPlayback = false);
    }
  }

  void _setupDirectPlayer(String url, {bool isLocal = false}) {
    if (_currentVideoUrl == url && _videoController != null) return;

    _videoController?.dispose();
    if (isLocal) {
      _videoController = VideoPlayerController.file(File(url));
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    }
    _currentVideoUrl = url;
    _initializeVideoFuture = _videoController!.initialize().then((_) async {
      if (!mounted) return;
      setState(() {});
      final s = context.read<RoomBloc>().state;
      if (_hasRemotePlaybackState(s)) {
        await _applyPlaybackFromFirestore(s, force: true);
      }
    });
  }

  void _disposeDirectPlayer() {
    _videoController?.dispose();
    _videoController = null;
    _initializeVideoFuture = null;
    _currentVideoUrl = null;
  }

  void _resetPlayback() {
    _preparedSourceUrl = null;
    _playbackKind = VideoPlaybackKind.unsupported;
    _resolvingPlayback = false;
    _disposeDirectPlayer();
  }

  Widget _buildVideoPane(
    ThemeData theme,
    bool isDark,
    RoomState state, {
    bool immersive = false,
  }) {
    final videoUrl = state.videoUrl?.trim() ?? '';
    final isLikelyLocalSource =
        videoUrl.isNotEmpty && _isLikelyLocalPath(videoUrl);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDarkVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(
          immersive ? 0 : AppConstants.borderRadiusLarge,
        ),
        boxShadow: immersive
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                immersive ? 0 : AppConstants.borderRadiusLarge,
              ),
              child: state.videoUrl == null || state.videoUrl!.isEmpty
                  ? Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00D9FF)],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              size: 72,
                              color: AppColors.textWhite.withValues(
                                alpha: 0.95,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No video URL configured for this room.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : isLikelyLocalSource
                  ? Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00D9FF)],
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.link_off,
                                size: 56,
                                color: AppColors.textWhite,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                kIsWeb
                                    ? 'This room uses a local file path. Web cannot access files from another device.'
                                    : 'This room uses a host local file path. Your device cannot access it.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Ask the host to recreate the room with a public HTTP(S) video URL.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textWhite.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _resolvingPlayback
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textWhite,
                        ),
                      ),
                    )
                  : _playbackKind == VideoPlaybackKind.youtube
                  ? YoutubePlayerView(
                      key: _youtubeKey,
                      videoUrl: state.videoUrl!,
                      immersiveLayout: immersive,
                      onFullscreenChanged: kIsWeb
                          ? null
                          : (expanded) {
                              if (!mounted) return;
                              setState(() => _youtubeImmersive = expanded);
                            },
                    )
                  : _playbackKind == VideoPlaybackKind.webPage
                  ? WebPagePlayerView(
                      key: _webPageKey,
                      pageUrl: state.videoUrl!,
                      immersiveLayout: immersive,
                      onVideoReady: () {
                        if (!mounted) return;
                        final s = context.read<RoomBloc>().state;
                        unawaited(_applyPlaybackFromFirestore(s, force: true));
                      },
                    )
                  : Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00D9FF)],
                        ),
                      ),
                      child: Center(
                        child:
                            (_videoController != null &&
                                _initializeVideoFuture != null)
                            ? FutureBuilder<void>(
                                future: _initializeVideoFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textWhite,
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Could not play this video stream.',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    );
                                  }
                                  return Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      AspectRatio(
                                        aspectRatio:
                                            _videoController!.value.aspectRatio,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                      IconButton(
                                        iconSize: 40,
                                        color: AppColors.textWhite,
                                        icon: Icon(
                                          _videoController!.value.isPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_fill,
                                        ),
                                        onPressed: () {
                                          final rs = context
                                              .read<RoomBloc>()
                                              .state;
                                          unawaited(_togglePlayback(rs));
                                        },
                                      ),
                                    ],
                                  );
                                },
                              )
                            : const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Preparing video…',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    ),
            ),
          ),
          if (!immersive) ...[
            const SizedBox(height: AppConstants.spacingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSmall,
                vertical: AppConstants.spacingSmall,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_playbackKind != VideoPlaybackKind.youtube)
                      IconButton(
                        tooltip: 'Fullscreen video',
                        onPressed: () =>
                            setState(() => _manualVideoOnly = true),
                        icon: const Icon(Icons.fullscreen),
                      ),
                    IconButton(
                      onPressed: () => unawaited(_seekRoomBy(state, -10)),
                      icon: const Icon(Icons.replay_10),
                    ),
                    IconButton(
                      onPressed: () => unawaited(_seekRoomToStart(state)),
                      icon: const Icon(Icons.skip_previous),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _togglePlayback(state),
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => unawaited(_seekRoomBy(state, 30)),
                      icon: const Icon(Icons.skip_next),
                    ),
                    IconButton(
                      onPressed: () => unawaited(_seekRoomBy(state, 10)),
                      icon: const Icon(Icons.forward_10),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: _isCallConnecting
                          ? 'Connecting call…'
                          : (_localCallStream != null
                              ? (_videoBubbleVisible
                                  ? 'Hide call bubbles'
                                  : 'Show call bubbles')
                              : 'Start video call'),
                      onPressed: _isCallConnecting
                          ? null
                          : () => unawaited(_toggleCallBubble(state)),
                      icon: _isCallConnecting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _videoBubbleVisible
                                  ? Icons.videocam
                                  : Icons.videocam_outlined,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            if (_localCallStream != null &&
                _videoBubbleVisible &&
                _renderersInitialized)
              RoomCallLocalStrip(
                renderer: _localRenderer,
                renderersReady: _renderersInitialized,
                micMuted: _micMuted,
                cameraMuted: _cameraMuted,
                onToggleMic: _toggleCallMic,
                onToggleCamera: _toggleCallCamera,
                onSwitchCamera: () => unawaited(_callService?.switchCamera()),
                onEndCall: () => unawaited(_endVideoCall()),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatPane(
    ThemeData theme,
    bool isDark, {
    required bool textChatEnabled,
    bool compactInput = false,
  }) {
    final headerPadding = compactInput
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.all(AppConstants.spacingMedium);
    final listPadding = compactInput
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
        : const EdgeInsets.all(AppConstants.spacingMedium);

    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, roomState) {
        final uid = fb.FirebaseAuth.instance.currentUser?.uid;
        final isRoomHost = uid != null && uid == roomState.hostId;
        final callBubblesActive = _localCallStream != null &&
            _videoBubbleVisible &&
            _renderersInitialized;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryDarkVariant : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: headerPadding,
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Room Chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (roomState.sensitiveWordsFilterEnabled) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message:
                            'Chat moderation is on. Harmful words are filtered or blocked.',
                        child: Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusSmall,
                          ),
                        ),
                        child: Text(
                          'Live',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<RoomBloc, RoomState>(
                  builder: (context, state) {
                    final messages = state.messages;
                    final maxBubbleW = MediaQuery.sizeOf(context).width * 0.85;
                    final myUid = fb.FirebaseAuth.instance.currentUser?.uid;
                    return ListView.builder(
                      padding: listPadding,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe =
                            myUid != null && myUid == message.authorId;
                        return ChatMessageBubble(
                          message: message,
                          isMe: isMe,
                          maxWidth: maxBubbleW,
                          onReport: isMe ? null : _reportMessage,
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingSmall),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: textChatEnabled,
                        minLines: 1,
                        maxLines: compactInput ? 1 : 3,
                        decoration: InputDecoration(
                          hintText: textChatEnabled
                              ? 'Say something to the room...'
                              : 'Chat disabled by host',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingMedium,
                            vertical: AppConstants.spacingSmall,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSmall),
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.textWhite,
                        ),
                        onPressed: textChatEnabled ? _sendMessage : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
            if (callBubblesActive)
              Positioned(
                top: _remoteBubbleOffset.dy,
                right: _remoteBubbleOffset.dx,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!mounted) return;
                    setState(() {
                      _remoteBubbleOffset = Offset(
                        (_remoteBubbleOffset.dx - details.delta.dx).clamp(
                          8,
                          200,
                        ),
                        (_remoteBubbleOffset.dy + details.delta.dy).clamp(
                          8,
                          280,
                        ),
                      );
                    });
                  },
                  child: RoomCallRemoteBubble(
                    renderer: _remoteRenderer,
                    renderersReady: _renderersInitialized,
                    hasRemoteStream: _remoteCallStream != null,
                    hasRemoteVideo: _hasRemoteVideo,
                    connectionState: _callConnectionState,
                    isRoomHost: isRoomHost,
                    remoteParticipantName: _remoteParticipantName.isNotEmpty
                        ? _remoteParticipantName
                        : _fallbackRemoteName(roomState, isRoomHost),
                    remoteStreamVersion: _remoteStreamVersion,
                    onClose: () => unawaited(_endVideoCall()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _isYouTubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  bool _isLikelyLocalPath(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return true;
    if (uri.scheme == 'file') return true;
    if (RegExp(r'^[a-zA-Z]:\\').hasMatch(url)) return true;
    if (!uri.hasScheme) return true;
    return false;
  }
}
