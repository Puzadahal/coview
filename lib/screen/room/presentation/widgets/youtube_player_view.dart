import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Embeds YouTube via iframe. Some videos show error 150/152 in embeds (owner
/// disabled embedding, age/region, etc.) — we offer “Open in YouTube”.
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
    _videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl) ?? '';

    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videoId,
      // Tap-to-play avoids autoplay policy issues on mobile WebViews.
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableKeyboard: true,
        playsInline: true,
        origin: 'https://www.youtube.com',
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _openInYouTubeApp() async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$_videoId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return YoutubeValueBuilder(
          controller: _controller,
          builder: (context, value) {
            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: player,
                ),
                if (value.hasError)
                  Material(
                    color: Colors.black.withValues(alpha: 0.72),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorLabel(value.error),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _openInYouTubeApp,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open in YouTube'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _errorLabel(YoutubeError err) {
    switch (err) {
      case YoutubeError.notEmbeddable:
      case YoutubeError.sameAsNotEmbeddable:
        return 'Embedding is disabled for this video. Open it in the YouTube app.';
      case YoutubeError.videoNotFound:
      case YoutubeError.cannotFindVideo:
        return 'Video not found or is private.';
      case YoutubeError.invalidParam:
        return 'Invalid video link.';
      default:
        return 'Playback failed in the player. Try opening in YouTube.';
    }
  }
}
