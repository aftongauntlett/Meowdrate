import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fixed water color, independent of the app's Light/Dark/System chrome
/// theme — see the matching note in FloodScene.
const _waterColor = Color(0xFF6EE7FF);

/// Two overlaid sine waves standing in for the flood surface — no image
/// assets, just Canvas math. `level` is 1.0 (fully flooded) down to 0.0
/// (fully drained/cleared for the day).
class WaterPainter extends CustomPainter {
  const WaterPainter({required this.level, required this.phase});

  final double level;

  /// Advances over time (radians) to animate the swish.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final waterTop = size.height * (1 - level);

    _drawWave(
      canvas,
      size,
      baseY: waterTop,
      amplitude: 8,
      wavelength: size.width * 0.9,
      phaseOffset: phase,
      color: _waterColor.withValues(alpha: 0.28),
    );
    _drawWave(
      canvas,
      size,
      baseY: waterTop + 4,
      amplitude: 6,
      wavelength: size.width * 0.55,
      phaseOffset: phase * 1.3 + 1.5,
      color: _waterColor.withValues(alpha: 0.5),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double amplitude,
    required double wavelength,
    required double phaseOffset,
    required Color color,
  }) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseY);
    for (double x = 0; x <= size.width; x += 4) {
      final y = baseY + amplitude * math.sin((x / wavelength) * 2 * math.pi + phaseOffset);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.phase != phase;
}
