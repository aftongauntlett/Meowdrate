enum TimeOfDayBand { dawn, day, dusk, night }

/// Fixed clock-hour bands (local device time, no location permission
/// needed) — not astronomically precise, just enough to give the flood
/// scene a sense of day passing.
TimeOfDayBand bandForHour(int hour) {
  if (hour >= 5 && hour < 7) {
    return TimeOfDayBand.dawn;
  }
  if (hour >= 7 && hour < 18) {
    return TimeOfDayBand.day;
  }
  if (hour >= 18 && hour < 20) {
    return TimeOfDayBand.dusk;
  }
  return TimeOfDayBand.night;
}
