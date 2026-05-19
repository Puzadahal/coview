import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lastUpdated;
  final IconData icon;
  final List<LegalSection> sections;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.primaryDarkVariant.withValues(alpha: 0.72)
        : AppColors.backgroundWhite;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLarge),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LegalHero(
                  title: title,
                  subtitle: subtitle,
                  lastUpdated: lastUpdated,
                  icon: icon,
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingMedium,
                    ),
                    child: _LegalSectionCard(
                      section: section,
                      surfaceColor: surfaceColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Text(
                  'This document is provided for app transparency and does not replace legal advice.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegalSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const LegalSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

class _LegalHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lastUpdated;
  final IconData icon;

  const _LegalHero({
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryAccent, AppColors.primaryDarkVariant],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
            child: Icon(icon, color: AppColors.textWhite, size: 28),
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMedium,
              vertical: AppConstants.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Last updated: $lastUpdated',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  final LegalSection section;
  final Color surfaceColor;

  const _LegalSectionCard({required this.section, required this.surfaceColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (section.paragraphs.isNotEmpty)
              const SizedBox(height: AppConstants.spacingSmall),
            ...section.paragraphs.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppConstants.spacingSmall,
                ),
                child: Text(
                  paragraph,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ),
            if (section.bullets.isNotEmpty)
              const SizedBox(height: AppConstants.spacingXSmall),
            ...section.bullets.map((bullet) => _LegalBullet(text: bullet)),
          ],
        ),
      ),
    );
  }
}

class _LegalBullet extends StatelessWidget {
  final String text;

  const _LegalBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: AppColors.primaryAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSmall),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
