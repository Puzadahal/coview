import 'package:equatable/equatable.dart';

/// Theme events for managing app theme
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

/// Event to toggle between light and dark mode
class ThemeToggled extends ThemeEvent {
  const ThemeToggled();
}

/// Event to set theme mode explicitly
class ThemeModeChanged extends ThemeEvent {
  final ThemeModeType mode;

  const ThemeModeChanged(this.mode);

  @override
  List<Object> get props => [mode];
}

/// Event to initialize theme from saved preferences
class ThemeInitialized extends ThemeEvent {
  const ThemeInitialized();
}

/// Theme mode types
enum ThemeModeType {
  light,
  dark,
  system,
}
