import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meowdrate/core/storage/local_store.dart';
import 'package:meowdrate/features/narrator/data/app_return_lines.dart';
import 'package:meowdrate/features/narrator/data/dawn_lines.dart';
import 'package:meowdrate/features/narrator/data/dusk_lines.dart';
import 'package:meowdrate/features/narrator/data/goal_met_greeting_lines.dart';
import 'package:meowdrate/features/narrator/data/goal_missed_lines.dart';
import 'package:meowdrate/features/narrator/data/late_night_lines.dart';
import 'package:meowdrate/features/narrator/data/long_absence_lines.dart';
import 'package:meowdrate/features/narrator/data/night_lines.dart';
import 'package:meowdrate/features/narrator/data/settings_closed_lines.dart';
import 'package:meowdrate/features/narrator/narrator_bag_service.dart';
import 'package:meowdrate/features/narrator/narrator_line_pools.dart';
import 'package:meowdrate/features/narrator/narrator_selector.dart';
import 'package:meowdrate/features/narrator/narrator_trigger.dart';

NarratorBagService _bag() => NarratorBagService(const LocalStore());

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('narratorLinePools', () {
    test('every trigger has a non-empty pool', () {
      // selectNarratorLine picks from pool[trigger] — an empty pool (a
      // typo or an accidentally-emptied data file) would throw a
      // RangeError the instant that trigger fires in production.
      for (final trigger in NarratorTrigger.values) {
        expect(
          narratorLinePools[trigger],
          isNotNull,
          reason: '$trigger has no pool registered',
        );
        expect(
          narratorLinePools[trigger],
          isNotEmpty,
          reason: '$trigger\'s pool is empty',
        );
      }
    });
  });

  group('isPriorityOpeningLine', () {
    test('is true for goal-missed and long-absence lines', () {
      expect(isPriorityOpeningLine(goalMissedLines.first), isTrue);
      expect(isPriorityOpeningLine(longAbsenceLines.first), isTrue);
    });

    test('is false for a plain welcome-back line, null, or an unrelated string', () {
      expect(isPriorityOpeningLine(appReturnLines.first), isFalse);
      expect(isPriorityOpeningLine(null), isFalse);
      expect(isPriorityOpeningLine('not a real narrator line'), isFalse);
    });
  });

  group('appReturnTriggerForHour', () {
    test('maps each local-hour band to the matching greeting trigger', () {
      expect(appReturnTriggerForHour(0), NarratorTrigger.lateNight);
      expect(appReturnTriggerForHour(4), NarratorTrigger.lateNight);
      expect(appReturnTriggerForHour(5), NarratorTrigger.dawn);
      expect(appReturnTriggerForHour(6), NarratorTrigger.dawn);
      expect(appReturnTriggerForHour(7), NarratorTrigger.appReturn);
      expect(appReturnTriggerForHour(12), NarratorTrigger.appReturn);
      expect(appReturnTriggerForHour(17), NarratorTrigger.appReturn);
      expect(appReturnTriggerForHour(18), NarratorTrigger.dusk);
      expect(appReturnTriggerForHour(19), NarratorTrigger.dusk);
      expect(appReturnTriggerForHour(20), NarratorTrigger.night);
      expect(appReturnTriggerForHour(23), NarratorTrigger.night);
    });
  });

  group('selectAppReturnLine', () {
    test('picks from the pool that matches the hour', () {
      final bag = _bag();
      expect(dawnLines, contains(selectAppReturnLine(bag, hour: 6)));
      expect(appReturnLines, contains(selectAppReturnLine(bag, hour: 12)));
      expect(duskLines, contains(selectAppReturnLine(bag, hour: 19)));
      expect(nightLines, contains(selectAppReturnLine(bag, hour: 22)));
      expect(lateNightLines, contains(selectAppReturnLine(bag, hour: 1)));
    });

    test('goalMet overrides every hour band with the goal-met greeting pool', () {
      final bag = _bag();
      for (final hour in [6, 12, 19, 22, 1]) {
        expect(
          goalMetGreetingLines,
          contains(selectAppReturnLine(bag, hour: hour, goalMet: true)),
        );
      }
    });
  });

  group('selectOpeningGreeting', () {
    test('routes a goal-missed trigger the same as selectNarratorLine', () {
      final bag = _bag();
      expect(
        goalMissedLines,
        contains(selectOpeningGreeting(bag, NarratorTrigger.goalMissed, hour: 1)),
      );
    });

    test('goalMissed ignores goalMet — a prior-day miss still shows even if today is already done', () {
      final bag = _bag();
      expect(
        goalMissedLines,
        contains(
          selectOpeningGreeting(
            bag,
            NarratorTrigger.goalMissed,
            hour: 1,
            goalMet: true,
          ),
        ),
      );
    });

    test('an appReturn trigger with goalMet uses the goal-met greeting pool', () {
      final bag = _bag();
      expect(
        goalMetGreetingLines,
        contains(
          selectOpeningGreeting(
            bag,
            NarratorTrigger.appReturn,
            hour: 19,
            goalMet: true,
          ),
        ),
      );
    });
  });

  group('selectSettingsClosedLine', () {
    test('skips goal-missed and long-absence greetings', () {
      final bag = _bag();
      expect(
        selectSettingsClosedLine(bag, currentOpeningLine: goalMissedLines.first),
        isNull,
      );
      expect(
        selectSettingsClosedLine(bag, currentOpeningLine: longAbsenceLines.first),
        isNull,
      );
    });

    test('returns a settings-closed line when there is no opening override', () {
      final bag = _bag();
      final line = selectSettingsClosedLine(bag, currentOpeningLine: null);
      expect(settingsClosedLines, contains(line));
    });

    test('may replace a generic welcome-back line', () {
      final bag = _bag();
      final line = selectSettingsClosedLine(bag, currentOpeningLine: appReturnLines.first);
      expect(settingsClosedLines, contains(line));
    });
  });
}
