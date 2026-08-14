import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../time_of_day_band.dart';

/// Ticks once a minute so timeOfDayBandProvider re-evaluates as time
/// passes, even without any other state changing.
final _timeTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (i) => i);
});

/// Debug-only: pins the hour used for band selection instead of the
/// device clock.
class DebugTimeOverride extends Notifier<int?> {
  @override
  int? build() => null;

  void setOverride(int? value) => state = value;
}

final debugTimeOverrideProvider =
    NotifierProvider<DebugTimeOverride, int?>(DebugTimeOverride.new);

final timeOfDayBandProvider = Provider<TimeOfDayBand>((ref) {
  ref.watch(_timeTickProvider);
  final override = ref.watch(debugTimeOverrideProvider);
  return bandForHour(override ?? DateTime.now().hour);
});
