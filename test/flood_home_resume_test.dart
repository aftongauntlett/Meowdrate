import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meowdrate/app.dart';
import 'package:meowdrate/core/utils/iso_date.dart';
import 'package:meowdrate/features/narrator/data/goal_missed_lines.dart';
import 'package:meowdrate/features/narrator/providers/narrator_providers.dart';

/// A once-a-day goal-missed/long-absence greeting must survive a plain
/// foreground resume (switching apps and coming right back) the same way
/// it survives a trip through Settings — otherwise didChangeAppLifecycleState
/// silently overwrites it with a generic welcome the moment the user
/// returns, which defeats the point of it being once-a-day.
void main() {
  testWidgets(
    'a goal-missed opening line is not overwritten by a background/resume cycle',
    (tester) async {
      final twoDaysAgo = isoDate(DateTime.now().subtract(const Duration(days: 2)));
      SharedPreferences.setMockInitialValues({
        'flood.state.v1':
            '{"currentStreak":4,"longestStreak":4,"lastGoalMetDate":"$twoDaysAgo","lastSeenDate":"$twoDaysAgo","lifetimeCups":10}',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MeowdrateApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      final openingLine = container.read(openingLineOverrideProvider);
      expect(goalMissedLines, contains(openingLine));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(container.read(openingLineOverrideProvider), openingLine);
    },
  );
}
