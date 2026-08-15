package com.aftongauntlett.meowdrate.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.aftongauntlett.meowdrate.MainActivity
import com.aftongauntlett.meowdrate.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders today's glass count with Pochi's mood art. All state (count,
 * goal, mood) is computed Dart-side by HomeWidgetSyncService and just read
 * back here — no hydration/day-boundary logic is duplicated natively.
 */
class HydrationWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val glassesCount = widgetData.getInt(KEY_GLASSES_COUNT, 0)
    val glassesGoal = widgetData.getInt(KEY_GLASSES_GOAL, 7)
    val mood = widgetData.getString(KEY_MOOD, MOOD_SAD)

    val catDrawable =
        when (mood) {
          MOOD_HAPPY -> R.drawable.pochi_widget_happy
          MOOD_NEUTRAL -> R.drawable.pochi_widget_neutral
          else -> R.drawable.pochi_widget_sad
        }

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.hydration_widget).apply {
            setImageViewResource(R.id.widget_cat, catDrawable)
            setTextViewText(R.id.widget_count, "$glassesCount of $glassesGoal")
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  companion object {
    private const val KEY_GLASSES_COUNT = "glasses_count"
    private const val KEY_GLASSES_GOAL = "glasses_goal"
    private const val KEY_MOOD = "mood"

    private const val MOOD_SAD = "sad"
    private const val MOOD_NEUTRAL = "neutral"
    private const val MOOD_HAPPY = "happy"
  }
}
