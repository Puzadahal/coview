import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'theme_event.dart';

/// Theme state
class ThemeState extends Equatable {
  final ThemeModeType mode;
  final ThemeMode flutterThemeMode;
  final bool isDarkMode;

  const ThemeState({
    required this.mode,
    required this.flutterThemeMode,
    required this.isDarkMode,
  });

  /// Initial state
  factory ThemeState.initial() {
    // Default the app to dark mode for a more cinematic, watch‑party feel.
    return const ThemeState(
      mode: ThemeModeType.dark,
      flutterThemeMode: ThemeMode.dark,
      isDarkMode: true,
    );
  }

  /// Create state with mode
  ThemeState copyWith({
    ThemeModeType? mode,
    ThemeMode? flutterThemeMode,
    bool? isDarkMode,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      flutterThemeMode: flutterThemeMode ?? this.flutterThemeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  List<Object> get props => [mode, flutterThemeMode, isDarkMode];
}
