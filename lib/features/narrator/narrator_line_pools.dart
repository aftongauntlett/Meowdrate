import 'data/app_return_lines.dart';
import 'data/drink_logged_lines.dart';
import 'data/goal_met_lines.dart';
import 'data/goal_missed_lines.dart';
import 'data/long_absence_lines.dart';
import 'narrator_trigger.dart';

const narratorLinePools = <NarratorTrigger, List<String>>{
  NarratorTrigger.drinkLogged: drinkLoggedLines,
  NarratorTrigger.goalMet: goalMetLines,
  NarratorTrigger.goalMissed: goalMissedLines,
  NarratorTrigger.longAbsence: longAbsenceLines,
  NarratorTrigger.appReturn: appReturnLines,
};
