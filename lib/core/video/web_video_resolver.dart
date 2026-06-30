import 'package:http/http.dart' as http;

class WebVideoResolveResult {
  final String pageUrl;
  final String? directStreamUrl;

  const WebVideoResolveResult({
    required this.pageUrl,
    this.directStreamUrl,
  });

  bool get hasDirectStream =>
      directStreamUrl != null && directStreamUrl!.trim().isNotEmpty;
}

/// Fetches a web page and tries to find an embedded direct video stream URL.
class WebVideoResolver {
  WebVideoResolver({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  static final List<RegExp> _metaPatterns = [
    RegExp(
      r'''property=["']og:video(?::secure_url|:url)?["'][^>]*content=["']([^"']+)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''content=["']([^"']+)["'][^>]*property=["']og:video(?::secure_url|:url)?["']''',
      caseSensitive: false,
    ),
    RegExp(
      r'''name=["']twitter:player:stream["'][^>]*content=["']([^"']+)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''<video[^>]+src=["']([^"']+)''',
      caseSensitive: false,
    ),
    RegExp(
      r'''<source[^>]+src=["']([^"']+)["'][^>]*type=["']video/''',
      caseSensitive: false,
    ),
    RegExp(
      r'''"contentUrl"\s*:\s*"([^"]+)"''',
      caseSensitive: false,
    ),
  ];

  Future<WebVideoResolveResult> resolve(String pageUrl) async {
    final uri = Uri.tryParse(pageUrl.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return WebVideoResolveResult(pageUrl: pageUrl);
    }

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'User-Agent': _userAgent,
              'Accept': 'text/html,application/xhtml+xml',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return WebVideoResolveResult(pageUrl: pageUrl);
      }

      final direct = _extractDirectVideoUrl(response.body, uri);
      return WebVideoResolveResult(
        pageUrl: pageUrl,
        directStreamUrl: direct,
      );
    } catch (_) {
      return WebVideoResolveResult(pageUrl: pageUrl);
    }
  }

  String? _extractDirectVideoUrl(String html, Uri pageUri) {
    for (final pattern in _metaPatterns) {
      for (final match in pattern.allMatches(html)) {
        final candidate = _normalizeCandidate(match.group(1), pageUri);
        if (candidate != null && _looksLikeVideoStream(candidate)) {
          return candidate;
        }
      }
    }
    return null;
  }

  String? _normalizeCandidate(String? raw, Uri pageUri) {
    if (raw == null) return null;
    var value = raw.trim().replaceAll(r'\u002F', '/').replaceAll(r'\/', '/');
    if (value.isEmpty) return null;

    if (value.startsWith('//')) {
      value = '${pageUri.scheme}:$value';
    } else if (value.startsWith('/')) {
      value = '${pageUri.scheme}://${pageUri.host}$value';
    } else if (!value.startsWith('http')) {
      return null;
    }

    return value;
  }

  bool _looksLikeVideoStream(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.gif') || lower.endsWith('.jpg') || lower.endsWith('.png')) {
      return false;
    }
    if (lower.contains('.mp4') ||
        lower.contains('.m3u8') ||
        lower.contains('.webm') ||
        lower.contains('.mov') ||
        lower.contains('video') ||
        lower.contains('stream')) {
      return true;
    }
    return lower.startsWith('http');
  }
}
