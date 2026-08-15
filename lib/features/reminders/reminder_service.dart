import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'hydration_reminders';
const _channelName = 'Hydration reminders';

/// Fixed active window — no reminders overnight (see kDefaultReminderStartHour
/// below for why this isn't user-configurable).
const kDefaultReminderStartHour = 7;
const kDefaultReminderEndHour = 22;

/// How often a nudge can fire, at most.
const kReminderInterval = Duration(hours: 3);

/// One id per pre-scheduled slot. Local notifications can't evaluate "has
/// the user already logged a drink?" at fire time, so instead of one
/// repeating daily alarm this pre-schedules a short run of single-shot
/// slots ahead of time (enough to cover the rest of today's window even if
/// the app never reopens) and relies on ReminderCoordinator.reconcile() to
/// cancel-and-reschedule them the moment something relevant actually
/// changes (a drink gets logged, the goal is hit, the app reopens).
const _baseNotificationId = 1000;
const _maxScheduledSlots = 6;

/// Wraps flutter_local_notifications for "drink water" reminders, entirely
/// client-side, no backend/push infrastructure required.
class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _tzReady = false;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );
  }

  /// zonedSchedule needs the IANA tz database loaded and the device's real
  /// local zone set — otherwise "7am" would mean 7am UTC, not 7am for
  /// whoever's holding the phone. Done lazily, once, on first schedule
  /// rather than in init() so a lookup failure can't block app startup.
  Future<void> _ensureTimeZone() async {
    if (_tzReady) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ReminderService: falling back to UTC ($error)');
      }
    }
    _tzReady = true;
  }

  Future<bool> requestPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return granted ?? false;
      case TargetPlatform.iOS:
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      case TargetPlatform.macOS:
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      default:
        // Web and other platforms: nothing to explicitly request here.
        return true;
    }
  }

  /// Cancels whatever's pending and schedules a fresh run of single-shot
  /// nudges starting [kReminderInterval] after [referenceTime] — typically
  /// "now" or the last logged drink, whichever the caller wants the
  /// cadence to count from (see ReminderCoordinator). Each slot lands
  /// inside [startHour]..[endHour] (rolling into tomorrow's window if
  /// [referenceTime] is already past the end of today's), capped at
  /// [_maxScheduledSlots] so this never reaches more than a day or so
  /// ahead — anything further out is stale by the time it'd matter anyway,
  /// and will get recomputed the next time reconcile() runs.
  Future<void> scheduleNextReminders(
    DateTime referenceTime, {
    int startHour = kDefaultReminderStartHour,
    int endHour = kDefaultReminderEndHour,
    Duration interval = kReminderInterval,
  }) async {
    await _ensureTimeZone();
    await cancelReminders();

    var next = _clampIntoWindow(referenceTime.add(interval), startHour: startHour, endHour: endHour);
    for (var i = 0; i < _maxScheduledSlots; i++) {
      await _plugin.zonedSchedule(
        id: _baseNotificationId + i,
        title: 'The water isn\'t going to drink itself.',
        body: 'The kitty is counting on you. Just saying.',
        scheduledDate: tz.TZDateTime.from(next, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Periodic reminders to log water and please the cat.',
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      next = _clampIntoWindow(next.add(interval), startHour: startHour, endHour: endHour);
    }
  }

  Future<void> cancelReminders() async {
    for (var i = 0; i < _maxScheduledSlots; i++) {
      await _plugin.cancel(id: _baseNotificationId + i);
    }
  }

  Future<List<PendingNotificationRequest>> pending() {
    return _plugin.pendingNotificationRequests();
  }
}

/// Pushes [dt] forward into the next moment that falls inside
/// [startHour]..[endHour] (inclusive, local time) — before the window
/// moves it to today's start, after it rolls to tomorrow's start.
DateTime _clampIntoWindow(DateTime dt, {required int startHour, required int endHour}) {
  if (dt.hour < startHour) {
    return DateTime(dt.year, dt.month, dt.day, startHour);
  }
  if (dt.hour > endHour) {
    final next = dt.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, startHour);
  }
  return dt;
}

final reminderService = ReminderService();
