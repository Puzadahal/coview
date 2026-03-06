import 'package:flutter/material.dart';
import '../../config/colors/app_colors.dart';
import '../constants/app_constants.dart';

class FormCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double topBorderRadius;
  final double bottomBorderRadius;
  final Color? backgroundColor;

  const FormCard({
    super.key,
    required this.children,
    this.padding,
    this.margin,
    this.topBorderRadius = AppConstants.borderRadiusXLarge,
    this.bottomBorderRadius = AppConstants.borderRadiusSmall,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topBorderRadius),
          topRight: Radius.circular(topBorderRadius),
          bottomLeft: Radius.circular(bottomBorderRadius),
          bottomRight: Radius.circular(bottomBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppConstants.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
