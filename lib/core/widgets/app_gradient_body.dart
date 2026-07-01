import 'package:flutter/material.dart';

import '../../config/colors/app_colors.dart';

class AppGradientBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppGradientBody({
    super.key,
    required this.child,
    this.padding,
  });

  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryDark, Color(0xFF14183A)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _gradient),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}
