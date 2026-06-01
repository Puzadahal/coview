import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/tmdb_secrets.dart';
import '../models/movie_recommendation.dart';

/// Fetches recent movies from TMDB by language.
///
/// Key resolution order:
/// 1. `--dart-define=TMDB_API_KEY=...` at build/run time
/// 2. `lib/config/tmdb_secrets.dart` (local, gitignored)
/// 3. Curated fallback list if no key is set
class TmdbService {
  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static String get apiKey {
    const fromDefine = String.fromEnvironment('TMDB_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return TmdbSecrets.apiKey;
  }

  static const _languageQueries = {
    'en': 'en',
    'hi': 'hi',
    'ne': 'ne',
  };

  static const List<MovieRecommendation> _fallbackMovies = [
    MovieRecommendation(
      title: 'Dune: Part Two',
      posterPath: '/9P12L3CTiZUQLZUzw0wUrdK5Mj.jpg',
      language: 'en',
      releaseDate: '2024-03-01',
      overview: 'Epic sci-fi sequel following Paul Atreides.',
    ),
    MovieRecommendation(
      title: 'Inside Out 2',
      posterPath: '/vpnVm9Bf6659l47x2oZ8.jpg',
      language: 'en',
      releaseDate: '2024-06-14',
      overview: 'Riley faces new emotions in her teenage years.',
    ),
    MovieRecommendation(
      title: 'Deadpool & Wolverine',
      posterPath: '/8cdW65Zmqh17ZDDdlXZs2Rv1DK.jpg',
      language: 'en',
      releaseDate: '2024-07-26',
      overview: 'Marvel action comedy team-up.',
    ),
    MovieRecommendation(
      title: 'Stree 2',
      posterPath: '/x6Wk24HCZQ80g41y6Z8YQ5Z5Z5Z.jpg',
      language: 'hi',
      releaseDate: '2024-08-15',
      overview: 'Horror comedy sequel set in a haunted town.',
    ),
    MovieRecommendation(
      title: 'Kalki 2898 AD',
      posterPath: '/7bScCo5jVf2Dbio1Vq9q.jpg',
      language: 'hi',
      releaseDate: '2024-06-27',
      overview: 'Futuristic Indian sci-fi epic.',
    ),
    MovieRecommendation(
      title: 'Animal',
      posterPath: '/iBq0i2QHK1YoGcC9Y0CSDh1KaQ.jpg',
      language: 'hi',
      releaseDate: '2023-12-01',
      overview: 'Intense action drama about a troubled son.',
    ),
    MovieRecommendation(
      title: 'Pashupati Prasad 2',
      language: 'ne',
      releaseDate: '2024-01-01',
      overview: 'Beloved Nepali comedy sequel.',
    ),
    MovieRecommendation(
      title: 'Jhola',
      language: 'ne',
      releaseDate: '2013-02-08',
      overview: 'Award-winning Nepali drama.',
    ),
    MovieRecommendation(
      title: 'Kabaddi 4',
      language: 'ne',
      releaseDate: '2022-04-29',
      overview: 'Popular Nepali romantic comedy series film.',
    ),
  ];

  Future<List<MovieRecommendation>> fetchRecentByLanguage({
    int perLanguage = 4,
  }) async {
    if (apiKey.isEmpty) {
      return _sortedFallback();
    }

    try {
      final results = await Future.wait(
        _languageQueries.entries.map(
          (entry) => _discoverMovies(
            language: entry.value,
            perPage: perLanguage,
          ),
        ),
      );

      final merged = results.expand((list) => list).toList();
      if (merged.isEmpty) return _sortedFallback();

      merged.sort((a, b) {
        final aDate = a.releaseDate ?? '';
        final bDate = b.releaseDate ?? '';
        return bDate.compareTo(aDate);
      });
      return merged;
    } catch (_) {
      return _sortedFallback();
    }
  }

  List<MovieRecommendation> _sortedFallback() {
    final list = List<MovieRecommendation>.from(_fallbackMovies);
    list.sort((a, b) {
      final aDate = a.releaseDate ?? '';
      final bDate = b.releaseDate ?? '';
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<List<MovieRecommendation>> _discoverMovies({
    required String language,
    required int perPage,
  }) async {
    final uri = Uri.parse('$_baseUrl/discover/movie').replace(
      queryParameters: {
        'api_key': apiKey,
        'with_original_language': language,
        'sort_by': 'primary_release_date.desc',
        'include_adult': 'false',
        'include_video': 'false',
        'page': '1',
        'vote_count.gte': '10',
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];

    return results
        .take(perPage)
        .map(
          (item) => MovieRecommendation.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .where((m) => m.posterPath != null && m.posterPath!.isNotEmpty)
        .toList();
  }
}
