import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/domain/bloc/theme_bloc.dart';
import '../theme/domain/bloc/theme_event.dart';
import '../theme/domain/bloc/theme_state.dart';

/// Theme toggle button widget
/// Shows a dropdown menu with Light/Dark/System options
class ThemeToggleButton extends StatelessWidget {
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;

  const ThemeToggleButton({
    super.key,
    this.icon = Icons.brightness_6,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return PopupMenuButton<ThemeModeType>(
          icon: Icon(
            _getIcon(state.mode, isDark),
            size: iconSize ?? 24,
            color: iconColor ?? theme.iconTheme.color,
          ),
          tooltip: 'Change theme',
          onSelected: (ThemeModeType mode) {
            context.read<ThemeBloc>().add(ThemeModeChanged(mode));
          },
          itemBuilder: (context) => [
            PopupMenuItem<ThemeModeType>(
              value: ThemeModeType.light,
              child: Row(
                children: [
                  Icon(
                    Icons.light_mode,
                    size: 20,
                    color: state.mode == ThemeModeType.light
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text('Light'),
                  if (state.mode == ThemeModeType.light) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
                  ],
                ],
              ),
            ),
            PopupMenuItem<ThemeModeType>(
              value: ThemeModeType.dark,
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode,
                    size: 20,
                    color: state.mode == ThemeModeType.dark
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text('Dark'),
                  if (state.mode == ThemeModeType.dark) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
                  ],
                ],
              ),
            ),
            PopupMenuItem<ThemeModeType>(
              value: ThemeModeType.system,
              child: Row(
                children: [
                  Icon(
                    Icons.brightness_auto,
                    size: 20,
                    color: state.mode == ThemeModeType.system
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text('System'),
                  if (state.mode == ThemeModeType.system) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getIcon(ThemeModeType mode, bool isDark) {
    switch (mode) {
      case ThemeModeType.light:
        return Icons.light_mode;
      case ThemeModeType.dark:
        return Icons.dark_mode;
      case ThemeModeType.system:
        return isDark ? Icons.dark_mode : Icons.light_mode;
    }
  }
}
