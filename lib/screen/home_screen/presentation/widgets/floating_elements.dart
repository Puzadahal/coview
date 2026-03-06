import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Floating sync icons and chat bubbles that pulse and drift.
class FloatingElements extends StatefulWidget {
  const FloatingElements({super.key});

  @override
  State<FloatingElements> createState() => _FloatingElementsState();
}

class _FloatingElementsState extends State<FloatingElements>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      8,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: 3000 + (index * 500),
        ),
      ),
    );
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 2 * math.pi).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (var controller in _controllers) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating sync icons
        ...List.generate(4, (index) {
          return Positioned(
            left: (index % 2 == 0) ? 20.0 : null,
            right: (index % 2 == 1) ? 20.0 : null,
            top: 100.0 + (index * 120.0),
            child: AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                final offset = math.sin(_animations[index].value) * 20;
                final opacity = 0.3 + (math.sin(_animations[index].value) * 0.2);
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Opacity(
                    opacity: opacity,
                    child: Icon(
                      Icons.sync,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          );
        }),
        // Floating chat bubbles
        ...List.generate(4, (index) {
          return Positioned(
            left: (index % 2 == 0) ? 40.0 : null,
            right: (index % 2 == 1) ? 40.0 : null,
            bottom: 150.0 + (index * 100.0),
            child: AnimatedBuilder(
              animation: _animations[index + 4],
              builder: (context, child) {
                final offset = math.cos(_animations[index + 4].value) * 15;
                final opacity = 0.2 + (math.cos(_animations[index + 4].value) * 0.15);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
