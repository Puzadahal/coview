import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// BLoC for managing app theme
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeModeKey = 'theme_mode';

  ThemeBloc() : super(ThemeState.initial()) {
    on<ThemeInitialized>(_onThemeInitialized);
    on<ThemeToggled>(_onThemeToggled);
    on<ThemeModeChanged>(_onThemeModeChanged);
  }

  /// Initialize theme from saved preferences
  Future<void> _onThemeInitialized(
    ThemeInitialized event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);

      ThemeModeType mode;
      if (savedMode == 'light') {
        mode = ThemeModeType.light;
      } else if (savedMode == 'dark') {
        mode = ThemeModeType.dark;
      } else {
        mode = ThemeModeType.system;
      }

      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isDarkMode = mode == ThemeModeType.dark ||
          (mode == ThemeModeType.system && brightness == Brightness.dark);

      emit(state.copyWith(
        mode: mode,
        flutterThemeMode: _getFlutterThemeMode(mode),
        isDarkMode: isDarkMode,
      ));
    } catch (e) {
      // If error, use system default
      emit(state);
    }
  }

  /// Toggle between light and dark (ignores system mode)
  Future<void> _onThemeToggled(
    ThemeToggled event,
    Emitter<ThemeState> emit,
  ) async {
    final newMode = state.isDarkMode ? ThemeModeType.light : ThemeModeType.dark;
    await _saveThemeMode(newMode);

    emit(state.copyWith(
      mode: newMode,
      flutterThemeMode: _getFlutterThemeMode(newMode),
      isDarkMode: !state.isDarkMode,
    ));
  }

  /// Change theme mode explicitly
  Future<void> _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    await _saveThemeMode(event.mode);

    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = event.mode == ThemeModeType.dark ||
        (event.mode == ThemeModeType.system && brightness == Brightness.dark);

    emit(state.copyWith(
      mode: event.mode,
      flutterThemeMode: _getFlutterThemeMode(event.mode),
      isDarkMode: isDarkMode,
    ));
  }

  /// Convert ThemeModeType to Flutter's ThemeMode
  ThemeMode _getFlutterThemeMode(ThemeModeType mode) {
    switch (mode) {
      case ThemeModeType.light:
        return ThemeMode.light;
      case ThemeModeType.dark:
        return ThemeMode.dark;
      case ThemeModeType.system:
        return ThemeMode.system;
    }
  }

  /// Save theme mode to preferences
  Future<void> _saveThemeMode(ThemeModeType mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      // Ignore save errors
    }
  }
}
