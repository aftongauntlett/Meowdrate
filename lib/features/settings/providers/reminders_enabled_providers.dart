import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hydration/providers/hydration_providers.dart';

const _storageKey = 'settings.remindersEnabled.v1';

/// Whether the user opted into hydration nudges — off by default, same as
/// before (this used to be inferred from whether a notification happened
/// to be scheduled; now it's the source of truth so the toggle survives a
/// day rollover even though reminders are single-shot, not repeating —
/// see reminder_service.dart).
class RemindersEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final store = ref.watch(localStoreProvider);
    final json = await store.readJson(_storageKey);
    return (json?['enabled'] as bool?) ?? false;
  }

  Future<void> set(bool enabled) async {
    state = AsyncValue.data(enabled);
    await ref.read(localStoreProvider).writeJson(_storageKey, {'enabled': enabled});
  }
}

final remindersEnabledProvider =
    AsyncNotifierProvider<RemindersEnabledNotifier, bool>(RemindersEnabledNotifier.new);
