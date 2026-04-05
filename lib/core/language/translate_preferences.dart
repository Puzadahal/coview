import 'dart:ui';

import 'package:flutter_translate/flutter_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists locale using the same key as the former [AppLanguageCubit] (`app_language`).
class SharedTranslatePreferences implements ITranslatePreferences {
  static const _key = 'app_language';

  @override
  Future<Locale?> getPreferredLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == null || code.isEmpty) return null;
    return localeFromString(code);
  }

  @override
  Future<void> savePreferredLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, localeToString(locale));
  }
}
