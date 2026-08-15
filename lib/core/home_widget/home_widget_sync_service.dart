import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/creatures/providers/creature_providers.dart';
import '../../features/hydration/providers/hydration_providers.dart';
import '../../features/settings/providers/daily_goal_providers.dart';

/// Must match the class name of android/app/.../widget/HydrationWidgetProvider.kt.
const _androidWidgetName = 'HydrationWidgetProvider';

/// Pushes today's glass count, goal, and Pochi's mood band to the
/// Android home-screen widget. No streak data is sent — the widget follows
/// the same anti-engagement stance as the in-app home screen (see PRD:
/// "No streak chip on the home screen").
///
/// Android-only for now (see PRD: iOS widget support is a later addition).
class HomeWidgetSyncService {
  HomeWidgetSyncService(this._ref);

  final Ref _ref;

  Future<void> sync() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    // Awaited (rather than a synchronous `.value` read) so a cold app-open
    // — where this runs before either provider has finished its first
    // load — doesn't push a false "0 glasses" snapshot. Once these
    // resolve, moodBandProvider's own reactive read below picks up the now
    // populated values instead of its loading-state fallback.
    final summary = await _ref.read(hydrationSummaryProvider.future);
    final goalGlasses = await _ref.read(dailyGoalGlassesProvider.future);
    final mood = _ref.read(moodBandProvider);

    await HomeWidget.saveWidgetData<int>('glasses_count', summary.count);
    await HomeWidget.saveWidgetData<int>('glasses_goal', goalGlasses);
    await HomeWidget.saveWidgetData<String>('mood', mood.name);
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}

final homeWidgetSyncServiceProvider = Provider((ref) => HomeWidgetSyncService(ref));
