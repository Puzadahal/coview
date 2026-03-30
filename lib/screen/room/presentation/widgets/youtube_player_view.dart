import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;

import '../../../../config/colors/app_colors.dart';

/// In-app YouTube playback for both web and mobile.
///
/// - Web: youtube_player_iframe (stable for browser runtime)
/// - Mobile/Desktop: youtube_player_flutter
class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;

  const YoutubePlayerView({super.key, required this.videoUrl});

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
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
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'YouTube blocked this embed in this browser session.\n'
                            'Sign in to YouTube in this browser, refresh, or use another public video link.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
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
