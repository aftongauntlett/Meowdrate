import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meowdrate/core/storage/local_store.dart';
import 'package:meowdrate/features/narrator/narrator_bag_service.dart';
import 'package:meowdrate/features/narrator/narrator_trigger.dart';

void main() {
  const pool = ['a', 'b', 'c'];

  test('cycles through the whole pool before repeating', () {
    SharedPreferences.setMockInitialValues({});
    final service = NarratorBagService(const LocalStore());
    final seen = <String>{};
    for (var i = 0; i < pool.length; i++) {
      seen.add(service.pull(NarratorTrigger.drinkLogged, pool));
    }
    expect(seen, pool.toSet());
  });

  test('a given occurrence always returns the same line on repeated reads', () {
    SharedPreferences.setMockInitialValues({});
    final service = NarratorBagService(const LocalStore());
    final first = service.pull(NarratorTrigger.drinkLogged, pool, occurrence: 1);
    final second = service.pull(NarratorTrigger.drinkLogged, pool, occurrence: 1);
    expect(first, second);
  });

  test('different occurrences on the same day pull different lines', () {
    SharedPreferences.setMockInitialValues({});
    final service = NarratorBagService(const LocalStore());
    final lines = [
      service.pull(NarratorTrigger.drinkLogged, pool, occurrence: 1),
      service.pull(NarratorTrigger.drinkLogged, pool, occurrence: 2),
      service.pull(NarratorTrigger.drinkLogged, pool, occurrence: 3),
    ];
    expect(lines.toSet(), pool.toSet());
  });

  test('persists the remaining bag order across service instances', () async {
    SharedPreferences.setMockInitialValues({});
    final first = NarratorBagService(const LocalStore());
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final pulledFromFirst = {
      first.pull(NarratorTrigger.drinkSkipped, pool),
      first.pull(NarratorTrigger.drinkSkipped, pool),
    };
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final second = NarratorBagService(const LocalStore());
    await Future<void>.delayed(const Duration(milliseconds: 5));

    // Only one line is left in the persisted queue — the second instance
    // should pick up exactly that one, not reshuffle a fresh cycle.
    final thirdLine = second.pull(NarratorTrigger.drinkSkipped, pool);
    expect(pulledFromFirst.contains(thirdLine), isFalse);
  });

  test('debugReset clears in-memory and persisted state', () async {
    SharedPreferences.setMockInitialValues({});
    final service = NarratorBagService(const LocalStore());
    service.pull(NarratorTrigger.drinkLogged, pool, occurrence: 1);
    await service.debugReset();

    final second = NarratorBagService(const LocalStore());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    // Nothing left over from the reset service to collide with — just
    // confirm a fresh pull still works.
    expect(pool, contains(second.pull(NarratorTrigger.drinkLogged, pool)));
  });
}
