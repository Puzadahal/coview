import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coview/config/routes/app_router.dart';
import 'package:coview/config/theme/app_theme.dart';
import 'package:coview/core/language/domain/bloc/app_language_cubit.dart';
import 'package:coview/core/theme/domain/bloc/theme_bloc.dart';
import 'package:coview/core/theme/domain/bloc/theme_event.dart';
import 'package:coview/core/theme/domain/bloc/theme_state.dart';
import 'package:coview/firebase_options.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ThemeBloc()..add(const ThemeInitialized()),
        ),
        BlocProvider(
          create: (context) => AppLanguageCubit()..initialize(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'SyncView',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.flutterThemeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
