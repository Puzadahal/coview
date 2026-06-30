import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/colors/app_colors.dart';

class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;

  /// When the native player enters/exits fullscreen (in-player control), parent
  /// can hide chat and use a video-only layout.
  final ValueChanged<bool>? onFullscreenChanged;

  /// Square corners when embedded in an edge-to-edge immersive layout.
  final bool immersiveLayout;

  const YoutubePlayerView({
    super.key,
    required this.videoUrl,
    this.onFullscreenChanged,
    this.immersiveLayout = false,
  });

  @override
  State<YoutubePlayerView> createState() => YoutubePlayerViewState();
}

class YoutubePlayerViewState extends State<YoutubePlayerView> {
  ypf.YoutubePlayerController? _mobileController;
  ypi.YoutubePlayerController? _webController;
  String _videoId = '';
  bool _lastNotifiedFullscreen = false;

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
    if (!kIsWeb &&
        widget.onFullscreenChanged != null &&
        _lastNotifiedFullscreen) {
      _lastNotifiedFullscreen = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFullscreenChanged?.call(false);
      });
    }
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

  /// True while the native player is in fullscreen (user tapped fullscreen).
  bool get isYoutubeFullscreen =>
      !kIsWeb && (_mobileController?.value.isFullScreen ?? false);

  /// Leave fullscreen and restore normal orientations without leaving the room.
  Future<void> exitYoutubeFullscreen() async {
    if (kIsWeb) return;
    final c = _mobileController;
    if (c == null) return;
    if (c.value.isFullScreen) {
      c.toggleFullScreenMode();
    }
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _openInYouTube() async {
    final id = _videoId;
    if (id.isEmpty) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$id');
    try {
      if (!await canLaunchUrl(uri)) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// YouTube IFrame API error codes 
  static String _embedErrorExplanation(int code) {
    switch (code) {
      case 1:
        return 'Invalid or malformed video ID.';
      case 2:
        return 'The request contains an invalid parameter value.';
      case 5:
        return 'This content cannot be played in the embedded player.';
      case 100:
        return 'Video not found (removed, private, or wrong ID).';
      case 101:
      case 150:
        return 'The owner disabled playback outside YouTube (embed blocked). '
            'Use “Open in YouTube” below, or choose another video for watch-together.';
      case 105:
        return 'YouTube could not determine the error for this video.';
      default:
        return 'This video could not play in the app. Try opening it in YouTube '
            'or use a different link.';
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
    final clipRadius = widget.immersiveLayout ? 0.0 : 16.0;
    // Do not use [YoutubePlayerBuilder]: it forces full window height in
    // landscape and toggles "fullscreen" on rotation, which overflows inside
    // the room card and makes the app bar back button leave the room.
    return ClipRRect(
      borderRadius: BorderRadius.circular(clipRadius),
      child: ValueListenableBuilder<ypf.YoutubePlayerValue>(
        valueListenable: c,
        builder: (context, value, _) {
          if (!kIsWeb && widget.onFullscreenChanged != null) {
            final fs = value.isFullScreen;
            if (fs != _lastNotifiedFullscreen) {
              _lastNotifiedFullscreen = fs;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widget.onFullscreenChanged!(fs);
                }
              });
            }
          }
          return PopScope(
            canPop: !value.isFullScreen,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (c.value.isFullScreen) {
                c.toggleFullScreenMode();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ypf.YoutubePlayer(
                    controller: c,
                    aspectRatio: 16 / 9,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppColors.secondary,
                    progressColors: ypf.ProgressBarColors(
                      playedColor: AppColors.secondary,
                      handleColor: AppColors.primaryAccent,
                    ),
                  ),
                ),
                if (value.hasError)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.82),
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
                          Text(
                            _embedErrorExplanation(value.errorCode),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          if (value.errorCode != 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Error code: ${value.errorCode}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _openInYouTube,
                            icon: const Icon(Icons.open_in_new),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.textDark,
                            ),
                            label: const Text('Open in YouTube'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => c.load(_videoId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            child: const Text('Retry in app'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
