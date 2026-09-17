import 'package:flutter_test/flutter_test.dart';
import 'package:meowdrate/features/narrator/data/app_return_lines.dart';
import 'package:meowdrate/features/narrator/data/dawn_lines.dart';
import 'package:meowdrate/features/narrator/data/dusk_lines.dart';
import 'package:meowdrate/features/narrator/data/goal_missed_lines.dart';
import 'package:meowdrate/features/narrator/data/late_night_lines.dart';
import 'package:meowdrate/features/narrator/data/long_absence_lines.dart';
import 'package:meowdrate/features/narrator/data/night_lines.dart';
import 'package:meowdrate/features/narrator/data/settings_closed_lines.dart';
import 'package:meowdrate/features/narrator/narrator_selector.dart';
import 'package:meowdrate/features/narrator/narrator_trigger.dart';

void main() {
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
    final date = DateTime(2026, 9, 17);

    test('picks from the pool that matches the hour', () {
      expect(dawnLines, contains(selectAppReturnLine(date: date, hour: 6)));
      expect(appReturnLines, contains(selectAppReturnLine(date: date, hour: 12)));
      expect(duskLines, contains(selectAppReturnLine(date: date, hour: 19)));
      expect(nightLines, contains(selectAppReturnLine(date: date, hour: 22)));
      expect(lateNightLines, contains(selectAppReturnLine(date: date, hour: 1)));
    });

    test('same date and hour is stable', () {
      expect(
        selectAppReturnLine(date: date, hour: 6),
        selectAppReturnLine(date: date, hour: 6),
      );
    });
  });

  group('selectOpeningGreeting', () {
    test('does not time-swap a goal-missed line', () {
      final date = DateTime(2026, 9, 17);
      expect(
        selectOpeningGreeting(NarratorTrigger.goalMissed, date: date, hour: 1),
        selectNarratorLine(NarratorTrigger.goalMissed, date: date),
      );
    });
  });

  group('selectSettingsClosedLine', () {
    test('skips goal-missed and long-absence greetings', () {
      expect(
        selectSettingsClosedLine(currentOpeningLine: goalMissedLines.first),
        isNull,
      );
      expect(
        selectSettingsClosedLine(currentOpeningLine: longAbsenceLines.first),
        isNull,
      );
    });

    test('comments when there is no opening override', () {
      final line = selectSettingsClosedLine(
        currentOpeningLine: null,
        date: DateTime(2026, 9, 17),
      );
      expect(settingsClosedLines, contains(line));
    });

    test('may replace a generic welcome-back line', () {
      final line = selectSettingsClosedLine(
        currentOpeningLine: appReturnLines.first,
        date: DateTime(2026, 9, 17),
      );
      expect(settingsClosedLines, contains(line));
    });
  });
}
