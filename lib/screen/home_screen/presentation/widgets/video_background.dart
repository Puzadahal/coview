import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../config/colors/app_colors.dart';
import '../../domain/bloc/home_bloc.dart';
import '../../domain/bloc/home_event.dart';

/// Cinematic video background with overlay for text readability.
class VideoBackground extends StatefulWidget {
  final String? videoPath;
  final Widget child;

  const VideoBackground({super.key, this.videoPath, required this.child});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath != null) {
      _initializeVideo();
    } else {
      _isInitialized = true;
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath!);
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(0); // Muted
      _controller!.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Notify BLoC that video loaded successfully
        context.read<HomeBloc>().add(const VideoLoaded());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Notify BLoC of video error
        context.read<HomeBloc>().add(VideoError(e.toString()));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video background or gradient fallback
        if (_controller != null &&
            _isInitialized &&
            _controller!.value.isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        else
          // Fallback gradient matching the video description
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A0B2E), // Deep purple
                  const Color(0xFF16213E), // Dark teal
                  const Color(0xFF0F3460), // Darker teal
                  AppColors.primaryDark,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        // Dark overlay for text readability (0.4 opacity)
        Container(color: Colors.black.withValues(alpha: 0.4)),
        // Content
        widget.child,
      ],
    );
  }
}
