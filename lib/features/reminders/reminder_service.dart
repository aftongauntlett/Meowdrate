import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _channelId = 'hydration_reminders';
const _channelName = 'Hydration reminders';
const _reminderNotificationId = 1000;

/// Wraps flutter_local_notifications for a single repeating "drink water"
/// reminder — entirely client-side, no backend/push infrastructure required.
class ReminderService {
  ReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

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

  Future<void> scheduleHourlyReminder() async {
    await _plugin.periodicallyShow(
      id: _reminderNotificationId,
      title: 'Your buddy is getting thirsty',
      body: 'Take a sip of water and check in on your pet.',
      repeatInterval: RepeatInterval.hourly,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Periodic reminders to log water and check on your pet.',
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelReminders() async {
    await _plugin.cancel(id: _reminderNotificationId);
  }

  Future<List<PendingNotificationRequest>> pending() {
    return _plugin.pendingNotificationRequests();
  }
}

final reminderService = ReminderService();
