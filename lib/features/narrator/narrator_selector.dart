import '../../core/time_of_day/time_of_day_band.dart';
import '../../core/utils/date_seed.dart';
import 'data/goal_missed_lines.dart';
import 'data/long_absence_lines.dart';
import 'narrator_line_pools.dart';
import 'narrator_trigger.dart';

String selectNarratorLine(NarratorTrigger trigger, {DateTime? date, int occurrence = 0}) {
  final pool = narratorLinePools[trigger]!;
  final index = dateSeededIndex(
    date ?? DateTime.now(),
    pool.length,
    salt: trigger.index,
    occurrence: occurrence,
  );
  return pool[index];
}

/// Welcome-back caption for a normal app open (not goal-missed / long-absence).
/// Daytime keeps the generic [NarratorTrigger.appReturn] pool; dawn, dusk,
/// evening, and past-midnight swap in a small time-specific pool so the
/// line can mention the hour without drink-logged commentary pretending
/// to know how long you took.
String selectAppReturnLine({DateTime? date, int? hour}) {
  final now = date ?? DateTime.now();
  final h = hour ?? now.hour;
  final trigger = appReturnTriggerForHour(h);
  return selectNarratorLine(trigger, date: now);
}

/// Maps a local clock hour to the greeting trigger. Past midnight (0–4)
/// is [NarratorTrigger.lateNight] rather than generic night, so "night owl"
/// lines don't fire at 9pm.
NarratorTrigger appReturnTriggerForHour(int hour) {
  if (hour >= 0 && hour < 5) {
    return NarratorTrigger.lateNight;
  }
  return switch (bandForHour(hour)) {
    TimeOfDayBand.dawn => NarratorTrigger.dawn,
    TimeOfDayBand.dusk => NarratorTrigger.dusk,
    TimeOfDayBand.night => NarratorTrigger.night,
    TimeOfDayBand.day => NarratorTrigger.appReturn,
  };
}

String selectOpeningGreeting(NarratorTrigger trigger, {DateTime? date, int? hour}) {
  if (trigger == NarratorTrigger.appReturn) {
    return selectAppReturnLine(date: date, hour: hour);
  }
  return selectNarratorLine(trigger, date: date);
}

/// Goal-missed / long-absence openings are once-a-day and should survive
/// a trip through Settings. Anything else (welcome, a previous settings
/// quip, or no override) can be replaced.
bool isPriorityOpeningLine(String? line) {
  if (line == null) {
    return false;
  }
  return goalMissedLines.contains(line) || longAbsenceLines.contains(line);
}

/// Caption to show after Settings closes, or null if the current opening
/// line should be left alone.
String? selectSettingsClosedLine({String? currentOpeningLine, DateTime? date}) {
  if (isPriorityOpeningLine(currentOpeningLine)) {
    return null;
  }
  return selectNarratorLine(NarratorTrigger.settingsClosed, date: date);
}
