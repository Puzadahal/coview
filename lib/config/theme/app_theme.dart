import 'package:flutter/material.dart';
import '../colors/app_colors.dart';

/// App theme configuration for light and dark modes
class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondary,
        surface: AppColors.backgroundWhite,
        background: AppColors.backgroundWhite,
        error: AppColors.error,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textDark,
        onSurface: AppColors.textDark,
        onBackground: AppColors.textDark,
        onError: AppColors.textWhite,
      ),
      scaffoldBackgroundColor: AppColors.backgroundWhite,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundGrey,
        labelStyle: const TextStyle(color: AppColors.textDark),
        hintStyle: TextStyle(color: AppColors.textGrey),
        prefixStyle: const TextStyle(color: AppColors.textDark),
        suffixStyle: const TextStyle(color: AppColors.textDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryAccent;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(AppColors.textWhite),
        side: BorderSide(color: AppColors.borderGrey, width: 2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondary,
        surface: AppColors.primaryDarkVariant,
        background: AppColors.primaryDark,
        error: AppColors.error,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textWhite,
        onBackground: AppColors.textWhite,
        onError: AppColors.textWhite,
      ),
      scaffoldBackgroundColor: AppColors.primaryDark,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundWhite.withValues(alpha: 0.12),
        labelStyle: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.95)),
        hintStyle: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.6)),
        prefixStyle: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.95)),
        suffixStyle: TextStyle(color: AppColors.textWhite.withValues(alpha: 0.95)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryAccent;
          }
          return AppColors.textWhite.withValues(alpha: 0.4);
        }),
        checkColor: MaterialStateProperty.all(AppColors.textWhite),
        side: BorderSide(
          color: AppColors.textWhite.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
    );
  }
}
