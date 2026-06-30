/// How a room video URL should be played.
enum VideoPlaybackKind {
  youtube,
  directStream,
  webPage,
  localFile,
  unsupported,
}

class VideoUrlClassifier {
  VideoUrlClassifier._();

  static const _directExtensions = [
    '.mp4',
    '.m3u8',
    '.webm',
    '.mov',
    '.mkv',
  ];

  static VideoPlaybackKind classify(String url) {
    final raw = url.trim();
    if (raw.isEmpty) return VideoPlaybackKind.unsupported;

    if (_isLikelyLocalPath(raw)) {
      return VideoPlaybackKind.localFile;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      return VideoPlaybackKind.unsupported;
    }
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      return VideoPlaybackKind.unsupported;
    }
    if (uri.host.isEmpty) return VideoPlaybackKind.unsupported;

    final host = uri.host.toLowerCase();
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return VideoPlaybackKind.youtube;
    }
    if (isDirectStreamUrl(raw)) {
      return VideoPlaybackKind.directStream;
    }

    return VideoPlaybackKind.webPage;
  }

  static bool isDirectStreamUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('firebasestorage.googleapis.com') ||
        host.contains('storage.googleapis.com')) {
      return true;
    }

    final path = Uri.decodeComponent(uri.path).toLowerCase();
    for (final ext in _directExtensions) {
      if (path.endsWith(ext) || path.contains('$ext?')) {
        return true;
      }
    }
    return false;
  }

  static bool _isLikelyLocalPath(String value) {
    final uri = Uri.tryParse(value);
    if (uri?.scheme == 'file') return true;
    if (RegExp(r'^[a-zA-Z]:\\').hasMatch(value)) return true;
    if (uri == null || !uri.hasScheme) {
      return value.startsWith('/') || value.startsWith('./');
    }
    return false;
  }
}
