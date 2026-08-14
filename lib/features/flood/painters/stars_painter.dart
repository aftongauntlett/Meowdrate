import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Star {
  const _Star({
    required this.position,
    required this.outerRadius,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.twinkleAmount,
  });

  final Offset position; // fractional (0..1) within the scene
  final double outerRadius;
  final double twinkleSpeed;
  final double twinkleOffset;

  /// 0 = doesn't twinkle (steady), 1 = twinkles fully — varied per star so
  /// they don't all pulse in unison.
  final double twinkleAmount;
}

/// A handful of fixed (seeded, not random-per-frame) 4-pointed sparkle
/// shapes scattered across the top of the scene. Some twinkle, some stay
/// steady. Fading the whole layer in/out by time-of-day band is handled
/// by wrapping this in an AnimatedOpacity, not by this painter.
class StarsPainter extends CustomPainter {
  const StarsPainter({required this.elapsedSeconds});

  /// Continuously increasing — never resets — so twinkling never jumps.
  final double elapsedSeconds;

  static final List<_Star> _stars = List.generate(24, (i) {
    final rnd = math.Random(i * 97 + 13);
    return _Star(
      position: Offset(rnd.nextDouble(), rnd.nextDouble() * 0.55),
      outerRadius: 1.6 + rnd.nextDouble() * 1.8,
      twinkleSpeed: 0.6 + rnd.nextDouble() * 1.8,
      twinkleOffset: rnd.nextDouble() * 2 * math.pi,
      twinkleAmount: rnd.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final twinkle =
          0.5 + 0.5 * math.sin(elapsedSeconds * star.twinkleSpeed + star.twinkleOffset);
      final opacity = (1 - star.twinkleAmount * (1 - twinkle)).clamp(0.35, 1.0);

      _drawStar(
        canvas,
        Offset(star.position.dx * size.width, star.position.dy * size.height),
        star.outerRadius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double outerRadius, Paint paint) {
    final innerRadius = outerRadius * 0.42;
    final path = Path()
      ..moveTo(center.dx, center.dy - outerRadius)
      ..lineTo(center.dx + innerRadius, center.dy - innerRadius)
      ..lineTo(center.dx + outerRadius, center.dy)
      ..lineTo(center.dx + innerRadius, center.dy + innerRadius)
      ..lineTo(center.dx, center.dy + outerRadius)
      ..lineTo(center.dx - innerRadius, center.dy + innerRadius)
      ..lineTo(center.dx - outerRadius, center.dy)
      ..lineTo(center.dx - innerRadius, center.dy - innerRadius)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds;
}
