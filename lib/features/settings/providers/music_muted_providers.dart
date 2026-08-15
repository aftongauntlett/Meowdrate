import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hydration/providers/hydration_providers.dart';

const _storageKey = 'settings.musicMuted.v1';

/// Whether the Drink Moment background song is muted — independent of
/// sound effects, which keep playing either way (see
/// `drink_moment_screen.dart`). Off (i.e. music audible) by default.
class MusicMutedNotifier extends AsyncNotifier<bool> {
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

final musicMutedProvider =
    AsyncNotifierProvider<MusicMutedNotifier, bool>(MusicMutedNotifier.new);
