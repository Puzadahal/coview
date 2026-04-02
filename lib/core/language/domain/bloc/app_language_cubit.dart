import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageCubit extends Cubit<String> {
  AppLanguageCubit() : super('en');

  static const _languageKey = 'app_language';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey) ?? 'en';
    emit(saved);
  }

  Future<void> setLanguage(String languageCode) async {
    emit(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
}
