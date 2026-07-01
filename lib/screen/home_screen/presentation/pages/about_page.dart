import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/widgets/app_back_app_bar.dart';
import '../../../../core/widgets/app_gradient_body.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBackAppBar(
        title: translate('aboutPageTitle'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: AppGradientBody(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    translate('aboutPageHeading'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  translate('aboutPageSub'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 17,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _InfoCard(
                  title: translate('whatWeFocus'),
                  points: [
                    translate('focus_point_1'),
                    translate('focus_point_2'),
                    translate('focus_point_3'),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: translate('ourVision'),
                  points: [
                    translate('vision_point_1'),
                    translate('vision_point_2'),
                    translate('vision_point_3'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> points;

  const _InfoCard({required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF191D44),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
