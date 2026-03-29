import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/language/app_texts.dart';
import '../../../../core/language/domain/bloc/app_language_cubit.dart';
import '../../domain/bloc/home_bloc.dart';
import '../../domain/bloc/home_event.dart';
import '../../domain/bloc/home_state.dart';
import '../widgets/previous_rooms_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(const HomeInitialized()),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  String tr(String lang, String key) => AppTexts.tr(lang, key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final useCompactNav = width < 820;
    return BlocBuilder<AppLanguageCubit, String>(
      builder: (context, selectedLanguage) {
        return Scaffold(
          backgroundColor: AppColors.primaryDark,
          drawer: useCompactNav
              ? _HomeDrawer(
                  selectedLanguage: selectedLanguage,
                  tr: tr,
                  onLanguageChanged: (code) =>
                      context.read<AppLanguageCubit>().setLanguage(code),
                )
              : null,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            titleSpacing: useCompactNav ? 8 : 16,
            title: useCompactNav
                ? const Text('SyncView', style: TextStyle(fontWeight: FontWeight.w800))
                : Row(
                    children: [
                      const Text('SyncView', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 16),
                      _NavLink(
                        label: tr(selectedLanguage, 'home'),
                        onTap: () => context.go('/home'),
                      ),
                      _NavLink(
                        label: tr(selectedLanguage, 'about'),
                        onTap: () => context.go('/about'),
                      ),
                      _LanguageMenu(
                        label: tr(selectedLanguage, 'language'),
                        current: selectedLanguage,
                        onChanged: (value) =>
                            context.read<AppLanguageCubit>().setLanguage(value),
                      ),
                      _NavLink(
                        label: tr(selectedLanguage, 'recommendations'),
                        onTap: () => context.go('/recommendations'),
                      ),
                    ],
                  ),
            actions: [
              IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.go('/profile'),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryDark, Color(0xFF14183A)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroSection(
                        isDesktop: isDesktop,
                        title: tr(selectedLanguage, 'heroTitle'),
                        subtitle: tr(selectedLanguage, 'heroSubtitle'),
                        primaryCta: tr(selectedLanguage, 'startWatching'),
                        secondaryCta: tr(selectedLanguage, 'joinExisting'),
                      ),
                      const SizedBox(height: 28),
                      _SimpleHeader(title: tr(selectedLanguage, 'howItWorks')),
                      const SizedBox(height: 14),
                      const _HowCards(),
                      const SizedBox(height: 28),
                      _SimpleHeader(title: tr(selectedLanguage, 'aboutTitle')),
                      const SizedBox(height: 12),
                      _TextCard(text: tr(selectedLanguage, 'aboutDesc')),
                      const SizedBox(height: 28),
                      _SimpleHeader(title: tr(selectedLanguage, 'trending')),
                      const SizedBox(height: 4),
                      Text(
                        tr(selectedLanguage, 'trendingSub'),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 12),
                      const _RecommendationsChips(),
                      const SizedBox(height: 28),
                      const PreviousRoomsSection(),
                      const SizedBox(height: 20),
                      _Footer(tagline: tr(selectedLanguage, 'footer')),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
        );
      },
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final String selectedLanguage;
  final String Function(String lang, String key) tr;
  final ValueChanged<String> onLanguageChanged;

  const _HomeDrawer({
    required this.selectedLanguage,
    required this.tr,
    required this.onLanguageChanged,
  });

  static const _langs = {'en': 'English', 'ne': 'Nepali', 'hi': 'Hindi'};

  @override
  Widget build(BuildContext context) {
    void closeThen(VoidCallback fn) {
      Navigator.of(context).pop();
      fn();
    }

    return Drawer(
      backgroundColor: const Color(0xFF191D44),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'SyncView',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0x33FFFFFF)),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.white),
              title: Text(tr(selectedLanguage, 'home'), style: const TextStyle(color: Colors.white)),
              onTap: () => closeThen(() => context.go('/home')),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: Text(tr(selectedLanguage, 'about'), style: const TextStyle(color: Colors.white)),
              onTap: () => closeThen(() => context.go('/about')),
            ),
            ListTile(
              leading: const Icon(Icons.recommend_outlined, color: Colors.white),
              title: Text(tr(selectedLanguage, 'recommendations'), style: const TextStyle(color: Colors.white)),
              onTap: () => closeThen(() => context.go('/recommendations')),
            ),
            const Divider(height: 1, color: Color(0x33FFFFFF)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                tr(selectedLanguage, 'language'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ..._langs.entries.map(
              (e) => RadioListTile<String>(
                value: e.key,
                groupValue: selectedLanguage,
                onChanged: (v) {
                  if (v != null) {
                    Navigator.of(context).pop();
                    onLanguageChanged(v);
                  }
                },
                activeColor: AppColors.secondary,
                title: Text(e.value, style: const TextStyle(color: Colors.white)),
              ),
            ),
            const Divider(height: 1, color: Color(0x33FFFFFF)),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white),
              title: Text('Profile', style: const TextStyle(color: Colors.white)),
              onTap: () => closeThen(() => context.go('/profile')),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  final String label;
  final String current;
  final ValueChanged<String> onChanged;
  const _LanguageMenu({
    required this.label,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const langs = {'en': 'English', 'ne': 'Nepali', 'hi': 'Hindi'};
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => langs.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text('$label: ${langs[current]}', style: const TextStyle(color: Colors.white)),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  final String title;
  final String subtitle;
  final String primaryCta;
  final String secondaryCta;

  const _HeroSection({
    required this.isDesktop,
    required this.title,
    required this.subtitle,
    required this.primaryCta,
    required this.secondaryCta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF191D44),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _copy(context)),
                const SizedBox(width: 18),
                const Expanded(child: _HeroPreview()),
              ],
            )
          : _copy(context),
    );
  }

  Widget _copy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 62 : 36,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/create-room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textDark,
              ),
              child: Text(primaryCta),
            ),
            OutlinedButton(
              onPressed: () => context.go('/join-room'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: Text(secondaryCta),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF2E336F), Color(0xFF161A38)]),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64),
      ),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  final String title;
  const _SimpleHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HowCards extends StatelessWidget {
  const _HowCards();
  @override
  Widget build(BuildContext context) {
    final cards = const [
      ('1', 'Create a room', 'Start a watch party in one click.'),
      ('2', 'Share invite link', 'Friends join instantly from browser.'),
      ('3', 'Stream + chat live', 'Watch together and talk in real time.'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = (constraints.maxWidth - 14).clamp(200.0, 320.0);
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards
              .map(
                (c) => SizedBox(
                  width: cardW,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191D44),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.$1,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.$3,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _TextCard extends StatelessWidget {
  final String text;
  const _TextCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF191D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.82))),
    );
  }
}

class _RecommendationsChips extends StatelessWidget {
  const _RecommendationsChips();
  @override
  Widget build(BuildContext context) {
    const picks = ['Dune: Part Two', 'Shogun', '3 Body Problem', 'Fallout'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: picks
          .map(
            (p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF191D44),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(p, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
    );
  }
}

class _Footer extends StatelessWidget {
  final String tagline;
  const _Footer({required this.tagline});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF191D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 420;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2026 SyncView',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                ),
                const SizedBox(height: 8),
                Text(
                  tagline,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ],
            );
          }
          return Row(
            children: [
              Flexible(
                child: Text(
                  '2026 SyncView',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  tagline,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
