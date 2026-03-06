import 'package:flutter/material.dart';
import '../../../../config/colors/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// "SyncView" logo that subtly glows/pulses in sync with keystrokes (kinetic typography).
class KineticLogo extends StatefulWidget {
  /// Trigger glow when this value changes (e.g. length of email or name).
  final int keystrokeTrigger;

  const KineticLogo({
    super.key,
    this.keystrokeTrigger = 0,
  });

  @override
  State<KineticLogo> createState() => _KineticLogoState();
}

class _KineticLogoState extends State<KineticLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(KineticLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keystrokeTrigger != widget.keystrokeTrigger &&
        widget.keystrokeTrigger > 0) {
      _pulseController.forward(from: 0);
      _pulseController.reverse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Text(
            'SyncView',
            style: TextStyle(
              fontSize: AppConstants.fontSizeXXLarge + 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppColors.textWhite,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: _pulseAnimation.value * 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
