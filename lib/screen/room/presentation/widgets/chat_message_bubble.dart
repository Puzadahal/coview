import 'package:flutter/material.dart';

import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/bloc/room_state.dart';

typedef ReportMessageCallback = void Function(RoomMessage message);

class ChatMessageBubble extends StatelessWidget {
  final RoomMessage message;
  final bool isMe;
  final double maxWidth;
  final ReportMessageCallback? onReport;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.maxWidth,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: !isMe && onReport != null
                ? () => _showMessageActions(context)
                : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppConstants.borderRadiusMedium),
              topRight: const Radius.circular(AppConstants.borderRadiusMedium),
              bottomLeft: Radius.circular(
                isMe
                    ? AppConstants.borderRadiusMedium
                    : AppConstants.borderRadiusSmall,
              ),
              bottomRight: Radius.circular(
                isMe
                    ? AppConstants.borderRadiusSmall
                    : AppConstants.borderRadiusMedium,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMedium,
                vertical: AppConstants.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                  topRight: const Radius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                  bottomLeft: Radius.circular(
                    isMe
                        ? AppConstants.borderRadiusMedium
                        : AppConstants.borderRadiusSmall,
                  ),
                  bottomRight: Radius.circular(
                    isMe
                        ? AppConstants.borderRadiusSmall
                        : AppConstants.borderRadiusMedium,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          message.author,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isMe
                                ? AppColors.textWhite.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isMe && onReport != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => onReport!(message),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.flag_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    softWrap: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe
                          ? AppColors.textWhite
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Report message'),
              subtitle: Text(
                'From ${message.author}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(ctx);
                onReport?.call(message);
              },
            ),
          ],
        ),
      ),
    );
  }
}
