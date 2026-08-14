/// Deterministic index into a pool of size [poolLength], seeded by date +
/// [salt] (e.g. which trigger) + [occurrence] (e.g. which drink of the
/// day). Same inputs always produce the same index, so content varies day
/// to day without a backend while staying stable and debuggable for a
/// given day.
int dateSeededIndex(DateTime date, int poolLength, {int salt = 0, int occurrence = 0}) {
  final dayKey = date.year * 10000 + date.month * 100 + date.day;
  final seed = (dayKey * 31 + salt * 17 + occurrence).abs();
  return seed % poolLength;
}
