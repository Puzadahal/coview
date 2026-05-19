import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class PreviousRoomsSection extends StatelessWidget {
  const PreviousRoomsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = fb.FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDarkVariant.withValues(alpha: 0.5)
            : AppColors.backgroundWhite.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primaryAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Recent Room',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user == null
                ? 'Sign in to jump back into your latest watch party.'
                : 'Your most recently joined room — tap Rejoin to continue.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textWhite.withValues(alpha: 0.7)
                  : AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 20),
          if (user == null)
            const _EmptyState(showLoginHint: true)
          else
            _RoomsList(userId: user.uid),
        ],
      ),
    );
  }
}

class _RoomsList extends StatelessWidget {
  final String userId;

  const _RoomsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .orderBy('lastJoinedAt', descending: true)
        .limit(1);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: roomsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _EmptyState(showLoginHint: false);
        }

        final data = snapshot.data!.docs.first.data();
        final roomId = data['roomId'] as String? ?? '';
        final name = data['name'] as String? ?? 'Watch Room';
        final videoUrl = data['videoUrl'] as String? ?? '';
        final isHost = data['isHost'] as bool? ?? false;
        final subtitle = videoUrl.isNotEmpty
            ? videoUrl
            : (roomId.isNotEmpty ? '#$roomId' : '');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: roomId.isNotEmpty ? () => context.go('/join/$roomId') : null,
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isHost
                          ? Icons.star_rounded
                          : Icons.play_circle_fill_rounded,
                      color: AppColors.primaryAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                            if (isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Host',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textWhite
                                        : AppColors.textDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textWhite.withValues(alpha: 0.65)
                                : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: roomId.isNotEmpty
                        ? () => context.go('/join/$roomId')
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Rejoin'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showLoginHint;

  const _EmptyState({required this.showLoginHint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: AppColors.primaryAccent.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent room',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showLoginHint
                ? 'Sign in and create or join a room — your latest one will appear here.'
                : 'Create or join a room — your most recent session will show here.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textWhite.withValues(alpha: 0.6)
                  : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
