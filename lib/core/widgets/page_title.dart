import 'package:flutter/material.dart';
import '../../config/colors/app_colors.dart';
import '../constants/app_constants.dart';

class PageTitle extends StatelessWidget {
  final List<String> titleLines;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double spacing;

  const PageTitle({
    super.key,
    required this.titleLines,
    this.textColor,
    this.fontSize = AppConstants.fontSizeXXLarge,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 0.5,
    this.spacing = AppConstants.spacingXSmall,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = textColor ?? AppColors.textWhite;

    return Column(
      children: titleLines
          .map(
            (line) => Padding(
              padding: EdgeInsets.only(
                bottom: line == titleLines.last ? 0 : spacing,
              ),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: defaultTextColor,
                  letterSpacing: letterSpacing,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
