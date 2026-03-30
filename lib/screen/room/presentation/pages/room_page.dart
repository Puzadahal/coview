import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/bloc/room_bloc.dart';
import '../../domain/bloc/room_event.dart';
import '../../domain/bloc/room_state.dart';
import '../widgets/youtube_player_view.dart';
import '../../domain/room_call_service.dart';

/// Coview Room screen showing synchronized playback UI and real‑time chat.
class RoomPage extends StatefulWidget {
  final String roomId;

  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final TextEditingController _messageController = TextEditingController();
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoFuture;
  String? _currentVideoUrl;
  RoomCallService? _callService;
  MediaStream? _localCallStream;
  final _localRenderer = RTCVideoRenderer();

  @override
  void dispose() {
    _messageController.dispose();
    _videoController?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text;
    context.read<RoomBloc>().add(RoomMessageSent(text));
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.primaryDark : AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.primaryDarkVariant : AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
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
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Invite',
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              // For now just show a hint; backend/deep link can be wired later.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share the invite link from the Create Room screen.'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
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
                : const [
                    Color(0xFFE6E9FF),
                    Color(0xFFF5F7FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMedium),
            child: BlocBuilder<RoomBloc, RoomState>(
              builder: (context, state) {
                _setupVideoController(state.videoUrl);

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

                return isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildVideoPane(
                              theme,
                              isDark,
                              state,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingMedium),
                          Expanded(
                            flex: 2,
                            child: _buildChatPane(theme, isDark),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildVideoPane(theme, isDark, state),
                          const SizedBox(height: AppConstants.spacingMedium),
                          Expanded(
                            child: _buildChatPane(theme, isDark),
                          ),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _setupVideoController(String? url) {
    if (url == null || url.isEmpty || _isYouTubeUrl(url)) {
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
        _initializeVideoFuture = null;
        _currentVideoUrl = null;
      }
      return;
    }

    if (_currentVideoUrl == url && _videoController != null) {
      return;
    }

    final uri = Uri.tryParse(url);
    final lower = url.toLowerCase();
    final isNetwork = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.path.endsWith('.mp4') || uri.path.endsWith('.m3u8'));
    final isLocalFile = !isNetwork &&
        (lower.endsWith('.mp4') ||
            lower.endsWith('.mkv') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi') ||
            lower.endsWith('.wmv') ||
            lower.endsWith('.flv') ||
            lower.endsWith('.webm'));

    if (!isNetwork && !isLocalFile) {
      // Not a playable source for the built‑in player.
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
        _initializeVideoFuture = null;
      }
      _currentVideoUrl = url;
      return;
    }

    _videoController?.dispose();
    if (isNetwork) {
      _videoController = VideoPlayerController.networkUrl(uri);
    } else {
      _videoController = VideoPlayerController.file(File(url));
    }
    _currentVideoUrl = url;
    _initializeVideoFuture = _videoController!.initialize().then((_) {
      setState(() {});
      _videoController!.play();
    });
  }

  Widget _buildVideoPane(
    ThemeData theme,
    bool isDark,
    RoomState state,
  ) {
    final videoUrl = state.videoUrl?.trim() ?? '';
    final isLikelyLocalSource =
        videoUrl.isNotEmpty && _isLikelyLocalPath(videoUrl);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDarkVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
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
          // Video surface — YouTube fills the box (no Center) so WebView gets stable size.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusLarge,
              ),
              child: state.videoUrl == null || state.videoUrl!.isEmpty
                  ? Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6C5CE7),
                            Color(0xFF00D9FF),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              size: 72,
                              color: AppColors.textWhite
                                  .withValues(alpha: 0.95),
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
                              colors: [
                                Color(0xFF6C5CE7),
                                Color(0xFF00D9FF),
                              ],
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
                                      color: AppColors.textWhite
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : _isYouTubeUrl(state.videoUrl!)
                      ? YoutubePlayerView(videoUrl: state.videoUrl!)
                      : Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF6C5CE7),
                                Color(0xFF00D9FF),
                              ],
                            ),
                          ),
                          child: Center(
                            child: (_videoController != null &&
                                    _initializeVideoFuture != null)
                                ? FutureBuilder<void>(
                                    future: _initializeVideoFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState !=
                                          ConnectionState.done) {
                                        return const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.textWhite,
                                          ),
                                        );
                                      }
                                      return Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: _videoController!
                                                .value.aspectRatio,
                                            child: VideoPlayer(
                                              _videoController!,
                                            ),
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
                                              setState(() {
                                                if (_videoController!
                                                    .value.isPlaying) {
                                                  _videoController!.pause();
                                                } else {
                                                  _videoController!.play();
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_circle_fill,
                                        size: 72,
                                        color: AppColors.textWhite
                                            .withValues(alpha: 0.95),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Open video in browser / app',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              AppConstants.spacingMedium,
                                        ),
                                        child: SelectableText(
                                          state.videoUrl!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textWhite
                                                .withValues(alpha: 0.9),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final uri =
                                              Uri.tryParse(state.videoUrl!);
                                          if (uri == null || !uri.hasScheme) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Invalid video URL. Please recreate the room with a valid link.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          try {
                                            final ok = await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                            if (!mounted) return;
                                            if (!ok) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'No app handled this link. Install a browser or try again.',
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Could not open link: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Open Video'),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          // Playback + call controls row (scroll on narrow screens)
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
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.replay_10),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.skip_previous),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.play_arrow,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.skip_next),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.forward_10),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Start Call (Host)',
                    onPressed: () async {
                      try {
                        _callService ??= RoomCallService(state.roomId);
                        await _localRenderer.initialize();
                        await _callService!.startCall();
                        if (!mounted) return;
                        setState(() {
                          _localCallStream = _callService!.localStream;
                          _localRenderer.srcObject = _localCallStream;
                        });
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Camera/mic: allow permissions in System settings. ($e)',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.video_call),
                  ),
                  IconButton(
                    tooltip: 'Join Call (Guest)',
                    onPressed: () async {
                      try {
                        _callService ??= RoomCallService(state.roomId);
                        await _localRenderer.initialize();
                        await _callService!.joinCall();
                        if (!mounted) return;
                        setState(() {
                          _localCallStream = _callService!.localStream;
                          _localRenderer.srcObject = _localCallStream;
                        });
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Camera/mic: allow permissions in System settings. ($e)',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.call),
                  ),
                  IconButton(
                    tooltip: 'End Call',
                    onPressed: () async {
                      await _callService?.dispose();
                      if (!mounted) return;
                      setState(() {
                        _localCallStream = null;
                        _localRenderer.srcObject = null;
                      });
                    },
                    icon: const Icon(Icons.call_end),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          if (_localCallStream != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppConstants.spacingMedium,
                right: AppConstants.spacingMedium,
                bottom: AppConstants.spacingSmall,
              ),
              child: SizedBox(
                height: 120,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusMedium),
                  child: RTCVideoView(_localRenderer, mirror: true),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatPane(ThemeData theme, bool isDark) {
    return Container(
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
            padding: const EdgeInsets.all(AppConstants.spacingMedium),
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
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
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
                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.spacingMedium),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.author == 'You';
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: maxBubbleW),
                        margin: const EdgeInsets.only(
                          bottom: AppConstants.spacingSmall,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMedium,
                          vertical: AppConstants.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface
                                  .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                              AppConstants.borderRadiusMedium,
                            ),
                            topRight: Radius.circular(
                              AppConstants.borderRadiusMedium,
                            ),
                            bottomLeft: Radius.circular(
                              isMe
                                  ? AppConstants.borderRadiusMedium
                                  : AppConstants.borderRadiusSmall,
                            ),
                            bottomRight: Radius.circular(
                              isMe
                                  ? AppConstants.borderRadiusSmall
                                  : AppConstants.borderRadiusMedium,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.author,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isMe
                                    ? AppColors.textWhite
                                        .withValues(alpha: 0.8)
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.text,
                              softWrap: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isMe
                                    ? AppColors.textWhite
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Say something to the room...',
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
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    // e.g. C:\video.mp4
    if (RegExp(r'^[a-zA-Z]:\\').hasMatch(url)) return true;
    // no scheme -> relative/local
    if (!uri.hasScheme) return true;
    return false;
  }
}
