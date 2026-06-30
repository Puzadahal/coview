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
class RoomCallRemoteBubble extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final bool renderersReady;
  final bool hasRemoteStream;
  final RoomCallConnectionState connectionState;
  final bool isRoomHost;
  final VoidCallback onClose;

  const RoomCallRemoteBubble({
    super.key,
    required this.renderer,
    required this.renderersReady,
    required this.hasRemoteStream,
    required this.connectionState,
    required this.isRoomHost,
    required this.onClose,
  });

  String get _statusLabel {
    if (hasRemoteStream && renderersReady) return 'Friend';
    return switch (connectionState) {
      RoomCallConnectionState.connecting when isRoomHost => 'Waiting…',
      RoomCallConnectionState.connecting => 'Joining…',
      RoomCallConnectionState.failed => 'Failed',
      RoomCallConnectionState.connected => 'Connected',
      _ when isRoomHost => 'Waiting for friend',
      _ => 'Connecting…',
    };
  }

  @override
  Widget build(BuildContext context) {
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
            if (hasRemoteStream && renderersReady)
              RTCVideoView(
                renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (connectionState == RoomCallConnectionState.connecting)
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
                        isRoomHost
                            ? 'Ask friend to tap camera'
                            : 'Waiting for video…',
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
                      onTap: onClose,
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
