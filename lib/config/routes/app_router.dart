import 'package:go_router/go_router.dart';
import '../../screen/splashscreen/presentation/pages/splash_screen.dart';
import '../../screen/auth/presentation/pages/login_page.dart';
import '../../screen/auth/presentation/pages/signup_page.dart';
import '../../screen/auth/presentation/pages/auth_choice_page.dart';
import '../../screen/home_screen/presentation/pages/home_screen.dart';
import '../../screen/profile/presentation/pages/profile_page.dart';
import '../../screen/create_room/presentation/pages/create_room_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screen/room/presentation/pages/room_page.dart';
import '../../screen/join_room/presentation/pages/join_room_page.dart';
import '../../screen/room/domain/bloc/room_bloc.dart';
import '../../screen/room/domain/bloc/room_event.dart';
import '../../screen/join_room/domain/bloc/join_room_bloc.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth-choice',
      builder: (context, state) => const AuthChoicePage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final hostName = state.uri.queryParameters['hostName'] ?? '';
        final hostAvatar = state.uri.queryParameters['hostAvatar'] ?? '';
        return LoginPage(
          inviteHostName: hostName.isEmpty ? null : hostName,
          inviteHostAvatar: hostAvatar.isEmpty ? null : hostAvatar,
        );
      },
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/create-room',
      name: 'create-room',
      builder: (context, state) => const CreateRoomPage(),
    ),
    GoRoute(
      path: '/join-room',
      name: 'join-room-form',
      builder: (context, state) => BlocProvider(
        create: (_) => JoinRoomBloc(),
        child: const JoinRoomPage(),
      ),
    ),
    GoRoute(
      path: '/join/:roomId',
      name: 'join-room',
      builder: (context, state) {
        final roomId = state.pathParameters['roomId'] ?? '';
        return BlocProvider(
          create: (_) => RoomBloc(roomId)..add(const RoomInitialized()),
          child: RoomPage(roomId: roomId),
        );
      },
    ),
  ],
);
