import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_icon.dart';
import '../../../core/widgets/themed_card_decoration.dart';
import '../../creatures/creature_roster.dart';
import '../../creatures/models/mood_band.dart';
import '../../creatures/widgets/sprite_animation.dart';
import '../hydration_constants.dart';
import '../providers/hydration_providers.dart';

class DrinkMomentScreen extends ConsumerStatefulWidget {
  const DrinkMomentScreen({super.key});

  @override
  ConsumerState<DrinkMomentScreen> createState() => _DrinkMomentScreenState();
}

class _DrinkMomentScreenState extends ConsumerState<DrinkMomentScreen> {
  static const _songVolume = 0.5;

  late int _remainingSeconds = kDrinkMomentSeconds;
  Timer? _timer;
  AudioPlayer? _songPlayer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, kDrinkMomentSeconds);
      });
      if (_remainingSeconds == 0) {
        _timer?.cancel();
        // A straight stop() here was an abrupt cut — full volume to
        // silence in one frame, with nothing else on screen changing at
        // that exact instant to explain it. Fade instead.
        unawaited(_fadeOutSong());
      }
    });
    unawaited(_playSong());
  }

  // Runs on its own player rather than through SoundService, so a one-shot
  // SFX (e.g. drinkLogged when the user taps through) doesn't cut it off.
  // Same "missing/unplayable asset is skipped silently" tolerance as
  // SoundService — see assets/audio/README.md.
  Future<void> _playSong() async {
    try {
      final player = _songPlayer = AudioPlayer();
      await player.setVolume(_songVolume);
      await player.play(AssetSource('audio/drinkMomentSong.mp3'));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('DrinkMomentScreen: skipping song ($error)');
      }
    }
  }

  /// Ramps volume down over ~800ms instead of stopping outright. Reads
  /// [_songPlayer] fresh each step (rather than capturing it once) so a
  /// concurrent dispose() — e.g. the user tapping through mid-fade — just
  /// stops the loop the next time it checks, instead of calling into an
  /// already-disposed player.
  Future<void> _fadeOutSong() async {
    const steps = 8;
    const stepDuration = Duration(milliseconds: 100);
    for (var i = steps - 1; i >= 0; i--) {
      final player = _songPlayer;
      if (player == null) {
        return;
      }
      try {
        await player.setVolume(_songVolume * i / steps);
      } catch (_) {
        return;
      }
      await Future.delayed(stepDuration);
    }
    try {
      await _songPlayer?.stop();
    } catch (_) {
      // Already gone — fine, that's the goal either way.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _songPlayer?.dispose();
    super.dispose();
  }

  bool get _isComplete => _remainingSeconds == 0;

  // No longer gated on _isComplete — the countdown is a pace-setter, not
  // a lock. Someone who's already finished their sips shouldn't have to
  // stand around waiting for the number to hit zero.
  Future<void> _handleDrank() async {
    _timer?.cancel();
    await ref.read(hydrationControllerProvider).logDrink();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _handleSkip() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(
            top: AppSpacing.xxl,
            bottom: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time to hydrate.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: kHeadingFontFamily,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Take a few sips. I\'ll be here the whole time, watching.',
                style: TextStyle(color: colors.textMuted, fontSize: 16, height: 1.4),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThemedCard(
                      // Fixed width so the box never resizes when the
                      // caption below swaps between its two (differently
                      // long) states — it used to visibly shrink the
                      // instant the timer hit 00:00.
                      width: 300,
                      radius: 18,
                      useArtInLightMode: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatSeconds(_remainingSeconds),
                            style: const TextStyle(
                              fontFamily: kHeadingFontFamily,
                              fontSize: 60,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Fixed height (not just fixed-width text) so a
                          // one-line vs. two-line wrap can't shift the
                          // box's height either.
                          SizedBox(
                            height: 36,
                            child: Center(
                              child: Text(
                                _isComplete
                                    ? 'All done? Let me know.'
                                    : 'Drinking now — I\'m timing you.',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontFamily: kHeadingFontFamily,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Explicit gap instead of letting Pochi overlap the
                    // card's bottom edge — the earlier version had them
                    // touching.
                    const SizedBox(height: AppSpacing.lg),
                    SpriteAnimation(creature: pochi, mood: MoodBand.happy, scale: 2.2),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PixelButton(
                      onPressed: _handleDrank,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PixelIcon(
                            'assets/ui/icon_check.png',
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('I Meowdrated!'),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _handleSkip,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelIcon('assets/ui/icon_x.png', color: colors.textMuted, size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          const Text('Skip'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatSeconds(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
