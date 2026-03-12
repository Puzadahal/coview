import 'package:flutter/material.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Real-time features list section.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-time Features',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 24),
        ..._buildFeatures(isSmallScreen),
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
        'description': 'Integrated text chat or voice call features.',
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Privacy Controls',
        'description': 'Private rooms with invite-only links.',
      },
    ];

    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(
                  color: AppColors.textWhite.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: const Color(0xFF00D9FF), // Teal accent
                size: isSmallScreen ? 24 : 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'] as String,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: AppColors.textWhite.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
