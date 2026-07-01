import 'package:flutter/material.dart';

import '../../config/colors/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 48),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
