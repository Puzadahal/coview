import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../config/colors/app_colors.dart';

class WebPagePlayerView extends StatefulWidget {
  final String pageUrl;
  final bool immersiveLayout;
  final VoidCallback? onVideoReady;

  const WebPagePlayerView({
    super.key,
    required this.pageUrl,
    this.immersiveLayout = false,
    this.onVideoReady,
  });

  @override
  State<WebPagePlayerView> createState() => WebPagePlayerViewState();
}

class WebPagePlayerViewState extends State<WebPagePlayerView> {
  InAppWebViewController? _controller;
  bool _pageLoaded = false;

  static const _videoProbeJs = '''
(function() {
  var videos = document.querySelectorAll('video');
  if (!videos.length) return JSON.stringify({ found: false });
  var video = videos[0];
  try { video.setAttribute('playsinline', 'true'); } catch (e) {}
  return JSON.stringify({
    found: true,
    paused: video.paused,
    currentTime: video.currentTime || 0,
    duration: video.duration || 0
  });
})()
''';

  static const _videoControlJs = '''
(function(action, seconds, shouldPlay) {
  var video = document.querySelector('video');
  if (!video) return false;
  if (action === 'play') { video.play(); return true; }
  if (action === 'pause') { video.pause(); return true; }
  if (action === 'seek') {
    var t = Number(seconds);
    if (!isNaN(t) && t >= 0) video.currentTime = t;
    return true;
  }
  if (action === 'sync') {
    var t = Number(seconds);
    if (!isNaN(t) && t >= 0) video.currentTime = t;
    if (shouldPlay) video.play(); else video.pause();
    return true;
  }
  return false;
})('%ACTION%', %SECONDS%, %SHOULD_PLAY%)
''';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.pageUrl)),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            javaScriptEnabled: true,
            useHybridComposition: true,
          ),
          onWebViewCreated: (controller) => _controller = controller,
          onLoadStop: (controller, _) async {
            if (!mounted) return;
            setState(() => _pageLoaded = true);
            await _probeVideo();
          },
        ),
        if (!_pageLoaded)
          const ColoredBox(
            color: Colors.black87,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          ),
      ],
    );
  }

  Future<void> _probeVideo() async {
    final raw = await _controller?.evaluateJavascript(source: _videoProbeJs);
    final parsed = _decodeJson(raw);
    if (!mounted) return;
    if (parsed?['found'] == true) widget.onVideoReady?.call();
  }

  Map<String, dynamic>? _decodeJson(Object? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw.toString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<double> currentPositionSeconds() async {
    final raw = await _controller?.evaluateJavascript(source: _videoProbeJs);
    final parsed = _decodeJson(raw);
    if (parsed?['found'] != true) return 0;
    return (parsed?['currentTime'] as num?)?.toDouble() ?? 0;
  }

  Future<bool> isPlaying() async {
    final raw = await _controller?.evaluateJavascript(source: _videoProbeJs);
    final parsed = _decodeJson(raw);
    if (parsed?['found'] != true) return false;
    return parsed?['paused'] != true;
  }

  Future<void> play() => _runControl(action: 'play');

  Future<void> pause() => _runControl(action: 'pause');

  Future<void> seekToSeconds(double seconds) =>
      _runControl(action: 'seek', seconds: seconds);

  Future<void> syncTo({required double seconds, required bool playing}) =>
      _runControl(action: 'sync', seconds: seconds, shouldPlay: playing);

  Future<void> _runControl({
    required String action,
    double seconds = 0,
    bool shouldPlay = false,
  }) async {
    final js = _videoControlJs
        .replaceFirst('%ACTION%', action)
        .replaceFirst('%SECONDS%', seconds.toString())
        .replaceFirst('%SHOULD_PLAY%', shouldPlay.toString());
    await _controller?.evaluateJavascript(source: js);
  }
}
