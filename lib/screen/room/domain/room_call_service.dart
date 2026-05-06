import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class RoomCallService {
  RoomCallService(this.roomId);

  final String roomId;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final _firestore = FirebaseFirestore.instance;
  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candidatesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _answerSub;
  final Set<String> _appliedCandidateDocIds = <String>{};
  final List<RTCIceCandidate> _pendingRemoteCandidates = <RTCIceCandidate>[];
  bool _remoteDescriptionApplied = false;
  bool _disposed = false;

  Future<void> startCall() async {
    if (_disposed) return;
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection ??= await createPeerConnection(config);
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream!);
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    if (_localStream != null) {
      await _peerConnection!.addStream(_localStream!);
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_disposed) return;
      if ((candidate.candidate ?? '').trim().isEmpty) return;
      if ((candidate.sdpMid ?? '').isEmpty) return;
      if (candidate.sdpMLineIndex == null || candidate.sdpMLineIndex! < 0) {
        return;
      }
      _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('call')
          .doc('host')
          .collection('candidates')
          .add(candidate.toMap());
    };

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host')
        .set({
          'sdp': offer.sdp,
          'type': offer.type,
          'createdAt': FieldValue.serverTimestamp(),
        });

    _answerSub?.cancel();
    _answerSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('guest')
        .snapshots()
        .listen((doc) async {
          if (_disposed) return;
          if (!doc.exists) return;
          final data = doc.data();
          if (data == null) return;
          if (_remoteDescriptionApplied) return;
          final sdp = data['sdp'] as String?;
          final type = data['type'] as String?;
          if ((sdp ?? '').isEmpty || (type ?? '').isEmpty) return;
          final answer = RTCSessionDescription(
            sdp,
            type,
          );
          await _peerConnection?.setRemoteDescription(answer);
          _remoteDescriptionApplied = true;
          await _flushPendingRemoteCandidates();
        });

    _candidatesSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('guest')
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

  Future<void> joinCall() async {
    if (_disposed) return;
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection ??= await createPeerConnection(config);
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream!);
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    if (_localStream != null) {
      await _peerConnection!.addStream(_localStream!);
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_disposed) return;
      if ((candidate.candidate ?? '').trim().isEmpty) return;
      if ((candidate.sdpMid ?? '').isEmpty) return;
      if (candidate.sdpMLineIndex == null || candidate.sdpMLineIndex! < 0) {
        return;
      }
      _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('call')
          .doc('guest')
          .collection('candidates')
          .add(candidate.toMap());
    };

    final hostDoc = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host')
        .get();
    if (!hostDoc.exists) return;
    final hostData = hostDoc.data();
    if (hostData == null) return;
    final hostSdp = hostData['sdp'] as String?;
    final hostType = hostData['type'] as String?;
    if ((hostSdp ?? '').isEmpty || (hostType ?? '').isEmpty) return;

    final offer = RTCSessionDescription(
      hostSdp,
      hostType,
    );
    await _peerConnection?.setRemoteDescription(offer);
    _remoteDescriptionApplied = true;

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection?.setLocalDescription(answer);

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('guest')
        .set({
          'sdp': answer.sdp,
          'type': answer.type,
          'createdAt': FieldValue.serverTimestamp(),
        });

    _candidatesSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host')
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

  Future<void> _handleRemoteCandidateMap(Map<String, dynamic> data) async {
    if (_disposed) return;
    final candidateStr = data['candidate'] as String?;
    if ((candidateStr ?? '').trim().isEmpty) return;

    final sdpMid = data['sdpMid'] as String?;
    if ((sdpMid ?? '').isEmpty) return;
    final rawIndex = data['sdpMLineIndex'];
    int? sdpMLineIndex;
    if (rawIndex is int) {
      sdpMLineIndex = rawIndex;
    } else if (rawIndex is num) {
      sdpMLineIndex = rawIndex.toInt();
    }
    if (sdpMLineIndex == null || sdpMLineIndex < 0) return;

    final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpMLineIndex);
    if (!_remoteDescriptionApplied) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    try {
      await _peerConnection?.addCandidate(candidate);
    } catch (_) {
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
      } catch (_) {
        // Keep flow alive even if a stale candidate fails.
      }
    }
  }

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  Stream<MediaStream> get remoteStreamUpdates => _remoteStreamController.stream;

  Future<bool> hostOfferExists() async {
    final hostDoc = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('host')
        .get();
    return hostDoc.exists;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _candidatesSub?.cancel();
    await _answerSub?.cancel();
    _appliedCandidateDocIds.clear();
    _pendingRemoteCandidates.clear();
    _remoteDescriptionApplied = false;
    await _remoteStream?.dispose();
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    await _remoteStreamController.close();
  }
}
