import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';

import '../../config/colors/app_colors.dart';
import '../constants/app_constants.dart';

class NoInternetScreen extends StatefulWidget {
  final Future<void> Function() onRetry;

  const NoInternetScreen({super.key, required this.onRetry});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, Color(0xFF14183A)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F8FB), Color(0xFFDFE6EF)],
          );

    return Material(
      color: isDark ? AppColors.primaryDark : const Color(0xFFEDF1F6),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DizzyFaceIllustration(
                  color: onSurface.withValues(alpha: isDark ? 0.55 : 0.45),
                ),
                const SizedBox(height: 48),
                Text(
                  translate('noInternetTitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  translate('noInternetMessage'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 36),
                _RetryButton(
                  label: translate('tryAgain'),
                  loading: _retrying,
                  onPressed: _handleRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _RetryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.colorScheme.primary : const Color(0xFF6B7280);
    final foregroundColor = isDark
        ? theme.colorScheme.onPrimary
        : AppColors.textWhite;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusXLarge),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}

class _DizzyFaceIllustration extends StatelessWidget {
  final Color color;

  const _DizzyFaceIllustration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 180,
      child: CustomPaint(
        painter: _DizzyFacePainter(color: color),
      ),
    );
  }
}

class _DizzyFacePainter extends CustomPainter {
  final Color color;

  _DizzyFacePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final headRadius = size.width * 0.28;
    final headCenter = Offset(centerX, size.height * 0.52);

    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.86),
        width: headRadius * 1.6,
        height: headRadius * 0.32,
      ),
      shadowPaint,
    );

    canvas.drawCircle(headCenter, headRadius, stroke);

    final eyeOffsetX = headRadius * 0.42;
    final eyeY = headCenter.dy - headRadius * 0.12;
    const eyeSize = 6.0;
    _drawX(canvas, Offset(headCenter.dx - eyeOffsetX, eyeY), eyeSize, stroke);
    _drawX(canvas, Offset(headCenter.dx + eyeOffsetX, eyeY), eyeSize, stroke);

    canvas.drawCircle(
      Offset(headCenter.dx, headCenter.dy + headRadius * 0.42),
      4.5,
      fill,
    );

    final steamPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final topY = headCenter.dy - headRadius - size.height * 0.14;
    _drawWave(canvas, Offset(centerX - 12, topY), size.height * 0.12, steamPaint);
    _drawWave(canvas, Offset(centerX + 12, topY), size.height * 0.12, steamPaint);
  }

  void _drawX(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(
      center.translate(-size, -size),
      center.translate(size, size),
      paint,
    );
    canvas.drawLine(
      center.translate(size, -size),
      center.translate(-size, size),
      paint,
    );
  }

  void _drawWave(Canvas canvas, Offset start, double height, Paint paint) {
    final path = Path()..moveTo(start.dx, start.dy);
    const amplitude = 6.0;
    const segments = 3;
    final segHeight = height / segments;
    for (var i = 0; i < segments; i++) {
      final dir = i.isEven ? 1 : -1;
      final controlX = start.dx + amplitude * dir;
      final startY = start.dy + segHeight * i;
      final endY = start.dy + segHeight * (i + 1);
      path.quadraticBezierTo(
        controlX,
        (startY + endY) / 2,
        start.dx,
        endY,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DizzyFacePainter oldDelegate) =>
      oldDelegate.color != color;
}
