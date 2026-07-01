import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/room_call_service.dart';

/// Small local camera preview shown below room playback controls.
class RoomCallLocalStrip extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final bool renderersReady;
  final bool micMuted;
  final bool cameraMuted;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onEndCall;

  const RoomCallLocalStrip({
    super.key,
    required this.renderer,
    required this.renderersReady,
    required this.micMuted,
    required this.cameraMuted,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: renderersReady
                  ? RTCVideoView(
                      renderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit
                          .RTCVideoViewObjectFitCover,
                    )
                  : const ColoredBox(
                      color: Color(0xFF101428),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Video call',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _MiniCallButton(
                      icon: micMuted ? Icons.mic_off : Icons.mic,
                      tooltip: micMuted ? 'Unmute' : 'Mute',
                      onPressed: onToggleMic,
                    ),
                    _MiniCallButton(
                      icon: cameraMuted ? Icons.videocam_off : Icons.videocam,
                      tooltip: cameraMuted ? 'Camera on' : 'Camera off',
                      onPressed: onToggleCamera,
                    ),
                    _MiniCallButton(
                      icon: Icons.cameraswitch,
                      tooltip: 'Flip camera',
                      onPressed: onSwitchCamera,
                    ),
                    _MiniCallButton(
                      icon: Icons.call_end,
                      tooltip: 'End call',
                      color: Colors.redAccent,
                      onPressed: onEndCall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draggable remote participant bubble over the chat pane.
class RoomCallRemoteBubble extends StatefulWidget {
  final RTCVideoRenderer renderer;
  final bool renderersReady;
  final bool hasRemoteStream;
  final bool hasRemoteVideo;
  final RoomCallConnectionState connectionState;
  final bool isRoomHost;
  final String remoteParticipantName;
  final int remoteStreamVersion;
  final VoidCallback onClose;

  const RoomCallRemoteBubble({
    super.key,
    required this.renderer,
    required this.renderersReady,
    required this.hasRemoteStream,
    required this.hasRemoteVideo,
    required this.connectionState,
    required this.isRoomHost,
    required this.remoteParticipantName,
    required this.remoteStreamVersion,
    required this.onClose,
  });

  @override
  State<RoomCallRemoteBubble> createState() => _RoomCallRemoteBubbleState();
}

class _RoomCallRemoteBubbleState extends State<RoomCallRemoteBubble> {
  Timer? _loadingTimer;
  bool _loadingTimedOut = false;

  @override
  void initState() {
    super.initState();
    _armLoadingTimer();
  }

  @override
  void didUpdateWidget(covariant RoomCallRemoteBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectionState == RoomCallConnectionState.connected &&
        widget.hasRemoteVideo &&
        widget.renderer.videoWidth > 0) {
      _loadingTimedOut = false;
      _loadingTimer?.cancel();
    } else if (widget.remoteStreamVersion != oldWidget.remoteStreamVersion ||
        widget.connectionState != oldWidget.connectionState) {
      _loadingTimedOut = false;
      _armLoadingTimer();
    }
  }

  void _armLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted) return;
      if (widget.renderer.videoWidth > 0 && widget.hasRemoteVideo) return;
      setState(() => _loadingTimedOut = true);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  String get _statusLabel {
    if (_loadingTimedOut) return 'Connection slow';
    if (widget.hasRemoteVideo && widget.renderersReady) {
      return widget.remoteParticipantName;
    }
    if (widget.hasRemoteStream && widget.renderersReady) {
      return widget.remoteParticipantName;
    }
    return switch (widget.connectionState) {
      RoomCallConnectionState.connecting when widget.isRoomHost => 'Waiting…',
      RoomCallConnectionState.connecting => 'Joining…',
      RoomCallConnectionState.failed => 'Failed',
      RoomCallConnectionState.connected => 'Connected',
      _ when widget.isRoomHost => 'Waiting…',
      _ => 'Connecting…',
    };
  }

  @override
  Widget build(BuildContext context) {
    final showVideo = widget.hasRemoteVideo && widget.renderersReady;
    final videoReady =
        widget.renderer.videoWidth > 0 && widget.renderer.videoHeight > 0;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 132,
        height: 186,
        decoration: BoxDecoration(
          color: const Color(0xFF101428),
          border: Border.all(color: AppColors.secondary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showVideo)
              Stack(
                fit: StackFit.expand,
                children: [
                  RTCVideoView(
                    widget.renderer,
                    key: ValueKey('remote-${widget.remoteStreamVersion}'),
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                  if (!videoReady && !_loadingTimedOut)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.secondary,
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connecting…',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_loadingTimedOut && !videoReady)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Center(
                        child: Text(
                          'Still connecting.\nDifferent networks can be slow — '
                          'keep both apps open.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 9,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else if (widget.hasRemoteStream && widget.renderersReady)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${widget.remoteParticipantName}\n(camera off)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.connectionState ==
                          RoomCallConnectionState.connecting)
                        const CircularProgressIndicator(
                          color: AppColors.secondary,
                          strokeWidth: 2,
                        )
                      else
                        Icon(
                          Icons.person_outline,
                          size: 36,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isRoomHost
                            ? 'Waiting for someone to join…'
                            : 'Waiting for ${widget.remoteParticipantName}…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCallButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _MiniCallButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: (color ?? AppColors.primaryDarkVariant).withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
