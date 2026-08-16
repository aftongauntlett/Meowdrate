import 'package:flutter_test/flutter_test.dart';
import 'package:meowdrate/features/reminders/reminder_service.dart';

void main() {
  const startHour = kDefaultReminderStartHour;
  const endHour = kDefaultReminderEndHour;

  test('a time already inside the window is left unchanged', () {
    final dt = DateTime(2026, 3, 5, 14, 30);
    final result = clampIntoWindow(dt, startHour: startHour, endHour: endHour);

    expect(result, dt);
  });

  test('a time before the window snaps up to startHour the same day', () {
    final dt = DateTime(2026, 3, 5, 4);
    final result = clampIntoWindow(dt, startHour: startHour, endHour: endHour);

    expect(result, DateTime(2026, 3, 5, startHour));
  });

  test('a time after the window rolls to startHour the next day', () {
    final dt = DateTime(2026, 3, 5, 23);
    final result = clampIntoWindow(dt, startHour: startHour, endHour: endHour);

    expect(result, DateTime(2026, 3, 6, startHour));
  });

  test('rolling past the end of the month/year carries correctly', () {
    final dt = DateTime(2025, 12, 31, 23);
    final result = clampIntoWindow(dt, startHour: startHour, endHour: endHour);

    expect(result, DateTime(2026, 1, 1, startHour));
  });

  test('exactly startHour is inside the window, not clamped', () {
    final dt = DateTime(2026, 3, 5, startHour);
    final result = clampIntoWindow(dt, startHour: startHour, endHour: endHour);

    expect(result, dt);
  });

  test('exactly endHour is still inside the window, not rolled', () {
    final dt = DateTime(2026, 3, 5, endHour);
    final result = clampIntoWindow(dt, startHour: startHour, endHour: endHour);

    expect(result, dt);
  });

  test('snapping up to startHour drops any leftover minutes', () {
    final dt = DateTime(2026, 3, 5, 4, 45);
    final result = clampIntoWindow(dt, startHour: startHour, endHour: endHour);

    expect(result, DateTime(2026, 3, 5, startHour));
  });
}
