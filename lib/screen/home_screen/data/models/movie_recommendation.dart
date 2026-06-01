class MovieRecommendation {
  final String title;
  final String? posterPath;
  final String language;
  final String? releaseDate;
  final String? overview;

  const MovieRecommendation({
    required this.title,
    this.posterPath,
    required this.language,
    this.releaseDate,
    this.overview,
  });

  String get languageLabel {
    switch (language) {
      case 'hi':
        return 'Hindi';
      case 'ne':
        return 'Nepali';
      default:
        return 'English';
    }
  }

  String? get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/w342$posterPath';
  }

  factory MovieRecommendation.fromJson(Map<String, dynamic> json) {
    return MovieRecommendation(
      title: json['title'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      language: json['original_language'] as String? ?? 'en',
      releaseDate: json['release_date'] as String?,
      overview: json['overview'] as String?,
    );
  }
}
