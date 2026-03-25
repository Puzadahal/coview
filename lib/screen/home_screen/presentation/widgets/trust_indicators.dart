import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Visual trust indicators: platform icons and "How it Works" section.
class TrustIndicators extends StatelessWidget {
  const TrustIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Platform icons
        Text(
          'Supported Platforms',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _buildPlatformIcons(context),
        ),
        const SizedBox(height: 40),
        // How it Works section
        Text(
          'How it Works',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: _buildHowItWorksSteps(isSmallScreen),
        ),
      ],
    );
  }

  List<Widget> _buildPlatformIcons(BuildContext context) {
    final platforms = [
      {'name': 'YouTube', 'image': 'assets/images/youtube.png'},
      {'name': 'Twitch', 'image': 'assets/images/twitch.png'},
      {'name': 'Dailymotion', 'image': 'assets/images/dailymotion.png'},
      {'name': 'Local Files', 'image': 'assets/images/files.png'},
    ];

    return platforms.map((platform) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            onTap: () {
              final name = platform['name'] as String;
              // For now, all supported platforms lead into the Create Room flow,
              // with a short hint describing what to do next.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    name == 'YouTube'
                        ? 'Paste a YouTube link in the Video URL field.'
                        : name == 'Twitch'
                            ? 'Paste a Twitch stream or VOD link in the Video URL field.'
                            : name == 'Dailymotion'
                                ? 'Paste a Dailymotion video link in the Video URL field.'
                                : 'Use the Upload button or a file URL for local files.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
              // Navigate to the unified Create Room screen.
              context.go('/create-room');
            },
            child: Container(
              width: 86,
              height: 86,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkVariant.withValues(alpha: 0.65),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Image.asset(
                platform['image'] as String,
                width: 150,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Icon(
                    platform['name'] == 'YouTube'
                        ? Icons.play_circle_outline
                        : platform['name'] == 'Twitch'
                            ? Icons.videogame_asset
                            : platform['name'] == 'Dailymotion'
                                ? Icons.movie_outlined
                                : Icons.folder_outlined,
                    color: AppColors.textWhite,
                    size: 32,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            platform['name'] as String,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textWhite.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildHowItWorksSteps(bool isSmallScreen) {
    final steps = [
      {
        'number': '1',
        'title': 'Create Room',
        'description': 'Start a new sync session',
        'icon': Icons.add_circle_outline,
      },
      {
        'number': '2',
        'title': 'Invite Friends',
        'description': 'Share your room link',
        'icon': Icons.person_add_outlined,
      },
      {
        'number': '3',
        'title': 'Watch in Sync',
        'description': 'Enjoy synchronized viewing',
        'icon': Icons.play_circle_filled,
      },
    ];

    return steps.asMap().entries.map((entry) {
      final step = entry.value;

      return SizedBox(
        width: isSmallScreen ? double.infinity : 250,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryDarkVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.secondary, AppColors.primaryAccent],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      step['number'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    step['icon'] as IconData,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step['title'] as String,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step['description'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textWhite.withValues(alpha: 0.8),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
