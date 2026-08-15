import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_effect.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_icon.dart';
import '../../../core/widgets/themed_card_decoration.dart';
import '../../creatures/creature_roster.dart';
import '../../creatures/models/mood_band.dart';
import '../../creatures/widgets/sprite_animation.dart';
import '../../settings/providers/music_muted_providers.dart';
import '../../settings/providers/sound_muted_providers.dart';
import '../hydration_constants.dart';
import '../providers/hydration_providers.dart';

class DrinkMomentScreen extends ConsumerStatefulWidget {
  const DrinkMomentScreen({super.key});

  @override
  ConsumerState<DrinkMomentScreen> createState() => _DrinkMomentScreenState();
}

class _DrinkMomentScreenState extends ConsumerState<DrinkMomentScreen> {
  static const _songVolume = 0.5;

  // How long the crossfade at each loop boundary (and the very first
  // fade-in) takes. Comfortably shorter than the track itself, so the
  // envelope in _fadeFactor never has to fight itself mid-song.
  static const _fadeWindow = Duration(seconds: 2);

  late int _remainingSeconds = kDrinkMomentSeconds;
  Timer? _timer;
  AudioPlayer? _songPlayer;
  StreamSubscription<Duration>? _songPositionSub;
  StreamSubscription<Duration>? _songDurationSub;
  Duration? _songDuration;
  Duration _songPosition = Duration.zero;

  // Mirrors musicMutedProvider and soundMutedProvider locally so
  // _updateSongVolume can read them synchronously from the
  // position-stream callback. Seeded from whatever the providers already
  // have (falls back to unmuted while still loading) and kept in sync by
  // the ref.listen calls in build(). _musicMuted is this screen's own
  // music-only toggle (see _MusicMuteButton); _soundMuted is the Settings
  // "Sound" master mute, which silences the song too — either one being
  // true means no audio.
  bool _musicMuted = false;
  bool _soundMuted = false;

  // Picked once per visit (not per rebuild) so it doesn't shuffle under
  // the user mid-countdown — a fresh roll each time this screen opens.
  late final _pose = pochiDrinkPoses[math.Random().nextInt(pochiDrinkPoses.length)];

