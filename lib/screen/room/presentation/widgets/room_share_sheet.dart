import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/colors/app_colors.dart';
import '../../data/room_share_recents_store.dart';

Future<void> showRoomShareSheet(
  BuildContext context, {
  required String roomName,
  required String shareBody,
  required String resolvedLink,
  required bool isFullUrl,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _RoomShareDialog(
      roomName: roomName,
      shareBody: shareBody,
      resolvedLink: resolvedLink,
      isFullUrl: isFullUrl,
    ),
  );
}

class _RoomShareDialog extends StatefulWidget {
  const _RoomShareDialog({
    required this.roomName,
    required this.shareBody,
    required this.resolvedLink,
    required this.isFullUrl,
  });

  final String roomName;
  final String shareBody;
  final String resolvedLink;
  final bool isFullUrl;

  @override
  State<_RoomShareDialog> createState() => _RoomShareDialogState();
}

class _RoomShareDialogState extends State<_RoomShareDialog> {
  List<RoomShareRecipient> _recipients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await RoomShareRecentsStore.load();
    if (mounted) {
      setState(() {
        _recipients = list;
        _loading = false;
      });
    }
  }

  Future<bool> _tryLaunchUris(List<Uri> uris) async {
    for (final u in uris) {
      try {
        final ok =
            await launchUrl(u, mode: LaunchMode.externalApplication);
        if (ok) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<void> _openWhatsAppWithText(String text, {String? phoneDigits}) async {
    final encoded = Uri.encodeComponent(text);
    final phone = phoneDigits;
    final hasPhone = phone != null && phone.isNotEmpty;
    if (kIsWeb) {
      final href = hasPhone
          ? 'https://wa.me/$phone?text=$encoded'
          : 'https://wa.me/?text=$encoded';
      await _launch(Uri.parse(href), fallbackCopy: text);
      return;
    }
    final native = hasPhone
        ? Uri.parse('whatsapp://send?phone=$phone&text=$encoded')
        : Uri.parse('whatsapp://send?text=$encoded');
    final https = hasPhone
        ? Uri.parse('https://wa.me/$phone?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');
    if (!await _tryLaunchUris([native]) && mounted) {
      await _launch(https, fallbackCopy: text);
    }
  }

  Future<void> _openMessenger() async {
    await Clipboard.setData(ClipboardData(text: widget.shareBody));
    if (!mounted) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invite copied. Open Messenger in another tab and paste.',
          ),
        ),
      );
      await _launch(
        Uri.parse('https://www.messenger.com/'),
        fallbackCopy: null,
      );
      return;
    }

    if (!widget.isFullUrl) {
      final opened = await _tryLaunchUris([
        Uri.parse('fb-messenger://'),
        Uri.parse('fb-messenger://thread'),
      ]);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invite copied. Open Messenger and paste (install the app for one-tap open).',
            ),
          ),
        );
        await _launch(
          Uri.parse('https://www.messenger.com/'),
          fallbackCopy: null,
        );
      }
      return;
    }

    final link = widget.resolvedLink;
    final opened = await _tryLaunchUris([
      Uri.parse(
        'fb-messenger://share?link=${Uri.encodeComponent(link)}',
      ),
    ]);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite copied. Opening Messenger in browser…'),
        ),
      );
      await _launch(
        Uri.parse('https://www.messenger.com/'),
        fallbackCopy: null,
      );
    }
  }

  Future<void> _openTelegram() async {
    final bodyEnc = Uri.encodeComponent(widget.shareBody);
    final urlParam = widget.isFullUrl
        ? Uri.encodeComponent(widget.resolvedLink)
        : '';

    if (kIsWeb) {
      await _launch(
        Uri.parse(
          'https://t.me/share/url?url=$urlParam&text=$bodyEnc',
        ),
        fallbackCopy: widget.shareBody,
      );
      return;
    }

    final opened = await _tryLaunchUris([
      Uri.parse('tg://msg?text=$bodyEnc'),
    ]);
    if (!opened && mounted) {
      await _launch(
        Uri.parse(
          'https://t.me/share/url?url=$urlParam&text=$bodyEnc',
        ),
        fallbackCopy: widget.shareBody,
      );
    }
  }

  Future<void> _openDiscord() async {
    await Clipboard.setData(ClipboardData(text: widget.shareBody));
    if (!mounted) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invite copied. Paste into Discord in the browser or desktop app.',
          ),
        ),
      );
      await _launch(
        Uri.parse('https://discord.com/channels/@me'),
        fallbackCopy: null,
      );
      return;
    }

    final opened = await _tryLaunchUris([
      Uri.parse('discord://'),
      Uri.parse('discord://-/'),
      Uri.parse('discord://channels/@me'),
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Invite copied — paste into a DM or channel in Discord.'
                : 'Invite copied. Install Discord or open the web app and paste.',
          ),
        ),
      );
    }
    if (!opened && mounted) {
      await _launch(
        Uri.parse('https://discord.com/channels/@me'),
        fallbackCopy: null,
      );
    }
  }

  Future<void> _openX() async {
    final url = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(widget.shareBody)}',
    );
    await _launch(url, fallbackCopy: widget.shareBody);
  }

  Future<void> _openEmail() async {
    final subject = Uri.encodeComponent('Join my Coview room: ${widget.roomName}');
    final body = Uri.encodeComponent(widget.shareBody);
    await _launch(
      Uri.parse('mailto:?subject=$subject&body=$body'),
      fallbackCopy: widget.shareBody,
    );
  }

  Future<void> _openSms() async {
    final body = Uri.encodeComponent(widget.shareBody);
    await _launch(Uri.parse('sms:?body=$body'), fallbackCopy: widget.shareBody);
  }

  Future<bool> _launch(Uri uri, {String? fallbackCopy}) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return true;
    } catch (_) {}
    if (fallbackCopy != null) {
      await Clipboard.setData(ClipboardData(text: fallbackCopy));
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard instead.')),
      );
    }
    return false;
  }

  Future<void> _copyInviteToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.shareBody));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite copied to clipboard.')),
    );
  }

  Future<void> _systemShare() async {
    final body = widget.shareBody;
    final subject = 'Join my Coview room: ${widget.roomName}';
    if (mounted) Navigator.pop(context);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: body,
          subject: subject,
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: body));
    }
  }

  Future<void> _addPerson() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add someone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Puza Dahal',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'WhatsApp number (optional)',
                hintText: 'Country code + number, no +',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final digits = RoomShareRecentsStore.normalizePhoneDigits(phoneCtrl.text);
    final r = RoomShareRecipient(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      phoneDigits: digits.isEmpty ? null : digits,
    );
    await RoomShareRecentsStore.upsert(r);
    await _reload();
  }

  Future<void> _onRecipientTap(RoomShareRecipient r) async {
    await RoomShareRecentsStore.touch(r.id);
    await _reload();
    if (r.phoneDigits != null && r.phoneDigits!.isNotEmpty) {
      await _openWhatsAppWithText(widget.shareBody, phoneDigits: r.phoneDigits);
    } else {
      await Clipboard.setData(ClipboardData(text: widget.shareBody));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite for ${r.name} copied to clipboard.')),
        );
      }
    }
  }

  Future<void> _removeRecipient(RoomShareRecipient r) async {
    await RoomShareRecentsStore.remove(r.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxW = 420.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: 560),
        child: Material(
          color: isDark ? AppColors.primaryDarkVariant : AppColors.lightSurface,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.ios_share, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Share room',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'People you invite often',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved on this device. Tap to send via WhatsApp (if number saved) or copy the invite.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      else if (_recipients.isEmpty)
                        Text(
                          'No saved contacts yet. Add someone you share rooms with often.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        )
                      else
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recipients.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final r = _recipients[i];
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  InkWell(
                                    onTap: () => _onRecipientTap(r),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 72,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            child: Text(
                                              r.name.isNotEmpty
                                                  ? r.name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: AppColors.textWhite,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            r.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _removeRecipient(r),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.primaryDark
                                                : AppColors.backgroundGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addPerson,
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text('Add someone'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Share using',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ShareOptionsGrid(
                        onWhatsApp: () =>
                            _openWhatsAppWithText(widget.shareBody),
                        onMessenger: _openMessenger,
                        onDiscord: _openDiscord,
                        onTelegram: _openTelegram,
                        onX: _openX,
                        onEmail: _openEmail,
                        onSms: _openSms,
                        onCopy: _copyInviteToClipboard,
                        onMore: _systemShare,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOptionsGrid extends StatelessWidget {
  const _ShareOptionsGrid({
    required this.onWhatsApp,
    required this.onMessenger,
    required this.onDiscord,
    required this.onTelegram,
    required this.onX,
    required this.onEmail,
    required this.onSms,
    required this.onCopy,
    required this.onMore,
  });

  final VoidCallback onWhatsApp;
  final VoidCallback onMessenger;
  final VoidCallback onDiscord;
  final VoidCallback onTelegram;
  final VoidCallback onX;
  final VoidCallback onEmail;
  final VoidCallback onSms;
  final VoidCallback onCopy;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final items = <_ShareItem>[
      _ShareItem('WhatsApp', const Color(0xFF25D366), Icons.chat_rounded,
          onWhatsApp),
      _ShareItem('Messenger', const Color(0xFF0084FF), Icons.send_rounded,
          onMessenger),
      _ShareItem(
        'Discord',
        const Color(0xFF5865F2),
        Icons.headset_mic_outlined,
        onDiscord,
      ),
      _ShareItem(
        'Telegram',
        const Color(0xFF0088CC),
        Icons.forum_outlined,
        onTelegram,
      ),
      _ShareItem(
        'X',
        themeColor(context, 0xFF000000),
        Icons.alternate_email,
        onX,
      ),
      _ShareItem(
        'Email',
        themeColor(context, 0xFF5F6368),
        Icons.email_outlined,
        onEmail,
      ),
      _ShareItem(
        'SMS',
        themeColor(context, 0xFF43A047),
        Icons.sms_outlined,
        onSms,
      ),
      _ShareItem(
        'Copy link',
        themeColor(context, 0xFF6C5CE7),
        Icons.link,
        onCopy,
      ),
      _ShareItem(
        'More',
        themeColor(context, 0xFF607D8B),
        Icons.more_horiz,
        onMore,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 360 ? 4 : 3;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children:
              items.map((item) => _ShareTile(item: item)).toList(growable: false),
        );
      },
    );
  }

  static Color themeColor(BuildContext context, int fallback) {
    final b = Theme.of(context).brightness == Brightness.dark;
    return b ? const Color(0xFFB0BEC5) : Color(fallback);
  }
}

class _ShareItem {
  _ShareItem(this.label, this.color, this.icon, this.onTap);
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.item});
  final _ShareItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
