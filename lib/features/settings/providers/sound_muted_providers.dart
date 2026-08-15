import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hydration/providers/hydration_providers.dart';

const _storageKey = 'settings.soundMuted.v1';

/// The master mute — silences everything (sound effects via
/// [SoundService] and the Drink Moment song). Independent from
/// [musicMutedProvider], which only mutes the Drink Moment song on its
/// own screen; this one is meant to be reachable from Settings and win
/// over that one when both apply. Off (i.e. audible) by default.
class SoundMutedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final store = ref.watch(localStoreProvider);
    final json = await store.readJson(_storageKey);
    return (json?['muted'] as bool?) ?? false;
  }

  Future<void> set(bool muted) async {
    state = AsyncValue.data(muted);
    await ref.read(localStoreProvider).writeJson(_storageKey, {'muted': muted});
  }
}

final soundMutedProvider =
    AsyncNotifierProvider<SoundMutedNotifier, bool>(SoundMutedNotifier.new);
