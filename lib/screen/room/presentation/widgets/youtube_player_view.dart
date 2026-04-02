import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/colors/app_colors.dart';

/// In-app YouTube playback for both web and mobile.
///
/// - Web: youtube_player_iframe (stable for browser runtime)
/// - Mobile/Desktop: youtube_player_flutter
class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;

  const YoutubePlayerView({super.key, required this.videoUrl});

  @override
  State<YoutubePlayerView> createState() => YoutubePlayerViewState();
}

class YoutubePlayerViewState extends State<YoutubePlayerView> {
  ypf.YoutubePlayerController? _mobileController;
  ypi.YoutubePlayerController? _webController;
  String _videoId = '';

  @override
  void initState() {
    super.initState();
    _applyUrl(widget.videoUrl);
  }

  @override
  void didUpdateWidget(YoutubePlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _applyUrl(widget.videoUrl);
    }
  }

  void _applyUrl(String url) {
    final id = ypf.YoutubePlayer.convertUrlToId(url) ?? '';
    if (id.length != 11) {
      _videoId = '';
      return;
    }

    _videoId = id;
    if (kIsWeb) {
      _webController = ypi.YoutubePlayerController.fromVideoId(
        videoId: _videoId,
        // Autoplay inside embedded browsers often triggers YouTube
        // "sign in to confirm you're not a bot". Let the user press play.
        autoPlay: false,
        params: const ypi.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableKeyboard: true,
          strictRelatedVideos: true,
          interfaceLanguage: 'en',
        ),
      );
    } else {
      _mobileController = ypf.YoutubePlayerController(
        initialVideoId: _videoId,
        flags: const ypf.YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          loop: false,
          isLive: false,
          controlsVisibleAtStart: false,
        ),
      );
    }
  }

  void _disposeControllers() {
    _mobileController?.dispose();
    _mobileController = null;
    _webController?.close();
    _webController = null;
    _videoId = '';
  }

  bool get hasController =>
      _videoId.isNotEmpty &&
      ((kIsWeb && _webController != null) ||
          (!kIsWeb && _mobileController != null));

  Future<void> play() async {
    if (kIsWeb) {
      await _webController?.playVideo();
    } else {
      _mobileController?.play();
    }
  }

  Future<void> pause() async {
    if (kIsWeb) {
      await _webController?.pauseVideo();
    } else {
      _mobileController?.pause();
    }
  }

  Future<void> seekToSeconds(double seconds) async {
    if (seconds.isNaN) return;
    final safe = seconds < 0 ? 0.0 : seconds;
    if (kIsWeb) {
      await _webController?.seekTo(seconds: safe, allowSeekAhead: true);
    } else {
      _mobileController?.seekTo(Duration(milliseconds: (safe * 1000).round()));
    }
  }

  Future<bool> isPlaying() async {
    if (kIsWeb) {
      return (_webController?.value.playerState == ypi.PlayerState.playing);
    }
    return _mobileController?.value.isPlaying ?? false;
  }

  Future<double> currentPositionSeconds() async {
    if (kIsWeb) {
      final c = _webController;
      if (c == null) return 0;
      return await c.currentTime;
    }
    final pos = _mobileController?.value.position ?? Duration.zero;
    return pos.inMilliseconds / 1000.0;
  }

  Future<void> _openInYouTube() async {
    final id = _videoId;
    if (id.isEmpty) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$id');
    try {
      if (!await canLaunchUrl(uri)) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignore; we'll just keep the error overlay visible.
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Invalid YouTube link for this room.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (kIsWeb) {
      final c = _webController;
      if (c == null) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ypi.YoutubePlayerScaffold(
          controller: c,
          aspectRatio: 16 / 9,
          builder: (context, player) => ypi.YoutubeValueBuilder(
            controller: c,
            builder: (context, value) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  player,
                  if (value.hasError)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: 0.78),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_off_outlined,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'YouTube blocked this embed in this browser session.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: _openInYouTube,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open in YouTube'),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'If it still fails, sign in to YouTube in Chrome and refresh.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
    }

    final c = _mobileController;
    if (c == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ypf.YoutubePlayerBuilder(
        player: ypf.YoutubePlayer(
          controller: c,
          aspectRatio: 16 / 9,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.secondary,
          progressColors: ypf.ProgressBarColors(
            playedColor: AppColors.secondary,
            handleColor: AppColors.primaryAccent,
          ),
        ),
        builder: (context, player) => Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            player,
            if (c.value.hasError)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.75),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This video can’t play embedded here (often blocked by the uploader). '
                        'Create the room with a different video link.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => c.load(_videoId),
                        child: const Text('Retry'),
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
