import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Cloud {
  const _Cloud({
    required this.position,
    required this.scale,
    required this.driftSpeed,
  });

  final Offset position; // fractional (0..1) within the scene, top area only
  final double scale;

  /// Fraction of scene width drifted per second — slow and barely
  /// noticeable, just enough to keep the sky from feeling static.
  final double driftSpeed;
}

/// A handful of simple fixed (seeded) puffy clouds for daytime — the
/// counterpart to StarsPainter at night. Dawn/dusk deliberately get
/// neither: they're brief transitional bands, not their own "look".
class CloudsPainter extends CustomPainter {
  const CloudsPainter({required this.elapsedSeconds});

  final double elapsedSeconds;

  static final List<_Cloud> _clouds = List.generate(4, (i) {
    final rnd = math.Random(i * 53 + 7);
    return _Cloud(
      position: Offset(rnd.nextDouble(), 0.08 + rnd.nextDouble() * 0.22),
      scale: 0.7 + rnd.nextDouble() * 0.6,
      driftSpeed: 0.006 + rnd.nextDouble() * 0.008,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);

    for (final cloud in _clouds) {
      // Drifts left-to-right and wraps around, using modulo on a
      // continuously-increasing time value — same "never resets" approach
      // as the star twinkle, so there's no jump when it wraps.
      final dx = (cloud.position.dx + elapsedSeconds * cloud.driftSpeed) % 1.2 - 0.1;
      final center = Offset(dx * size.width, cloud.position.dy * size.height);
      _drawPuff(canvas, center, cloud.scale * size.width * 0.09, paint);
    }
  }

  void _drawPuff(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center + Offset(-radius * 0.9, radius * 0.15), radius * 0.65, paint);
    canvas.drawCircle(center + Offset(radius * 0.9, radius * 0.15), radius * 0.65, paint);
    canvas.drawCircle(center, radius * 0.85, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * 0.35),
        width: radius * 2.6,
        height: radius * 0.9,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CloudsPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds;
}
