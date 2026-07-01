import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String fallbackRoute;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool transparent;

  const AppBackAppBar({
    super.key,
    required this.title,
    this.fallbackRoute = '/home',
    this.backgroundColor,
    this.foregroundColor,
    this.transparent = false,
  });

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: transparent ? Colors.transparent : backgroundColor,
      foregroundColor: foregroundColor,
      elevation: transparent ? 0 : null,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _onBack(context),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
