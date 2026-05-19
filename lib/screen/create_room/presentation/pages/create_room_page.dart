import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/glass_form_card.dart';
import '../../domain/bloc/create_room_bloc.dart';
import '../../domain/bloc/create_room_event.dart';
import '../../domain/bloc/create_room_state.dart';
import '../widgets/room_preview_card.dart';
import '../widgets/create_room_success_dialog.dart';

class CreateRoomPage extends StatelessWidget {
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateRoomBloc(),
      child: const _CreateRoomPageContent(),
    );
  }
}

class _CreateRoomPageContent extends StatelessWidget {
  const _CreateRoomPageContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Room'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: BlocListener<CreateRoomBloc, CreateRoomState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == CreateRoomStatus.success) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CreateRoomSuccessDialog(
                roomName: state.roomName,
                inviteLink: state.inviteLink ?? '',
                roomId: state.createdRoomId ?? '',
              ),
            );
          } else if (state.status == CreateRoomStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to create room'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLarge),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassFormCard(
                padding: const EdgeInsets.all(AppConstants.spacingXLarge),
                children: [
                  Column(
                    children: [
                      Text(
                        'Create Your Watch Room',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary,
                              AppColors.primaryAccent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  _RoomNameField(),
                  const SizedBox(height: 24),

                  _VideoUrlField(),
                  const SizedBox(height: 24),

                  BlocBuilder<CreateRoomBloc, CreateRoomState>(
                    buildWhen: (previous, current) =>
                        previous.isUrlValid != current.isUrlValid ||
                        previous.videoThumbnail != current.videoThumbnail,
                    builder: (context, state) {
                      if (state.isUrlValid && state.videoThumbnail != null) {
                        return Column(
                          children: [
                            RoomPreviewCard(
                              thumbnailUrl: state.videoThumbnail!,
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  _PrivacyToggle(),
                  const SizedBox(height: 24),

                  _AdvancedSettingsSection(),
                  const SizedBox(height: 32),

                  _LaunchPartyButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomNameField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CreateRoomBloc, CreateRoomState>(
      buildWhen: (previous, current) => previous.roomName != current.roomName,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Name',
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textWhite.withValues(alpha: 0.95)
                    : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                context.read<CreateRoomBloc>().add(RoomNameChanged(value));
              },
              decoration: InputDecoration(
                hintText: '',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textWhite.withValues(alpha: 0.5)
                      : AppColors.textGrey,
                ),
                prefixIcon: Icon(Icons.room, color: theme.colorScheme.primary),
                suffixIcon: state.roomName.trim().isNotEmpty
                    ? Icon(Icons.check_circle, color: AppColors.success)
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.primaryDarkVariant.withValues(alpha: 0.3)
                    : AppColors.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 15,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoUrlField extends StatefulWidget {
  @override
  State<_VideoUrlField> createState() => _VideoUrlFieldState();
}

class _VideoUrlFieldState extends State<_VideoUrlField> {
  late final TextEditingController _controller;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFile() async {
    try {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: const ['mp4', 'mkv', 'mov', 'avi', 'wmv', 'webm'],
      );
      final file = (picked != null && picked.files.isNotEmpty)
          ? picked.files.first
          : null;
      if (file == null) return;

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read file bytes for upload. Try a smaller file or paste a public URL.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });
      final publicUrl = await _uploadToStorage(file, bytes);

      if (!mounted) return;
      _controller.text = publicUrl;
      context.read<CreateRoomBloc>().add(VideoUrlChanged(publicUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload complete. Public link added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<String> _uploadToStorage(PlatformFile file, Uint8List bytes) async {
    var user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      final cred = await fb.FirebaseAuth.instance.signInAnonymously();
      user = cred.user;
    }
    if (user == null) {
      throw Exception('User auth unavailable for upload.');
    }

    final originalName = (file.name.isNotEmpty ? file.name : 'video.mp4')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ext = _extensionOf(originalName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'room_uploads/${user.uid}/$timestamp-${timestamp % 1000}.$ext';

    final metadata = SettableMetadata(
      contentType: _contentTypeForExtension(ext),
      customMetadata: {'originalName': originalName},
    );
    final ref = FirebaseStorage.instance.ref().child(storagePath);
    final task = ref.putData(bytes, metadata);

    task.snapshotEvents.listen((snapshot) {
      if (!mounted) return;
      final total = snapshot.totalBytes;
      if (total <= 0) return;
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / total;
      });
    });

    await task;
    return ref.getDownloadURL();
  }

  String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return 'mp4';
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case 'm3u8':
        return 'application/vnd.apple.mpegurl';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp4':
      default:
        return 'video/mp4';
    }
  }

  bool _isLocalPath(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return false;
    final uri = Uri.tryParse(raw);
    if (uri?.scheme == 'file') return true;
    if (RegExp(r'^[a-zA-Z]:\\').hasMatch(raw)) return true;
    return raw.startsWith('/') || raw.startsWith('./');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CreateRoomBloc, CreateRoomState>(
      buildWhen: (previous, current) =>
          previous.videoUrl != current.videoUrl ||
          previous.isUrlValid != current.isUrlValid,
      builder: (context, state) {
        if (_controller.text != state.videoUrl) {
          _controller.text = state.videoUrl;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video URL (Shareable Link)',
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textWhite.withValues(alpha: 0.95)
                    : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              onChanged: (value) {
                context.read<CreateRoomBloc>().add(VideoUrlChanged(value));
              },
              decoration: InputDecoration(
                hintText:
                    'Paste YouTube / Vimeo / Dailymotion / Twitch / direct HTTP video URL',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textWhite.withValues(alpha: 0.5)
                      : AppColors.textGrey,
                ),
                prefixIcon: Icon(Icons.link, color: theme.colorScheme.primary),
                suffixIcon: state.videoUrl.trim().isNotEmpty
                    ? state.isUrlValid
                          ? Icon(Icons.check_circle, color: AppColors.success)
                          : Icon(Icons.error, color: AppColors.error)
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.primaryDarkVariant.withValues(alpha: 0.3)
                    : AppColors.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 15,
              ),
            ),
            if (state.videoUrl.trim().isNotEmpty && !state.isUrlValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please enter a valid public HTTP(S) video URL (local file paths are not shareable).',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            if (state.videoUrl.trim().isNotEmpty &&
                _isLocalPath(state.videoUrl))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Local files work only on the host device. For shared playback, use a public URL.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () {
                        _pickVideoFile();
                      },
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.upload_file, color: theme.colorScheme.primary),
                label: Text(
                  _isUploading
                      ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                      : 'Upload Video',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CreateRoomBloc, CreateRoomState>(
      buildWhen: (previous, current) => previous.isPrivate != current.isPrivate,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryDarkVariant.withValues(alpha: 0.4)
                : AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    state.isPrivate ? Icons.lock : Icons.public,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Room Privacy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.isPrivate ? 'Private Room' : 'Public Room',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppColors.textWhite.withValues(alpha: 0.7)
                              : AppColors.textDark.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: state.isPrivate,
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  context.read<CreateRoomBloc>().add(
                    PrivacySettingChanged(value),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdvancedSettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CreateRoomBloc, CreateRoomState>(
      buildWhen: (previous, current) =>
          previous.isAdvancedSettingsExpanded !=
          current.isAdvancedSettingsExpanded,
      builder: (context, state) {
        return Column(
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<CreateRoomBloc>().add(
                  AdvancedSettingsToggled(!state.isAdvancedSettingsExpanded),
                );
              },
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryDarkVariant.withValues(alpha: 0.4)
                      : AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Advanced Settings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      state.isAdvancedSettingsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (state.isAdvancedSettingsExpanded) ...[
              const SizedBox(height: 16),
              _ParticipantLimitField(),
              const SizedBox(height: 16),
              _CommunicationOptions(),
            ],
          ],
        );
      },
    );
  }
}

class _ParticipantLimitField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CreateRoomBloc, CreateRoomState>(
      buildWhen: (previous, current) =>
          previous.participantLimit != current.participantLimit,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Participant Limit',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textWhite.withValues(alpha: 0.95)
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Max ${AppConstants.maxParticipantLimit}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'To ensure smooth performance, rooms are limited to ${AppConstants.maxParticipantLimit} participants',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textWhite.withValues(alpha: 0.6)
                    : AppColors.textGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed:
                      state.participantLimit > AppConstants.minParticipantLimit
                      ? () {
                          HapticFeedback.lightImpact();
                          context.read<CreateRoomBloc>().add(
                            ParticipantLimitChanged(state.participantLimit - 1),
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color:
                        state.participantLimit >
                            AppConstants.minParticipantLimit
                        ? theme.colorScheme.primary
                        : AppColors.disabledGrey,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${state.participantLimit} ${state.participantLimit == 1 ? 'person' : 'people'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textDark,
                        ),
                      ),
                      if (state.participantLimit >=
                          AppConstants.maxParticipantLimit)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 12,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Maximum limit reached',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      state.participantLimit < AppConstants.maxParticipantLimit
                      ? () {
                          HapticFeedback.lightImpact();
                          context.read<CreateRoomBloc>().add(
                            ParticipantLimitChanged(state.participantLimit + 1),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: AppColors.textWhite,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Maximum ${AppConstants.maxParticipantLimit} participants allowed to ensure optimal performance',
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.warning,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  icon: Icon(
                    Icons.add_circle_outline,
                    color:
                        state.participantLimit <
                            AppConstants.maxParticipantLimit
                        ? theme.colorScheme.primary
                        : AppColors.disabledGrey,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CommunicationOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CreateRoomBloc, CreateRoomState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication Options',
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textWhite.withValues(alpha: 0.95)
                    : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _CommunicationToggle(
              icon: Icons.chat_bubble_outline,
              title: 'Text Chat',
              value: state.textChatEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                context.read<CreateRoomBloc>().add(
                  TextChatEnabledChanged(value),
                );
              },
            ),
            const SizedBox(height: 12),
            _CommunicationToggle(
              icon: Icons.mic_outlined,
              title: 'Voice Chat',
              value: state.voiceChatEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                context.read<CreateRoomBloc>().add(
                  VoiceChatEnabledChanged(value),
                );
              },
            ),
            const SizedBox(height: 12),
            _CommunicationToggle(
              icon: Icons.video_call_outlined,
              title: 'Video Call',
              value: state.videoCallEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                context.read<CreateRoomBloc>().add(
                  VideoCallEnabledChanged(value),
                );
              },
            ),
            const SizedBox(height: 12),
            _CommunicationToggle(
              icon: Icons.videocam_outlined,
              title: 'Video Bubbles',
              value: state.videoBubblesEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                context.read<CreateRoomBloc>().add(
                  VideoBubblesEnabledChanged(value),
                );
              },
            ),
            const SizedBox(height: 12),
            _CommunicationToggle(
              icon: Icons.security_outlined,
              title: 'Sensitive Words Filter',
              value: state.sensitiveWordsFilterEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                context.read<CreateRoomBloc>().add(
                  SensitiveWordsFilterChanged(value),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CommunicationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CommunicationToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDarkVariant.withValues(alpha: 0.2)
            : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textWhite : AppColors.textDark,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LaunchPartyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateRoomBloc, CreateRoomState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isFormValid != current.isFormValid,
      builder: (context, state) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: state.isFormValid ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: state.isFormValid
                      ? LinearGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.primaryAccent,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                  boxShadow: state.isFormValid
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed:
                      state.isFormValid &&
                          state.status != CreateRoomStatus.loading
                      ? () {
                          HapticFeedback.mediumImpact();
                          context.read<CreateRoomBloc>().add(
                            const CreateRoomButtonPressed(),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isFormValid
                        ? Colors.transparent
                        : AppColors.disabledGrey,
                    foregroundColor: state.isFormValid
                        ? AppColors.textWhite
                        : AppColors.textGrey,
                    disabledBackgroundColor: AppColors.disabledGrey,
                    disabledForegroundColor: AppColors.textGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusLarge,
                      ),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: state.status == CreateRoomStatus.loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textWhite,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              size: 26,
                              color: state.isFormValid
                                  ? AppColors.textWhite
                                  : AppColors.textGrey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Create Room',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
