import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/colors/app_colors.dart';
import '../../data/models/movie_recommendation.dart';
import '../../data/services/tmdb_service.dart';

class MovieRecommendationsSection extends StatefulWidget {
  const MovieRecommendationsSection({super.key});

  @override
  State<MovieRecommendationsSection> createState() =>
      _MovieRecommendationsSectionState();
}

class _MovieRecommendationsSectionState
    extends State<MovieRecommendationsSection> {
  static const double _cardWidth = 150;
  static const double _listHeight = 280;

  late final Future<List<MovieRecommendation>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = TmdbService().fetchRecentByLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MovieRecommendation>>(
      future: _moviesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          );
        }

        final movies = snapshot.data ?? [];
        if (movies.isEmpty) {
          return Text(
            translate('trendingEmpty'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          );
        }

        return SizedBox(
          height: _listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return SizedBox(
                width: _cardWidth,
                height: _listHeight,
                child: _MovieCard(movie: movies[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class _MovieCard extends StatelessWidget {
  final MovieRecommendation movie;

  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/create-room'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _PosterImage(posterUrl: movie.posterUrl),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                movie.languageLabel,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  final String? posterUrl;

  const _PosterImage({this.posterUrl});

  @override
  Widget build(BuildContext context) {
    if (posterUrl == null || posterUrl!.contains('placeholder')) {
      return _posterPlaceholder();
    }

    return Image.network(
      posterUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _posterPlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _posterPlaceholder(showLoader: true);
      },
    );
  }

  Widget _posterPlaceholder({bool showLoader = false}) {
    return Container(
      color: const Color(0xFF2E336F),
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary,
                ),
              )
            : Icon(
                Icons.movie_outlined,
                size: 40,
                color: Colors.white.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
