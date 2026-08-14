import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time_of_day/providers/time_of_day_providers.dart';
import '../../../core/time_of_day/time_of_day_band.dart';
import '../../creatures/providers/creature_providers.dart';
import '../../creatures/widgets/creature_reveal.dart';
import '../../narrator/providers/narrator_providers.dart';
import '../painters/stars_painter.dart';
import '../painters/water_painter.dart';
import '../providers/flood_providers.dart';

/// Fixed light text color, independent of the app's Light/Dark/System
/// chrome theme — see the matching note in CreatureReveal.
const _onSceneText = Color(0xFFF5F7FF);

/// The core-loop visual: a flood that recedes as today's water goal is
/// logged, revealing the day's creature, narrated by the sarcastic
/// narrator voice, under a sky that shifts with the time of day. Every
/// color in this scene is fixed rather than theme-driven — the sky/water
/// already have their own always-moody palette, independent of the
/// user's Light/Dark/System chrome preference (see PRD.md's Time of Day
/// & Theming section on why these two axes stay decoupled).
class FloodScene extends ConsumerStatefulWidget {
  const FloodScene({super.key});

  @override
  ConsumerState<FloodScene> createState() => _FloodSceneState();
}

class _FloodSceneState extends ConsumerState<FloodScene>
    with SingleTickerProviderStateMixin {
  // A raw Ticker driving continuously-increasing elapsed time, rather than
  // a bounded AnimationController that resets to 0 every cycle — a
  // multi-frequency wave built on a value that resets doesn't complete a
  // whole cycle at the reset point, which is what caused the visible
  // "jump" in the water animation. Elapsed time here never resets, so
  // there's nothing to jump.
  final ValueNotifier<double> _elapsedSeconds = ValueNotifier(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _elapsedSeconds.value = elapsed.inMicroseconds / 1e6;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsedSeconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(floodLevelProvider);
    final creature = ref.watch(creatureOfTheDayProvider);
    final mood = ref.watch(moodBandProvider);
    final narratorLine = ref.watch(currentNarratorLineProvider);
    final band = ref.watch(timeOfDayBandProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        height: 420,
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _skyColors(band),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _starOpacity(band),
              child: ValueListenableBuilder<double>(
                valueListenable: _elapsedSeconds,
                builder: (context, elapsedSeconds, _) =>
                    CustomPaint(painter: StarsPainter(elapsedSeconds: elapsedSeconds)),
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _elapsedSeconds,
              builder: (context, elapsedSeconds, _) => CustomPaint(
                painter: WaterPainter(
                  level: level,
                  phase: elapsedSeconds * (2 * math.pi / 6),
                ),
              ),
            ),
            Center(child: CreatureReveal(creature: creature, mood: mood)),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                narratorLine,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _onSceneText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _skyColors(TimeOfDayBand band) {
    switch (band) {
      case TimeOfDayBand.dawn:
        return const [Color(0xFF3A2A40), Color(0xFF7A4B4B)];
      case TimeOfDayBand.day:
        return const [Color(0xFF1B3A4B), Color(0xFF2E5F73)];
      case TimeOfDayBand.dusk:
        return const [Color(0xFF2A1B3A), Color(0xFF8A4B3A)];
      case TimeOfDayBand.night:
        return const [Color(0xFF05070F), Color(0xFF0B1220)];
    }
  }

  double _starOpacity(TimeOfDayBand band) {
    switch (band) {
      case TimeOfDayBand.night:
        return 1.0;
      case TimeOfDayBand.dawn:
      case TimeOfDayBand.dusk:
        return 0.4;
      case TimeOfDayBand.day:
        return 0.0;
    }
  }
}
