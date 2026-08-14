import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meowdrate/core/audio/sound_effect.dart';
import 'package:meowdrate/core/audio/sound_service.dart';
import 'package:meowdrate/core/utils/iso_date.dart';
import 'package:meowdrate/features/flood/providers/flood_providers.dart';

/// registerDrinkLogged plays a sound on goal-met; the real SoundService
/// touches platform channels that aren't available in a plain `test()`
/// (no Flutter binding), so every test container overrides it with this
/// no-op instead.
class _NoopSoundService extends SoundService {
  @override
  Future<void> play(SoundEffect effect) async {}
}

ProviderContainer _testContainer() {
  return ProviderContainer(
    overrides: [soundServiceProvider.overrideWithValue(_NoopSoundService())],
  );
}

String _stateJson({
  required int currentStreak,
  required String? lastGoalMetDate,
  required String? lastSeenDate,
}) {
  return '{"currentStreak":$currentStreak,"longestStreak":$currentStreak,'
      '"lastGoalMetDate":${lastGoalMetDate == null ? 'null' : '"$lastGoalMetDate"'},'
      '"lastSeenDate":${lastSeenDate == null ? 'null' : '"$lastSeenDate"'},'
      '"lifetimeCups":10}';
}

void main() {
  final now = DateTime.now();
  final yesterday = isoDate(now.subtract(const Duration(days: 1)));
  final twoDaysAgo = isoDate(now.subtract(const Duration(days: 2)));
  final fiveDaysAgo = isoDate(now.subtract(const Duration(days: 5)));

  test('goal met twice in one day increments the streak only once', () async {
    SharedPreferences.setMockInitialValues({});
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(floodStateProvider.future);
    final notifier = container.read(floodStateProvider.notifier);
    await notifier.registerDrinkLogged(totalMlToday: 2000);
    await notifier.registerDrinkLogged(totalMlToday: 2500);

    expect(container.read(floodStateProvider).value!.currentStreak, 1);
  });

  test('meeting the goal on consecutive days increments the streak', () async {
    SharedPreferences.setMockInitialValues({
      'flood.state.v1': _stateJson(
        currentStreak: 3,
        lastGoalMetDate: yesterday,
        lastSeenDate: yesterday,
      ),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(floodStateProvider.future);
    await container.read(floodStateProvider.notifier).registerDrinkLogged(totalMlToday: 2000);

    expect(container.read(floodStateProvider).value!.currentStreak, 4);
  });

  test('meeting the goal after a gap resets the streak to 1', () async {
    SharedPreferences.setMockInitialValues({
      'flood.state.v1': _stateJson(
        currentStreak: 5,
        lastGoalMetDate: twoDaysAgo,
        lastSeenDate: twoDaysAgo,
      ),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(floodStateProvider.future);
    await container.read(floodStateProvider.notifier).registerDrinkLogged(totalMlToday: 2000);

    expect(container.read(floodStateProvider).value!.currentStreak, 1);
  });

  test('opening the app after a missed day quietly zeroes the streak', () async {
    SharedPreferences.setMockInitialValues({
      'flood.state.v1': _stateJson(
        currentStreak: 4,
        lastGoalMetDate: twoDaysAgo,
        lastSeenDate: twoDaysAgo,
      ),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    final state = await container.read(floodStateProvider.future);

    expect(state.currentStreak, 0);
    expect(
      container.read(floodStateProvider.notifier).consumePendingRolloverEvent(),
      DayRolloverEvent.goalMissed,
    );
  });

  test('opening the app after a long absence reports a long-absence event', () async {
    SharedPreferences.setMockInitialValues({
      'flood.state.v1': _stateJson(
        currentStreak: 2,
        lastGoalMetDate: fiveDaysAgo,
        lastSeenDate: fiveDaysAgo,
      ),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(floodStateProvider.future);

    expect(
      container.read(floodStateProvider.notifier).consumePendingRolloverEvent(),
      DayRolloverEvent.longAbsence,
    );
    // Consuming the event clears it so it doesn't repeat.
    expect(
      container.read(floodStateProvider.notifier).consumePendingRolloverEvent(),
      DayRolloverEvent.none,
    );
  });
}
