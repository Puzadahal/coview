import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/colors/app_colors.dart';
import '../../../../core/widgets/app_back_app_bar.dart';
import '../../../../core/widgets/app_gradient_body.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/movie_poster_image.dart';
import '../../data/models/movie_recommendation.dart';
import '../../data/services/tmdb_service.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late final Future<List<MovieRecommendation>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _moviesFuture = TmdbService().fetchRecentByLanguage(perLanguage: 6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBackAppBar(
        title: translate('recommendationsPageTitle'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: AppGradientBody(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardW = (constraints.maxWidth - 16).clamp(220.0, 300.0);
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        translate('recommendationsPageHeading'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      translate('recommendationsPageSub'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<MovieRecommendation>>(
                      future: _moviesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoadingIndicator();
                        }

                        final movies = snapshot.data ?? [];
                        if (movies.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              translate('trendingEmpty'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          );
                        }

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: movies
                              .map(
                                (movie) => SizedBox(
                                  width: cardW,
                                  child: _RecommendationCard(movie: movie),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final MovieRecommendation movie;

  const _RecommendationCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    final overview = movie.overview?.trim();
    final description = (overview != null && overview.isNotEmpty)
        ? overview
        : movie.languageLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191D44),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: MoviePosterImage(
                posterUrl: movie.posterUrl,
                useGradientPlaceholder: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          CustomButton(
            text: translate('watchWithFriends'),
            height: 44,
            fontSize: 14,
            onPressed: () => context.go('/create-room'),
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textDark,
          ),
        ],
      ),
    );
  }
}
