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
        const SizedBox(height: 48),
        // How it Works section
        Text(
          'How it Works',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 32),
        ..._buildHowItWorksSteps(isSmallScreen),
      ],
    );
  }

  List<Widget> _buildPlatformIcons(BuildContext context) {
    final platforms = [
      {'name': 'YouTube', 'image': 'assets/images/youtube.png'},
      {'name': 'Netflix', 'image': 'assets/images/netflix.png'},
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
                        : name == 'Netflix'
                            ? 'Paste a Netflix episode or movie URL in the Video URL field.'
                            : 'Use the Upload button or a file URL for local files.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
              // Navigate to the unified Create Room screen.
              context.go('/create-room');
            },
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textWhite.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(
                  color: AppColors.textWhite.withValues(alpha: 0.2),
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
                        : platform['name'] == 'Netflix'
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
      final index = entry.key;
      final step = entry.value;
      final isLast = index == steps.length - 1;

      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D9FF), 
                    const Color(0xFF7B2CBF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  step['number'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        step['icon'] as IconData,
                        color: const Color(0xFF00D9FF),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['description'] as String,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: AppColors.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow (except for last step)
            if (!isLast) ...[
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textWhite.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ],
        ),
      );
    }).toList();
  }
}
