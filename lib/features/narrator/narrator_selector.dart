import '../../core/time_of_day/time_of_day_band.dart';
import 'data/goal_missed_lines.dart';
import 'data/long_absence_lines.dart';
import 'narrator_bag_service.dart';
import 'narrator_line_pools.dart';
import 'narrator_trigger.dart';

String selectNarratorLine(
  NarratorBagService bagService,
  NarratorTrigger trigger, {
  int? occurrence,
}) {
  final pool = narratorLinePools[trigger]!;
  return bagService.pull(trigger, pool, occurrence: occurrence);
}

/// Welcome-back caption for a normal app open (not goal-missed / long-absence).
/// Daytime keeps the generic [NarratorTrigger.appReturn] pool; dawn, dusk,
/// evening, and past-midnight swap in a small time-specific pool so the
/// line can mention the hour without drink-logged commentary pretending
/// to know how long you took. [goalMet] overrides all of those with
/// [NarratorTrigger.goalMetGreeting] instead — the time-of-day pools assume
/// the flood is still up ("the water didn't get short"), which reads wrong
/// once today's goal is already cleared.
String selectAppReturnLine(
  NarratorBagService bagService, {
  int? hour,
  bool goalMet = false,
}) {
  if (goalMet) {
    return selectNarratorLine(bagService, NarratorTrigger.goalMetGreeting);
  }
  final h = hour ?? DateTime.now().hour;
  final trigger = appReturnTriggerForHour(h);
  return selectNarratorLine(bagService, trigger);
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

String selectOpeningGreeting(
  NarratorBagService bagService,
  NarratorTrigger trigger, {
  int? hour,
  bool goalMet = false,
}) {
  if (trigger == NarratorTrigger.appReturn) {
    return selectAppReturnLine(bagService, hour: hour, goalMet: goalMet);
  }
  return selectNarratorLine(bagService, trigger);
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
String? selectSettingsClosedLine(
  NarratorBagService bagService, {
  String? currentOpeningLine,
}) {
  if (isPriorityOpeningLine(currentOpeningLine)) {
    return null;
  }
  return selectNarratorLine(bagService, NarratorTrigger.settingsClosed);
}
