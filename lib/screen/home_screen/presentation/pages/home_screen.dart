import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/bloc/home_bloc.dart';
import '../../domain/bloc/home_event.dart';
import '../../domain/bloc/home_state.dart';
import '../widgets/video_background.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/trust_indicators.dart';
import '../widgets/floating_elements.dart';
import '../widgets/previous_rooms_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(const HomeInitialized()),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return VideoBackground(
            // TODO: Uncomment and add video when available:
            // videoPath: 'assets/videos/home_background.mp4',
            child: Stack(
          children: [
            // Floating animated elements
            const FloatingElements(),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Hero Section
                      HeroSection(
                        onStartWatching: () {
                          context.go('/create-room');
                        },
                        onCreateRoom: () {
                          context.go('/create-room');
                        },
                      ),
                      const SizedBox(height: 80),
                      // Features Section
                      const FeaturesSection(),
                      const SizedBox(height: 60),
                      // "Join Existing Room" CTA matching the flow chart
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<HomeBloc>().add(const JoinRoomPressed());
                            context.go('/join-room');
                          },
                          icon: const Icon(Icons.meeting_room_outlined),
                          label: const Text('Join Existing Room'),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Previous Rooms Section placeholder (for registered users)
                      const PreviousRoomsSection(),
                      const SizedBox(height: 60),
                      // Trust Indicators
                      const TrustIndicators(),
                      const SizedBox(height: 60),
                      // Bottom CTA
                      BlocBuilder<HomeBloc, HomeState>(
                        builder: (context, state) {
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.read<HomeBloc>().add(
                                        const CreateRoomPressed());
                                    context.go('/create-room');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00FF88), // Neon green
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 12,
                                    shadowColor: const Color(0xFF00FF88)
                                        .withValues(alpha: 0.5),
                                  ),
                                  child: const Text(
                                    'Get Started Now',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ),
        );
      },
    ),
    );
  }
}
