import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubePlayerView extends StatefulWidget {
  final String videoUrl;

  const YoutubePlayerView({super.key, required this.videoUrl});

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
  late final YoutubePlayerController _controller;
  late final String _videoId;

  @override
  void initState() {
    super.initState();
    _videoId =
        YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';

    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableKeyboard: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId.isEmpty) {
      return const Center(
        child: Text(
          'Invalid YouTube link for this room.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return YoutubePlayerScaffold(
      controller: _controller,
      builder: (context, player) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: player,
        );
      },
    );
  }
}

