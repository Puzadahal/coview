import 'package:flutter/material.dart';

import '../../config/colors/app_colors.dart';

class MoviePosterImage extends StatelessWidget {
  final String? posterUrl;
  final bool useGradientPlaceholder;

  const MoviePosterImage({
    super.key,
    required this.posterUrl,
    this.useGradientPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    if (posterUrl == null || posterUrl!.contains('placeholder')) {
      return _placeholder();
    }

    return Image.network(
      posterUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(showLoader: true);
      },
    );
  }

  Widget _placeholder({bool showLoader = false}) {
    return Container(
      decoration: useGradientPlaceholder
          ? const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF00D9FF)],
              ),
            )
          : null,
      color: useGradientPlaceholder ? null : const Color(0xFF2E336F),
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
                useGradientPlaceholder
                    ? Icons.play_circle_fill_rounded
                    : Icons.movie_outlined,
                size: useGradientPlaceholder ? 54 : 40,
                color: Colors.white.withValues(
                  alpha: useGradientPlaceholder ? 1 : 0.5,
                ),
              ),
      ),
    );
  }
}
