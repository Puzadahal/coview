import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/permissions/call_permissions.dart';
import '../../../core/permissions/call_audio_session.dart';

enum RoomCallRole { host, guest }

enum RoomCallConnectionState {
  idle,
  connecting,
  connected,
  failed,
  disconnected,
}

class RoomCallService {
  RoomCallService(this.roomId);

  final String roomId;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final _firestore = FirebaseFirestore.instance;
  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _connectionStateController =
      StreamController<RoomCallConnectionState>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candidatesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _answerSub;
  final Set<String> _appliedCandidateDocIds = <String>{};
  final List<RTCIceCandidate> _pendingRemoteCandidates = <RTCIceCandidate>[];
  bool _remoteDescriptionApplied = false;
  bool _disposed = false;
  RoomCallRole? _role;
  int _callGeneration = 0;
  Timer? _trackSyncTimer;

  static final _peerConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'iceTransportPolicy': 'all',
  };

  static const _offerAnswerConstraints = {
    'offerToReceiveAudio': true,
    'offerToReceiveVideo': true,
    'voiceActivityDetection': true,
  };

  Stream<MediaStream> get remoteStreamUpdates => _remoteStreamController.stream;
  Stream<RoomCallConnectionState> get connectionStateUpdates =>
      _connectionStateController.stream;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RoomCallRole? get role => _role;

  Future<void> startCall({
    bool clearExisting = true,
    String? hostId,
    String? hostName,
    String? roomName,
  }) async {
    if (_disposed) return;
    _role = RoomCallRole.host;
    _emitConnectionState(RoomCallConnectionState.connecting);

    if (clearExisting) {
      await _clearCallSignaling(clearAll: true);
    }

    await _resetPeerConnection();
    await _attachLocalMedia();
    await CallAudioSession.activate();
    _callGeneration = DateTime.now().millisecondsSinceEpoch;
    await _publishHostOffer(hostId: hostId, hostName: hostName);
    await _publishCallInvite(
      hostId: hostId,
      hostName: hostName,
      roomName: roomName,
    );
    _listenForGuestAnswer();
    _listenForGuestCandidates();
  }

  Future<bool> waitForHostOffer({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final hostRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host');

    final existing = await hostRef.get();
    if (_hasValidSessionDescription(existing.data())) return true;

    final completer = Completer<bool>();
    late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> sub;
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    sub = hostRef.snapshots().listen((doc) {
      if (_hasValidSessionDescription(doc.data())) {
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    final ready = await completer.future;
    await sub.cancel();
    timer.cancel();
    return ready;
  }

  Future<void> joinCall({
    String? guestId,
    String? guestName,
  }) async {
    if (_disposed) return;
    _role = RoomCallRole.guest;
    _emitConnectionState(RoomCallConnectionState.connecting);

    await _resetPeerConnection();
    await _attachLocalMedia();
    await CallAudioSession.activate();

    final hostDoc = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host')
        .get();
    if (!_hasValidSessionDescription(hostDoc.data())) {
      throw Exception('Host video call is not ready yet.');
    }

    final hostData = hostDoc.data()!;
    _callGeneration = hostData['generation'] as int? ?? 0;
    final offer = RTCSessionDescription(
      hostData['sdp'] as String,
      hostData['type'] as String,
    );

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _publishCandidate('guest', candidate);
    };

    _listenForHostCandidates();

    await _peerConnection!.setRemoteDescription(offer);
    _remoteDescriptionApplied = true;
    await _applyExistingCandidates('host');

    final answer = await _peerConnection!.createAnswer(_offerAnswerConstraints);
    await _peerConnection!.setLocalDescription(answer);

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('guest')
        .set({
          'sdp': answer.sdp,
          'type': answer.type,
          'generation': _callGeneration,
          'participantId': guestId ?? '',
          'participantName': guestName ?? 'Guest',
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _flushPendingRemoteCandidates();
    await _syncRemoteTracksFromReceivers();
    _startTrackSyncTimer();
  }

  Future<bool> hostOfferExists() async {
    final hostDoc = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host')
        .get();
    return _hasValidSessionDescription(hostDoc.data());
  }

  Future<void> _resetPeerConnection() async {
    _trackSyncTimer?.cancel();
    _trackSyncTimer = null;
    await _candidatesSub?.cancel();
    await _answerSub?.cancel();
    _candidatesSub = null;
    _answerSub = null;
    _appliedCandidateDocIds.clear();
    _pendingRemoteCandidates.clear();
    _remoteDescriptionApplied = false;

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;

    for (final track in _remoteStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _remoteStream?.dispose();
    _remoteStream = null;

    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }

    _peerConnection = await createPeerConnection(_peerConfig);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      unawaited(_handleRemoteTrack(event));
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      unawaited(_handleRemoteStream(stream));
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('RoomCallService: connectionState=$state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _emitConnectionState(RoomCallConnectionState.connected);
          unawaited(_syncRemoteTracksFromReceivers());
          _startTrackSyncTimer();
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _emitConnectionState(RoomCallConnectionState.failed);
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _emitConnectionState(RoomCallConnectionState.disconnected);
        default:
          break;
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('RoomCallService: iceConnectionState=$state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _emitConnectionState(RoomCallConnectionState.connected);
        unawaited(_syncRemoteTracksFromReceivers());
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _emitConnectionState(RoomCallConnectionState.failed);
      }
    };
  }

  Future<void> _handleRemoteTrack(RTCTrackEvent event) async {
    if (_disposed) return;

    final track = event.track;
    track.enabled = true;

    MediaStream stream;
    if (event.streams.isNotEmpty) {
      stream = event.streams.first;
    } else {
      _remoteStream ??= await createLocalMediaStream('remote');
      final alreadyAdded = _remoteStream!
          .getTracks()
          .any((existing) => existing.id == track.id);
      if (!alreadyAdded) {
        await _remoteStream!.addTrack(track);
      }
      stream = _remoteStream!;
    }

    for (final t in stream.getTracks()) {
      t.enabled = true;
    }

    await _handleRemoteStream(stream);
    unawaited(_syncRemoteTracksFromReceivers());
  }

  Future<void> _syncRemoteTracksFromReceivers() async {
    if (_disposed || _peerConnection == null) return;

    try {
      final receivers = await _peerConnection!.getReceivers();
      MediaStream? stream = _remoteStream;
      var changed = false;

      for (final receiver in receivers) {
        final track = receiver.track;
        if (track == null) continue;
        track.enabled = true;
        stream ??= await createLocalMediaStream('remote');
        if (!stream.getTracks().any((existing) => existing.id == track.id)) {
          await stream.addTrack(track);
          changed = true;
        }
      }

      if (stream != null) {
        for (final track in stream.getTracks()) {
          track.enabled = true;
        }
        if (changed || _remoteStream == null) {
          await _handleRemoteStream(stream);
        }
      }
    } catch (e) {
      debugPrint('RoomCallService: sync receivers failed: $e');
    }
  }

  Future<void> _handleRemoteStream(MediaStream? stream) async {
    if (_disposed || stream == null) return;
    for (final track in stream.getTracks()) {
      track.enabled = true;
    }
    _remoteStream = stream;
    if (!_remoteStreamController.isClosed) {
      _remoteStreamController.add(stream);
    }
    _emitConnectionState(RoomCallConnectionState.connected);
  }

  void _startTrackSyncTimer() {
    if (_disposed) return;
    _trackSyncTimer?.cancel();
    _trackSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_syncRemoteTracksFromReceivers());
    });
  }

  Future<void> _attachLocalMedia() async {
    if (_localStream != null) return;

    await CallPermissions.ensureCameraAndMicrophone();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
      });
    } catch (e, st) {
      debugPrint('RoomCallService: getUserMedia failed: $e\n$st');
      throw Exception('Could not open camera/microphone. ($e)');
    }

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }
  }

  Future<void> _publishHostOffer({
    String? hostId,
    String? hostName,
  }) async {
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _publishCandidate('host', candidate);
    };

    final offer = await _peerConnection!.createOffer(_offerAnswerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host')
        .set({
          'sdp': offer.sdp,
          'type': offer.type,
          'generation': _callGeneration,
          'participantId': hostId ?? '',
          'participantName': hostName ?? 'Host',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _publishCallInvite({
    String? hostId,
    String? hostName,
    String? roomName,
  }) async {
    if (_disposed) return;
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('invite')
        .set({
          'active': true,
          'generation': _callGeneration,
          'hostId': hostId ?? '',
          'hostName': hostName ?? 'Room host',
          'roomName': roomName ?? 'Watch room',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _clearCallInvite() async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('call')
          .doc('invite')
          .set({'active': false}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('RoomCallService: clear invite failed: $e');
    }
  }

  void _listenForGuestAnswer() {
    _answerSub?.cancel();
    _answerSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('guest')
        .snapshots()
        .listen((doc) async {
          if (_disposed || _role != RoomCallRole.host) return;
          if (!_hasValidSessionDescription(doc.data())) return;
          if (_remoteDescriptionApplied) return;

          final data = doc.data()!;
          final guestGeneration = data['generation'] as int? ?? 0;
          if (data.containsKey('generation') &&
              _callGeneration > 0 &&
              guestGeneration != _callGeneration) {
            return;
          }

          final answer = RTCSessionDescription(
            data['sdp'] as String,
            data['type'] as String,
          );
          try {
            await _peerConnection!.setRemoteDescription(answer);
            _remoteDescriptionApplied = true;
            await _applyExistingCandidates('guest');
            await _flushPendingRemoteCandidates();
            await _syncRemoteTracksFromReceivers();
            _startTrackSyncTimer();
          } catch (e, st) {
            debugPrint('RoomCallService: apply guest answer failed: $e\n$st');
          }
        });
  }

  void _listenForGuestCandidates() {
    _listenForCandidates('guest');
  }

  void _listenForHostCandidates() {
    _listenForCandidates('host');
  }

  void _listenForCandidates(String peerDoc) {
    _candidatesSub?.cancel();
    _candidatesSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc(peerDoc)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) async {
          if (_disposed) return;
          for (final doc in snapshot.docs) {
            if (!_appliedCandidateDocIds.add(doc.id)) continue;
            await _handleRemoteCandidateMap(doc.data());
          }
        });
  }

  Future<void> _applyExistingCandidates(String peerDoc) async {
    final snap = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc(peerDoc)
        .collection('candidates')
        .get();
    for (final doc in snap.docs) {
      if (!_appliedCandidateDocIds.add(doc.id)) continue;
      await _handleRemoteCandidateMap(doc.data());
    }
  }

  void _publishCandidate(String peerDoc, RTCIceCandidate candidate) {
    if (_disposed) return;
    final candidateStr = candidate.candidate?.trim() ?? '';
    if (candidateStr.isEmpty) return;

    _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc(peerDoc)
        .collection('candidates')
        .add({
          'candidate': candidateStr,
          'sdpMid': candidate.sdpMid ?? '',
          'sdpMLineIndex': candidate.sdpMLineIndex ?? 0,
        });
  }

  Future<void> _handleRemoteCandidateMap(Map<String, dynamic> data) async {
    if (_disposed) return;
    final candidateStr = data['candidate'] as String?;
    if ((candidateStr ?? '').trim().isEmpty) return;

    final sdpMid = data['sdpMid'] as String?;
    final rawIndex = data['sdpMLineIndex'];
    int sdpMLineIndex = 0;
    if (rawIndex is int) {
      sdpMLineIndex = rawIndex;
    } else if (rawIndex is num) {
      sdpMLineIndex = rawIndex.toInt();
    }

    final candidate = RTCIceCandidate(
      candidateStr,
      (sdpMid == null || sdpMid.isEmpty) ? null : sdpMid,
      sdpMLineIndex,
    );

    if (!_remoteDescriptionApplied) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    try {
      await _peerConnection?.addCandidate(candidate);
    } catch (e) {
      debugPrint('RoomCallService: addCandidate failed: $e');
      _pendingRemoteCandidates.add(candidate);
    }
  }

  Future<void> _flushPendingRemoteCandidates() async {
    if (_disposed) return;
    if (!_remoteDescriptionApplied || _pendingRemoteCandidates.isEmpty) return;
    final pending = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();
    for (final c in pending) {
      try {
        await _peerConnection?.addCandidate(c);
      } catch (e) {
        debugPrint('RoomCallService: flush candidate failed: $e');
      }
    }
  }

  bool _hasValidSessionDescription(Map<String, dynamic>? data) {
    if (data == null) return false;
    final sdp = data['sdp'] as String?;
    final type = data['type'] as String?;
    return (sdp ?? '').isNotEmpty && (type ?? '').isNotEmpty;
  }

  void toggleAudioMuted(bool muted) {
    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  void toggleVideoMuted(bool muted) {
    for (final track in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack == null) return;
    await Helper.switchCamera(videoTrack);
  }

  Future<void> _clearCallSignaling({required bool clearAll}) async {
    final callRef = _firestore.collection('rooms').doc(roomId).collection('call');
    await _deleteCandidates(callRef.doc('host'));
    await _deleteCandidates(callRef.doc('guest'));
    await callRef.doc('guest').delete();
    await _clearCallInvite();
    if (clearAll) {
      await callRef.doc('host').delete();
    }
  }

  Future<void> _deleteCandidates(
    DocumentReference<Map<String, dynamic>> peerRef,
  ) async {
    while (true) {
      final snap = await peerRef.collection('candidates').limit(40).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  void _emitConnectionState(RoomCallConnectionState state) {
    if (_connectionStateController.isClosed) return;
    _connectionStateController.add(state);
  }

  Future<void> dispose() async {
    _disposed = true;
    _trackSyncTimer?.cancel();
    _trackSyncTimer = null;
    await _clearCallInvite();
    await CallAudioSession.deactivate();
    await _candidatesSub?.cancel();
    await _answerSub?.cancel();
    _appliedCandidateDocIds.clear();
    _pendingRemoteCandidates.clear();
    _remoteDescriptionApplied = false;

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    for (final track in _remoteStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }

    await _remoteStream?.dispose();
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _role = null;

    if (!_remoteStreamController.isClosed) {
      await _remoteStreamController.close();
    }
    if (!_connectionStateController.isClosed) {
      await _connectionStateController.close();
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
