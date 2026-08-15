import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/creature.dart';
import '../models/mood_band.dart';

/// Slices and loops a horizontal pixel-art sprite strip (see Creature),
/// reacting to [mood]: which clip plays (for creatures with real
/// distinct mood art), how fast it animates, a tint, and a small idle
/// bounce when happy. Nearest-neighbor scaled so the pixel art stays
/// crisp.
class SpriteAnimation extends StatefulWidget {
  const SpriteAnimation({
    super.key,
    required this.creature,
    required this.mood,
    this.scale = 4,
    this.clipOverride,
  });

  final Creature creature;
  final MoodBand mood;
  final double scale;

  /// Plays this clip instead of `creature.clipFor(mood)` — mood still
  /// drives the tint/speed/bounce below. For a one-off animation (e.g. a
  /// screen-specific pose) that shouldn't change what the mood normally
  /// renders elsewhere.
  final SpriteClip? clipOverride;

  @override
  State<SpriteAnimation> createState() => _SpriteAnimationState();
}

class _SpriteAnimationState extends State<SpriteAnimation>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  String? _loadedAsset;
  int _frame = 0;
  double _elapsedSeconds = 0;
  late final Ticker _ticker;

  SpriteClip get _clip => widget.clipOverride ?? widget.creature.clipFor(widget.mood);

  @override
  void initState() {
    super.initState();
    _loadImage();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant SpriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_clip.spriteAsset != _loadedAsset) {
      _frame = 0;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final asset = _clip.spriteAsset;
    try {
      final data = await rootBundle.load('assets/$asset');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _image = frame.image;
          _loadedAsset = asset;
        });
      }
    } catch (_) {
      // Missing sprite: leave _image null, we just render an empty box.
    }
  }

  double get _speedFactor {
    switch (widget.mood) {
      case MoodBand.sad:
        return 1.6; // slower — heavy, unenthused
      case MoodBand.neutral:
        return 1.0;
      case MoodBand.happy:
        return 0.7; // quicker — perked up
    }
  }

  void _onTick(Duration elapsed) {
    _elapsedSeconds = elapsed.inMicroseconds / 1e6;
    final frameMs = (widget.creature.frameDuration.inMilliseconds * _speedFactor).round();
    final frame = (elapsed.inMilliseconds ~/ frameMs) % _clip.frameCount;
    if (frame != _frame || widget.mood == MoodBand.happy) {
      // Happy mode also drives a continuous bounce, so keep ticking even
      // when the frame index hasn't changed.
      setState(() => _frame = frame);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.creature.frameSize * widget.scale;
    final image = _image;
    final bounce = widget.mood == MoodBand.happy ? math.sin(_elapsedSeconds * 5) * 4 : 0.0;

    Widget sprite = SizedBox(
      width: size,
      height: size,
      child: image == null
          ? null
          : CustomPaint(
              painter: _SpriteFramePainter(
                image: image,
                frameIndex: _frame,
                frameCount: _clip.frameCount,
                frameSize: widget.creature.frameSize,
              ),
            ),
    );

    sprite = Transform.translate(offset: Offset(0, -bounce), child: sprite);

    final matrix = _moodColorMatrix(widget.mood);
    if (matrix != null) {
      sprite = ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: sprite);
    }
    return sprite;
  }

  List<double>? _moodColorMatrix(MoodBand mood) {
    switch (mood) {
      case MoodBand.neutral:
        return null;
      case MoodBand.sad:
        return _tintMatrix(saturation: 0.55, brightness: 0.8);
      case MoodBand.happy:
        return _tintMatrix(saturation: 1.0, brightness: 1.06);
    }
  }

  List<double> _tintMatrix({required double saturation, required double brightness}) {
    const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
    final sr = (1 - saturation) * lumR;
    final sg = (1 - saturation) * lumG;
    final sb = (1 - saturation) * lumB;
    return <double>[
      (sr + saturation) * brightness, sg * brightness, sb * brightness, 0, 0,
      sr * brightness, (sg + saturation) * brightness, sb * brightness, 0, 0,
      sr * brightness, sg * brightness, (sb + saturation) * brightness, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

class _SpriteFramePainter extends CustomPainter {
  const _SpriteFramePainter({
    required this.image,
    required this.frameIndex,
    required this.frameCount,
    required this.frameSize,
  });

  final ui.Image image;
  final int frameIndex;
  final int frameCount;
  final int frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final index = frameIndex.clamp(0, frameCount - 1);
    final src = Rect.fromLTWH(
      index * frameSize.toDouble(),
      0,
      frameSize.toDouble(),
      frameSize.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(covariant _SpriteFramePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.frameIndex != frameIndex ||
      oldDelegate.frameCount != frameCount;
}
