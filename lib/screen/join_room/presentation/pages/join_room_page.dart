import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../config/colors/app_colors.dart';
import '../../../../core/widgets/app_back_app_bar.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/bloc/join_room_bloc.dart';
import '../../domain/bloc/join_room_event.dart';
import '../../domain/bloc/join_room_state.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({super.key});

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<JoinRoomBloc>().add(const JoinRoomSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.primaryDark
          : AppColors.lightBackground,
      appBar: const AppBackAppBar(
        title: 'Join Existing Room',
        transparent: true,
      ),
      body: BlocListener<JoinRoomBloc, JoinRoomState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == JoinRoomStatus.success,
        listener: (context, state) async {
          final roomId = state.resolvedRoomId;
          if (roomId != null && roomId.isNotEmpty) {
            final user = fb.FirebaseAuth.instance.currentUser;
            if (user != null) {
              try {
                final firestore = FirebaseFirestore.instance;
                final roomDoc = await firestore
                    .collection('rooms')
                    .doc(roomId)
                    .get();
                final data = roomDoc.data() ?? {};
                await firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('rooms')
                    .doc(roomId)
                    .set({
                      'roomId': roomId,
                      'name': (data['name'] as String?) ?? 'Watch Room',
                      'videoUrl': (data['videoUrl'] as String?) ?? '',
                      'isHost': data['hostId'] == user.uid,
                      'lastJoinedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
              } catch (e, st) {
                debugPrint(
                  'JoinRoom: could not save user room history: $e\n$st',
                );
              }
            }

            if (!mounted) return;
            this.context.go('/join/$roomId');
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: BlocBuilder<JoinRoomBloc, JoinRoomState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter Invite Link or Room Code',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingMedium),
                      Text(
                        'Paste the Coview invite link you received, or type the room code shared by your host.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textWhite.withValues(alpha: 0.8)
                              : AppColors.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spacingLarge),
                      TextField(
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'https://syncview.app/join/room_1234abcd or room_1234abcd',
                          prefixIcon: const Icon(Icons.link),
                          errorText: state.error,
                        ),
                        onChanged: (value) {
                          context.read<JoinRoomBloc>().add(
                            JoinRoomInputChanged(value),
                          );
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppConstants.spacingLarge),
                      CustomButton(
                        text: 'Join Room',
                        isLoading: false,
                        onPressed: state.canSubmit ? _submit : null,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
