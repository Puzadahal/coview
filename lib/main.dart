import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:coview/config/routes/app_router.dart';
import 'package:coview/config/theme/app_theme.dart';
import 'package:coview/core/connectivity/connectivity_service.dart';
import 'package:coview/core/language/translate_preferences.dart';
import 'package:coview/core/notifications/notification_service.dart';
import 'package:coview/core/theme/domain/bloc/theme_bloc.dart';
import 'package:coview/core/theme/domain/bloc/theme_event.dart';
import 'package:coview/core/theme/domain/bloc/theme_state.dart';
import 'package:coview/core/widgets/no_internet_screen.dart';
import 'package:coview/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.initialize();
  unawaited(ConnectivityService.instance.initialize());

  final delegate = await LocalizationDelegate.create(
    fallbackLocale: 'en',
    supportedLocales: const ['en', 'ne', 'hi'],
    basePath: 'assets/i18n',
    preferences: SharedTranslatePreferences(),
  );

  // flutter_translate can leave _currentLocale unset if device locale loading
  // never calls changeLocale; MaterialApp then reads currentLocale and crashes
  // before the first frame (often seen as a black screen).
  try {
    final _ = delegate.currentLocale;
  } catch (_) {
    await delegate.changeLocale(delegate.fallbackLocale);
  }

  runApp(LocalizedApp(delegate, const CoviewAppEntry()));
}

class CoviewAppEntry extends StatelessWidget {
  const CoviewAppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationDelegate = LocalizedApp.of(context).delegate;

    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ThemeBloc()..add(const ThemeInitialized()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'SyncView',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.flutterThemeMode,
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                localizationDelegate,
              ],
              supportedLocales: localizationDelegate.supportedLocales,
              locale: localizationDelegate.currentLocale,
              routerConfig: appRouter,
              builder: (context, child) {
                return _ConnectivityGate(child: child ?? const SizedBox.shrink());
              },
            );
          },
        ),
      ),
    );
  }
}

/// Overlays [NoInternetScreen] on top of the whole app whenever the device
/// loses internet access, and removes it automatically when access returns.
class _ConnectivityGate extends StatelessWidget {
  final Widget child;

  const _ConnectivityGate({required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) {
        return Stack(
          children: [
            child,
            if (!isOnline)
              Positioned.fill(
                child: NoInternetScreen(
                  onRetry: ConnectivityService.instance.recheck,
                ),
              ),
          ],
        );
      },
    );
  }
}
