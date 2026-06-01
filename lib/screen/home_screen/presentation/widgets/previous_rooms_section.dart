import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_translate/flutter_translate.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class PreviousRoomsSection extends StatelessWidget {
  const PreviousRoomsSection({super.key});

  static const int _maxRooms = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = fb.FirebaseAuth.instance.currentUser;

    return Container(
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
                translate('recentRoomsTitle'),
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
                ? translate('recentRoomsLoginHint')
                : translate('recentRoomsSub'),
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
    final roomsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('rooms')
        .orderBy('lastJoinedAt', descending: true)
        .limit(PreviousRoomsSection._maxRooms);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: roomsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _EmptyState(showLoginHint: false);
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _RoomCard(data: docs[index].data());
            },
          ),
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RoomCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomId = data['roomId'] as String? ?? '';
    final name = data['name'] as String? ?? 'Watch Room';
    final videoUrl = data['videoUrl'] as String? ?? '';
    final isHost = data['isHost'] as bool? ?? false;
    final subtitle = videoUrl.isNotEmpty
        ? videoUrl
        : (roomId.isNotEmpty ? '#$roomId' : '');

    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: roomId.isNotEmpty ? () => context.go('/join/$roomId') : null,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isHost
                        ? Icons.star_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.primaryAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textWhite
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isHost)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Host',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textWhite.withValues(alpha: 0.65)
                              : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.secondary.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
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
            size: 48,
            color: AppColors.primaryAccent.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            translate('recentRoomsEmpty'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            showLoginHint
                ? translate('recentRoomsLoginHint')
                : translate('recentRoomsEmptyHint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
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
