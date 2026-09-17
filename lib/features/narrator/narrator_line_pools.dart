import 'data/app_return_lines.dart';
import 'data/dawn_lines.dart';
import 'data/drink_logged_lines.dart';
import 'data/dusk_lines.dart';
import 'data/goal_met_lines.dart';
import 'data/goal_missed_lines.dart';
import 'data/late_night_lines.dart';
import 'data/long_absence_lines.dart';
import 'data/night_lines.dart';
import 'data/settings_closed_lines.dart';
import 'narrator_trigger.dart';

const narratorLinePools = <NarratorTrigger, List<String>>{
  NarratorTrigger.drinkLogged: drinkLoggedLines,
  NarratorTrigger.goalMet: goalMetLines,
  NarratorTrigger.goalMissed: goalMissedLines,
  NarratorTrigger.longAbsence: longAbsenceLines,
  NarratorTrigger.appReturn: appReturnLines,
  NarratorTrigger.dawn: dawnLines,
  NarratorTrigger.dusk: duskLines,
  NarratorTrigger.night: nightLines,
  NarratorTrigger.lateNight: lateNightLines,
  NarratorTrigger.settingsClosed: settingsClosedLines,
};
