import 'package:flutter/material.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Why SyncView',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 30,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Built for fast room creation and shared viewing sessions.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppColors.textWhite.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _buildFeatures(isSmallScreen),
        ),
      ],
    );
  }

  List<Widget> _buildFeatures(bool isSmallScreen) {
    final features = [
      {
        'icon': Icons.sync,
        'title': 'Perfect Sync',
        'description': 'One-click synchronization for YouTube, Twitch, Dailymotion, or local files.',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'Live Interaction',
        'description': 'Real-time chat alongside your video room.',
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Privacy Controls',
        'description': 'Private rooms with invite-only links.',
      },
    ];

    return features.map((feature) {
      return SizedBox(
        width: isSmallScreen ? double.infinity : 320,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primaryDarkVariant.withValues(alpha: 0.62),
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusLarge),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppColors.secondary,
                  size: isSmallScreen ? 22 : 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                feature['title'] as String,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                feature['description'] as String,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
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
