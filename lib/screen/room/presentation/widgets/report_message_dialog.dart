import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class ReportMessageDialog extends StatefulWidget {
  final String authorName;
  final String messagePreview;

  const ReportMessageDialog({
    super.key,
    required this.authorName,
    required this.messagePreview,
  });

  static Future<String?> show(
    BuildContext context, {
    required String authorName,
    required String messagePreview,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ReportMessageDialog(
        authorName: authorName,
        messagePreview: messagePreview,
      ),
    );
  }

  @override
  State<ReportMessageDialog> createState() => _ReportMessageDialogState();
}

class _ReportMessageDialogState extends State<ReportMessageDialog> {
  static const _reasons = [
    'Harassment or bullying',
    'Threats or violence',
    'Spam',
    'Inappropriate content',
    'Other',
  ];

  String _selected = _reasons.first;

  @override
  Widget build(BuildContext context) {
    final preview = widget.messagePreview.length > 80
        ? '${widget.messagePreview.substring(0, 80)}…'
        : widget.messagePreview;

    return AlertDialog(
      title: const Text('Report message'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report a message from ${widget.authorName}:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              '"$preview"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            ..._reasons.map(
              (reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  _selected == reason
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(reason),
                onTap: () => setState(() => _selected = reason),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Submit report'),
        ),
      ],
    );
  }
}
