/// Formats a DateTime as a yyyy-MM-dd string — the shared "which day is
/// this" key used across flood streak tracking, narrator/creature
/// selection, and the good-deeds picker.
String isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