  @override
  void initState() {
    super.initState();
    _musicMuted = ref.read(musicMutedProvider).value ?? false;
    _soundMuted = ref.read(soundMutedProvider).value ?? false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(
          0,
          kDrinkMomentSeconds,
        );
      });
      // The countdown is just a pace-setter, not a track length — once it
      // hits zero the timer stops ticking but the song keeps looping, so
      // someone who wants to linger and listen can.
      if (_remainingSeconds == 0) {
        _timer?.cancel();
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
      // Loops gaplessly on its own rather than us reseeking on completion
      // — _updateSongVolume layers the fade in/out on top by watching
      // position against duration, so each wrap-around still reads as a
      // deliberate crossfade rather than a hard restart.
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0);
      _songPositionSub = player.onPositionChanged.listen((position) {
        _songPosition = position;
        _updateSongVolume();
      });
      _songDurationSub = player.onDurationChanged.listen((duration) {
        _songDuration = duration;
      });
      await player.play(AssetSource('audio/drinkMomentSong.mp3'));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('DrinkMomentScreen: skipping song ($error)');
      }
    }
  }

  /// Applies the current mute flag and fade envelope to [_songPlayer]'s
  /// volume. Called on every position tick (for the loop-boundary fade)
  /// and whenever the mute toggle changes (using the last-known position),
  /// so both stay driven through this single place.
  void _updateSongVolume() {
    final player = _songPlayer;
    if (player == null) {
      return;
    }
    final muted = _musicMuted || _soundMuted;
    final volume = muted ? 0.0 : _songVolume * _fadeFactor();
    unawaited(player.setVolume(volume).catchError((_) {}));
  }

  /// 0.0-1.0 multiplier that ramps up over [_fadeWindow] from the very
  /// start of the track, and back down over [_fadeWindow] before it wraps
  /// — the "nice fade in/fade out on repeat" effect, layered on top of the
  /// player's own gapless loop.
  double _fadeFactor() {
    final duration = _songDuration;
    if (duration == null || duration <= _fadeWindow * 2) {
      return 1.0;
    }
    final fadeMs = _fadeWindow.inMilliseconds;
    final msFromStart = _songPosition.inMilliseconds;
    if (msFromStart < fadeMs) {
      return (msFromStart / fadeMs).clamp(0.0, 1.0);
    }
    final msFromEnd = (duration - _songPosition).inMilliseconds;
    if (msFromEnd < fadeMs) {
      return (msFromEnd / fadeMs).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  Future<void> _toggleMusicMuted() async {
    final next = !_musicMuted;
    setState(() => _musicMuted = next);
    unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
    _updateSongVolume();
    await ref.read(musicMutedProvider.notifier).set(next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _songPositionSub?.cancel();
    _songDurationSub?.cancel();
    _songPlayer?.dispose();
    super.dispose();
  }

  bool get _isComplete => _remainingSeconds == 0;

  // No longer gated on _isComplete — the countdown is a pace-setter, not
  // a lock. Someone who's already finished their sips shouldn't have to
  // stand around waiting for the number to hit zero.
  Future<void> _handleDrank() async {
    unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTap));
    _timer?.cancel();
    await ref.read(hydrationControllerProvider).logDrink();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _handleSkip() {
    unawaited(ref.read(soundServiceProvider).play(SoundEffect.uiTapNegative));
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Catches both a later toggle from Settings and each provider's own
    // initial load finishing after initState already seeded these fields
    // with a guessed default.
    ref.listen<AsyncValue<bool>>(musicMutedProvider, (previous, next) {
      final value = next.value;
      if (value != null && value != _musicMuted) {
        setState(() => _musicMuted = value);
        _updateSongVolume();
      }
    });
    ref.listen<AsyncValue<bool>>(soundMutedProvider, (previous, next) {
      final value = next.value;
      if (value != null && value != _soundMuted) {
        setState(() => _soundMuted = value);
        _updateSongVolume();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl)
              .copyWith(top: AppSpacing.xxl, bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time to hydrate.',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                          fontFamily: kHeadingFontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  _MusicMuteButton(
                    // Reflects whether the song is actually audible right
                    // now (also off if Settings' master Sound mute is on),
                    // even though tapping it only ever flips this screen's
                    // own music-only flag — see _toggleMusicMuted.
                    muted: _musicMuted || _soundMuted,
                    onPressed: _toggleMusicMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Take a few sips. I\'ll be here the whole time, watching.',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 16,
                  height: 1.4,
                ),
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
                    SpriteAnimation(
                      creature: pochi,
                      mood: MoodBand.happy,
                      clipOverride: _pose,
                      scale: 2.2,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A Row (not Center) is what actually hugs the button to
                    // its content width here — PixelButton's inner Container
                    // sets `alignment: Alignment.center`, which makes it
                    // expand to fill any *bounded* incoming constraint
                    // (Center's included, even though it's loose). Only a
                    // Row gives its non-flex child an *unbounded* main-axis
                    // constraint, which is what lets the Container
                    // shrink-wrap instead — same fix as the Meowdrate!
                    // button in flood_home_screen.dart.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                      ],
                    ),
                    TextButton(
                      onPressed: _handleSkip,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelIcon(
                            'assets/ui/icon_x.png',
                            color: colors.textMuted,
                            size: 20,
                          ),
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

/// Quick access to the same music-mute setting Settings has, right where
/// the song is actually playing — someone who likes the tap/chime sound
/// effects but not the background song shouldn't have to leave this screen
/// to quiet it. A plain Material glyph (no PixelIcon) to match the other
/// bare functional icons elsewhere (e.g. the settings gear).
class _MusicMuteButton extends StatelessWidget {
  const _MusicMuteButton({required this.muted, required this.onPressed});

  final bool muted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Tooltip(
          message: muted ? 'Unmute music' : 'Mute music',
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(
              muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
              color: colors.textMuted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

