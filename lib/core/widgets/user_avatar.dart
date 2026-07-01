import 'package:flutter/material.dart';

import '../../config/colors/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final double iconSize;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 20,
    this.backgroundColor = AppColors.primaryAccent,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPhotoUrl = photoUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundImage: trimmedPhotoUrl == null || trimmedPhotoUrl.isEmpty
          ? null
          : NetworkImage(trimmedPhotoUrl),
      onForegroundImageError: trimmedPhotoUrl == null || trimmedPhotoUrl.isEmpty
          ? null
          : (_, _) {},
      child: Icon(Icons.person, size: iconSize, color: AppColors.textWhite),
    );
  }
}
