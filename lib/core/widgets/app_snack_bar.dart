import 'package:flutter/material.dart';

import '../../config/colors/app_colors.dart';

enum AppSnackBarType { success, error, info }

class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    Widget? icon,
  }) {
    final color = switch (type) {
      AppSnackBarType.success => Colors.green,
      AppSnackBarType.error => Colors.red,
      AppSnackBarType.info => AppColors.secondary,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: color,
        content: icon == null
            ? Text(message)
            : Row(
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppSnackBarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppSnackBarType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: AppSnackBarType.info);
}
