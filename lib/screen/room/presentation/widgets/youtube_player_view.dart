import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../config/colors/app_colors.dart';

/// In-app YouTube playback (no external YouTube app / browser).
class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;

  const YoutubePlayerView({super.key, required this.videoUrl});

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
  YoutubePlayerController? _controller;
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
      _disposeController();
      _applyUrl(widget.videoUrl);
    }
  }

  void _applyUrl(String url) {
    final id = YoutubePlayer.convertUrlToId(url) ?? '';
    if (id.length != 11) {
      _videoId = '';
      return;
    }
    _videoId = id;
    _controller = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        loop: false,
        isLive: false,
        controlsVisibleAtStart: false,
      ),
    )..addListener(_onPlayerUpdate);
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  void _disposeController() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    _controller = null;
    _videoId = '';
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId.isEmpty || _controller == null) {
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

    final c = _controller!;
    final hasErr = c.value.hasError;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          YoutubePlayer(
            controller: c,
            aspectRatio: 16 / 9,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.secondary,
            progressColors: ProgressBarColors(
              playedColor: AppColors.secondary,
              handleColor: AppColors.primaryAccent,
            ),
          ),
          if (hasErr)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.75),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_outlined,
                        color: Colors.white, size: 40),
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
    );
  }
}
