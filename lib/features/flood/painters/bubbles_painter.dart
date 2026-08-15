import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Bubble {
  const _Bubble({
    required this.dx,
    required this.startDepth,
    required this.riseSpeed,
    required this.radius,
    required this.wobbleSpeed,
    required this.wobbleAmount,
  });

  /// Fractional horizontal position (0..1) within the scene.
  final double dx;

  /// Fractional depth (0 at the water surface, 1 at the scene floor) this
  /// bubble starts at, so bubbles don't all rise in lockstep.
  final double startDepth;

  /// Fraction of the water column risen per second.
  final double riseSpeed;
  final double radius;
  final double wobbleSpeed;
  final double wobbleAmount;
}

/// A handful of small bubbles slowly rising through the flood water, giving
/// the flat WaterPainter fill some life. Position is expressed as a
/// fraction of the *current water column* (between the wave surface and the
/// scene floor) rather than absolute pixels, so bubbles stay inside the
/// water as it drains instead of drifting into the sky above it.
class BubblesPainter extends CustomPainter {
  const BubblesPainter({required this.elapsedSeconds, required this.level});

  final double elapsedSeconds;

  /// 1.0 (fully flooded) down to 0.0 (fully drained) — matches WaterPainter.
  final double level;

  static final List<_Bubble> _bubbles = List.generate(7, (i) {
    final rnd = math.Random(i * 29 + 11);
    return _Bubble(
      dx: 0.1 + rnd.nextDouble() * 0.8,
      startDepth: rnd.nextDouble(),
      riseSpeed: 0.03 + rnd.nextDouble() * 0.03,
      radius: 2.5 + rnd.nextDouble() * 3,
      wobbleSpeed: 0.5 + rnd.nextDouble() * 0.7,
      wobbleAmount: 3 + rnd.nextDouble() * 4,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;

    final waterTop = size.height * (1 - level);
    final columnHeight = size.height - waterTop;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final bubble in _bubbles) {
      // Depth counts down from 1 (floor) to 0 (surface) and wraps, so the
      // bubble resets to the floor and starts rising again once it pops.
      final depth = (bubble.startDepth - elapsedSeconds * bubble.riseSpeed) % 1.0;
      final wobble = math.sin(elapsedSeconds * bubble.wobbleSpeed + bubble.startDepth * 10) *
          bubble.wobbleAmount;

      final y = waterTop + depth * columnHeight;
      final x = bubble.dx * size.width + wobble;

      // Fade in just off the floor and fade out just before reaching the
      // surface, so the wrap-around reset is never visibly a pop-in/pop-out.
      final fadeIn = (depth / 0.15).clamp(0.0, 1.0);
      final fadeOut = ((1 - depth) / 0.1).clamp(0.0, 1.0);
      final alpha = 0.5 * math.min(fadeIn, fadeOut);
      if (alpha <= 0) continue;

      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BubblesPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds || oldDelegate.level != level;
}
