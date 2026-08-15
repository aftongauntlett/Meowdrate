import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/sound_muted_providers.dart';
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
  // Round-robining across a generic pool (the previous approach here)
  // wasn't enough: every play() call still did AudioPlayer.play(source),
  // which re-decodes the mp3 from the asset bundle from scratch on every
  // single call. That's cheap on a simulator but measurably slow on real
  // hardware — narratorBlip alone fires every ~72ms while a line types
  // out, so repeatedly decoding piled up enough platform-channel work to
  // visibly stall the UI thread (the narrator's reveal stuttering) and,
  // when a call landed on a player still mid-decode from a previous call,
  // silently dropped that sound (missed tap clicks).
  //
  // Fix: decode each effect's asset exactly once per player (via
  // setSource, at pool-creation time) and reuse it — every actual play()
  // call after that is just a cheap stop()+resume() on an already-decoded
  // player, no asset IO involved. Kept per-effect (not shared across
  // effects) with a couple of players each, so a burst of the same
  // rapid-fire effect (narratorBlip) still has a free player to land on
  // instead of two calls racing the same one.
  static const _playersPerEffect = 3;
  final Map<SoundEffect, List<AudioPlayer>> _pools = {};
  final Map<SoundEffect, int> _nextIndex = {};

  /// The Settings "Sound" master mute (see [soundMutedProvider]), mirrored
  /// here by [soundServiceProvider] so [play] can check it synchronously
  /// without every call site needing to read the provider itself.
  bool muted = false;

  Future<void> play(SoundEffect effect) async {
    if (muted) {
      return;
    }
    try {
      final player = await _acquirePlayer(effect);
      // Fired together via Future.wait rather than sequentially — awaiting
      // the haptic first would add its own platform-channel round trip
      // ahead of the sound.
      await Future.wait([
        if (_tapEffects.contains(effect)) HapticFeedback.lightImpact(),
        player.stop().then((_) => player.resume()),
      ]);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('SoundService: skipping ${effect.name} ($error)');
      }
    }
  }

  Future<AudioPlayer> _acquirePlayer(SoundEffect effect) async {
    // Constructed lazily, inside play()'s try block: touching audioplayers
    // at all requires platform channels, which aren't available in every
    // environment (e.g. plain `test()` with no Flutter binding) — that
    // failure should be swallowed exactly like a missing asset file.
    var pool = _pools[effect];
    if (pool == null) {
      pool = [];
      for (var i = 0; i < _playersPerEffect; i++) {
        final player = AudioPlayer();
        // lowLatency picks audioplayers' dedicated short-SFX native
        // backend (e.g. SoundPool on Android) instead of the default
        // mediaPlayer one. ReleaseMode.stop keeps the decoded audio
        // resident after playback instead of releasing it, which is what
        // makes the stop()+resume() reuse above cheap.
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(effect.assetPath));
        pool.add(player);
      }
      _pools[effect] = pool;
    }
    final index = (_nextIndex[effect] ?? 0) % pool.length;
    _nextIndex[effect] = index + 1;
    return pool[index];
  }

  void dispose() {
    for (final pool in _pools.values) {
      for (final player in pool) {
        player.dispose();
      }
    }
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  ref.listen<AsyncValue<bool>>(soundMutedProvider, (previous, next) {
    final value = next.value;
    if (value != null) {
      service.muted = value;
    }
  }, fireImmediately: true);
  return service;
});
