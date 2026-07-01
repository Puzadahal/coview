import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/colors/app_colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/movie_poster_image.dart';
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
          return const AppLoadingIndicator(padding: EdgeInsets.symmetric(vertical: 80));
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
                child: _CompactMovieCard(movie: movies[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class _CompactMovieCard extends StatelessWidget {
  final MovieRecommendation movie;

  const _CompactMovieCard({required this.movie});

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
                child: MoviePosterImage(posterUrl: movie.posterUrl),
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
            _LanguageBadge(label: movie.languageLabel),
          ],
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String label;

  const _LanguageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
