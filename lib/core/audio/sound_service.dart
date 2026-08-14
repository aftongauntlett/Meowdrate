import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sound_effect.dart';

/// Thin wrapper over audioplayers for short one-shot sound effects. Every
/// asset is self-made and optional (see assets/audio/README.md) — a
/// missing file is skipped silently rather than crashing the app, the
/// same "art not sourced yet" tolerance the old placeholder-emoji pet
/// view used for missing Lottie files.
class SoundService {
  AudioPlayer? _player;

  Future<void> play(SoundEffect effect) async {
    try {
      // Constructed lazily, inside the try block: touching audioplayers at
      // all requires platform channels, which aren't available in every
      // environment (e.g. plain `test()` with no Flutter binding) — that
      // failure should be swallowed exactly like a missing asset file.
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource(effect.assetPath));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('SoundService: skipping ${effect.name} ($error)');
      }
    }
  }

  void dispose() => _player?.dispose();
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});
