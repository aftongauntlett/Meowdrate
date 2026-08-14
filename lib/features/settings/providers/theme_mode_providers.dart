import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hydration/providers/hydration_providers.dart';

const _storageKey = 'settings.themeMode.v1';

/// The user's manual Light/Dark/System preference for the app's UI chrome
/// — completely separate from the flood scene's automatic day/night sky
/// (see FloodScene/timeOfDayBandProvider). Defaults to System.
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final store = ref.watch(localStoreProvider);
    final json = await store.readJson(_storageKey);
    return _fromName(json?['mode'] as String?);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    await ref.read(localStoreProvider).writeJson(_storageKey, {'mode': mode.name});
  }

  ThemeMode _fromName(String? name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
