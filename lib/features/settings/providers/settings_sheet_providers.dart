import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Settings sheet is currently on screen. The flood scene
/// behind it (FloodScene) stays fully mounted and reactive while a
/// `showModalBottomSheet` is up — see showSettingsSheet — so without this,
/// changes made in Settings (e.g. the daily-goal stepper shifting the
/// narrator's selected line) still restart the narrator's typewriter
/// animation and its blip sound underneath the sheet, even though it's
/// hidden. FloodScene watches this to freeze the narrator line while true.
class SettingsSheetOpen extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final settingsSheetOpenProvider = NotifierProvider<SettingsSheetOpen, bool>(
  SettingsSheetOpen.new,
);
