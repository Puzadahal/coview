import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors - Modern deep purple/blue gradient palette
  static const Color primaryDark = Color(0xFF0A0E27); // Deep space blue-black
  static const Color primaryDarkVariant = Color(0xFF1A1B3A); // Rich dark purple-blue
  static const Color primaryAccent = Color(0xFF6C5CE7); // Vibrant purple
  static const Color primaryAccentLight = Color(0xFF8B7ED8); // Lighter purple
  static const Color primaryWhite = Color(0xFFFFFFFF);

  // Secondary Colors - Teal/Cyan accents
  static const Color secondary = Color(0xFF00D9FF); // Bright cyan
  static const Color secondaryDark = Color(0xFF00A8CC); // Darker cyan
  static const Color secondaryLight = Color(0xFF33E0FF); // Light cyan

  // Text Colors
  static const Color textDark = Color(0xFF000000);
  static const Color textGrey = Color(0xFF808080);
  static const Color textGreyLight = Color(0xFFB0B0B0);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Border Colors
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color borderGreyLight = Color(0xFFF0F0F0);
  static const Color borderAccent = Color(0xFF6C5CE7); // Purple border

  // Background Colors
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0A0E27); // Deep space background
  
  // Light Theme Background Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  
  // Dark Theme Background Colors
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color darkSurface = Color(0xFF1A1B3A);
  static const Color darkCard = Color(0xFF1A1B3A);

  // Status Colors - More vibrant
  static const Color success = Color(0xFF00FF88); // Neon green
  static const Color error = Color(0xFFFF3366); // Vibrant red-pink
  static const Color warning = Color(0xFFFFB84D); // Warm orange
  static const Color info = Color(0xFF00D9FF); // Cyan

  // Disabled Colors
  static const Color disabledGrey = Color(0xFFC0C0C0);
}
