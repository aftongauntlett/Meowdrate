import SwiftUI
import WidgetKit

/// iOS counterpart of android/app/.../widget/HydrationWidgetProvider.kt.
/// Renders today's glass count with Pochi's mood art. All state (count,
/// goal, mood) is computed Dart-side by HomeWidgetSyncService and just read
/// back here — no hydration/day-boundary logic is duplicated natively.

/// Must match _iOSAppGroupId in lib/core/home_widget/home_widget_sync_service.dart.
private let appGroupId = "group.com.aftongauntlett.meowdrate"

private enum Keys {
  static let glassesCount = "glasses_count"
  static let glassesGoal = "glasses_goal"
  static let mood = "mood"
}

struct HydrationEntry: TimelineEntry {
  let date: Date
  let glassesCount: Int
  let glassesGoal: Int
  let mood: String

  var catImageName: String {
    switch mood {
    case "happy": return "pochi_widget_happy"
    case "neutral": return "pochi_widget_neutral"
    default: return "pochi_widget_sad"
    }
  }

  static let placeholder = HydrationEntry(date: Date(), glassesCount: 4, glassesGoal: 7, mood: "neutral")
}

struct HydrationProvider: TimelineProvider {
  func placeholder(in context: Context) -> HydrationEntry {
    .placeholder
  }

  func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> Void) {
    completion(context.isPreview ? .placeholder : readEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
    // The app calls HomeWidget.updateWidget whenever the data changes, so
    // there's nothing to poll for.
    completion(Timeline(entries: [readEntry()], policy: .never))
  }

  private func readEntry() -> HydrationEntry {
    let defaults = UserDefaults(suiteName: appGroupId)
    let goal = defaults?.object(forKey: Keys.glassesGoal) as? Int ?? 7
    return HydrationEntry(
      date: Date(),
      glassesCount: defaults?.integer(forKey: Keys.glassesCount) ?? 0,
      glassesGoal: goal,
      mood: defaults?.string(forKey: Keys.mood) ?? "sad"
    )
  }
}

struct HydrationWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: HydrationEntry

  var body: some View {
    content
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Meowdrate: \(entry.glassesCount) of \(entry.glassesGoal) glasses today")
      .widgetBackground(Color("WidgetBackground"))
  }

  @ViewBuilder
  private var content: some View {
    if family == .systemSmall {
      VStack(alignment: .leading, spacing: 6) {
        cat.frame(width: 56, height: 56)
        Spacer(minLength: 0)
        labels
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    } else {
      HStack(spacing: 12) {
        cat.frame(width: 72, height: 72)
        labels
        Spacer(minLength: 0)
      }
    }
  }

  private var cat: some View {
    Image(entry.catImageName)
      .resizable()
      .interpolation(.none)
      .scaledToFit()
  }

  private var labels: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(entry.glassesCount) of \(entry.glassesGoal)")
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(Color("WidgetText"))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text("glasses today")
        .font(.system(size: 13))
        .foregroundColor(Color("WidgetTextMuted"))
        .lineLimit(1)
    }
  }
}

private extension View {
  /// iOS 17 requires widgets to declare their background via
  /// containerBackground; earlier versions just draw it behind the content.
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      padding().background(color)
    }
  }
}

@main
struct MeowdrateWidget: Widget {
  /// Must match _iOSWidgetName in lib/core/home_widget/home_widget_sync_service.dart.
  let kind = "MeowdrateWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HydrationProvider()) { entry in
      HydrationWidgetView(entry: entry)
    }
    .configurationDisplayName("Meowdrate")
    .description("Today's glass count, with Pochi reacting to your progress")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
