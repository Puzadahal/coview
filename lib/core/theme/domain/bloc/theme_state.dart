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
    return const ThemeState(
      mode: ThemeModeType.system,
      flutterThemeMode: ThemeMode.system,
      isDarkMode: false,
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
