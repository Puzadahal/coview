import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/bloc/room_bloc.dart';
import '../../domain/bloc/room_event.dart';
import '../../domain/bloc/room_state.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    _videoController?.dispose();
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
              children: [
                Text(state.roomName ?? 'Coview Room'),
                Text(
                  '#${widget.roomId}',
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
    if (url == null || url.isEmpty) {
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
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        !(uri.path.endsWith('.mp4') || uri.path.endsWith('.m3u8'))) {
      // Not a direct playable file URL; use external launcher instead.
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
        _initializeVideoFuture = null;
      }
      _currentVideoUrl = url;
      return;
    }

    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(uri);
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
          // Video surface
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusLarge,
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6C5CE7),
                    Color(0xFF00D9FF),
                  ],
                ),
              ),
              child: Center(
                child: state.videoUrl == null || state.videoUrl!.isEmpty
                    ? Column(
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
                      )
                    : (_videoController != null &&
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
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingMedium,
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
                                  if (uri == null) {
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
                                  final canOpen =
                                      await canLaunchUrl(uri);
                                  if (!canOpen) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot open this video link on this device.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode
                                        .externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open Video'),
                              ),
                            ],
                          ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          // Playback controls row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMedium,
              vertical: AppConstants.spacingSmall,
            ),
            child: Row(
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
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.closed_caption_outlined),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
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
                Text(
                  'Room Chat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Text(
                    'Realtime UI only',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
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
}
