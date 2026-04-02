import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Previous Rooms section - Only visible for registered users
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
              Icon(
                Icons.history,
                color: AppColors.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Previous Rooms',
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
                ? 'Login to see and rejoin your previous watch parties.'
                : 'View and rejoin your previous watch parties.',
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
        .limit(10);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: roomsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _EmptyState(showLoginHint: false);
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final roomId = data['roomId'] as String? ?? '';
            final name = data['name'] as String? ?? 'Watch Room';
            final videoUrl = data['videoUrl'] as String? ?? '';
            final isHost = data['isHost'] as bool? ?? false;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isHost ? Icons.star : Icons.play_circle_fill,
                color: AppColors.primaryAccent,
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
              subtitle: Text(
                videoUrl.isNotEmpty ? videoUrl : roomId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textWhite.withValues(alpha: 0.7)
                      : AppColors.textGrey,
                ),
              ),
              trailing: TextButton(
                onPressed: () {
                  if (roomId.isNotEmpty) {
                    context.go('/join/$roomId');
                  }
                },
                child: const Text('Rejoin'),
              ),
            );
          },
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
            'No previous rooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showLoginHint
                ? 'Sign in and create or join rooms to see them here.'
                : 'Create or join a room to get started!',
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

