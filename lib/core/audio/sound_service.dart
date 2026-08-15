import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sound_effect.dart';

/// Which effects double as a discrete "button click" moment (as opposed to
/// a passive/reactive cue like [SoundEffect.goalMet] or the rapid-fire
/// [SoundEffect.narratorBlip]) — these also fire a light haptic alongside
/// their sound, see [SoundService.play].
const _tapEffects = {SoundEffect.uiTap, SoundEffect.uiTapNegative};

/// Thin wrapper over audioplayers for short one-shot sound effects, plus a
/// light haptic tick for the subset of effects that represent an actual
/// button tap (see [_tapEffects]) — the combination is what reads as
/// "responsive" the way Finch's button taps do. Every audio asset is
/// self-made and optional (see assets/audio/README.md) — a missing file is
/// skipped silently rather than crashing the app, the same "art not
/// sourced yet" tolerance the old placeholder-emoji pet view used for
/// missing Lottie files. Haptics get the same tolerance: unsupported
/// platforms (web, desktop) just no-op/throw and are swallowed the same
/// way as a missing sound file.
class SoundService {
  // A single shared AudioPlayer dropped a tap's sound whenever two calls
  // landed close together (e.g. a quick double-tap): the second play()
  // races the first's still-in-flight source-load/"prepared" setup on the
  // same player and can lose silently. Round-robining across a small pool
  // gives each near-simultaneous call its own player instead.
  static const _poolSize = 4;
  List<AudioPlayer>? _players;
  int _nextPlayerIndex = 0;

  Future<void> play(SoundEffect effect) async {
    try {
      // Constructed lazily, inside the try block: touching audioplayers at
      // all requires platform channels, which aren't available in every
      // environment (e.g. plain `test()` with no Flutter binding) — that
      // failure should be swallowed exactly like a missing asset file.
      final players = _players ??= List.generate(
        _poolSize,
        (_) => AudioPlayer(),
      );
      final player = players[_nextPlayerIndex];
      _nextPlayerIndex = (_nextPlayerIndex + 1) % players.length;
      // PlayerMode.lowLatency (audioplayers' dedicated short-SFX backend,
      // e.g. SoundPool on Android) instead of the default mediaPlayer mode
      // — these are one-shot UI/narrator blips fired on every tap or
      // typewriter character, and mediaPlayer's per-play buffering was
      // audible as a delay between tap and sound.
      //
      // Fired together via Future.wait rather than sequentially — awaiting
      // the haptic first would add its own platform-channel round trip
      // ahead of the sound, reintroducing the delay that motivated
      // lowLatency in the first place.
      await Future.wait([
        if (_tapEffects.contains(effect)) HapticFeedback.lightImpact(),
        player.play(AssetSource(effect.assetPath), mode: PlayerMode.lowLatency),
      ]);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('SoundService: skipping ${effect.name} ($error)');
      }
    }
  }

  void dispose() {
    for (final player in _players ?? const <AudioPlayer>[]) {
      player.dispose();
    }
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});
