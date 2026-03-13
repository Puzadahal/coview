import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class RoomCallService {
  RoomCallService(this.roomId);

  final String roomId;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candidatesSub;

  Future<void> startCall() async {
    // Basic STUN only; for production you should add TURN.
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection ??= await createPeerConnection(config);

    // Get local media (audio + video)
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localStream?.getTracks().forEach(_peerConnection!.addTrack);

    // Handle ICE candidates from this peer
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('call')
          .doc('host')
          .collection('candidates')
          .add(candidate.toMap());
    };

    // Create and store the offer
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

    // Listen for answer and remote ICE
    _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('guest')
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final answer = RTCSessionDescription(
        data['sdp'] as String,
        data['type'] as String,
      );
      await _peerConnection!.setRemoteDescription(answer);
    });

    _candidatesSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('call')
        .doc('guest')
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _peerConnection?.addCandidate(RTCIceCandidate(
          data['candidate'] as String?,
          data['sdpMid'] as String?,
          data['sdpMLineIndex'] as int?,
        ));
      }
    });
  }

  Future<void> joinCall() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection ??= await createPeerConnection(config);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _localStream?.getTracks().forEach(_peerConnection!.addTrack);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
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

    final offer = RTCSessionDescription(
      hostData['sdp'] as String,
      hostData['type'] as String,
    );
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

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
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _peerConnection?.addCandidate(RTCIceCandidate(
          data['candidate'] as String?,
          data['sdpMid'] as String?,
          data['sdpMLineIndex'] as int?,
        ));
      }
    });
  }

  MediaStream? get localStream => _localStream;

  Future<void> dispose() async {
    await _candidatesSub?.cancel();
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
  }
}

