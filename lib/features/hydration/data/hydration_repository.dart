import '../../../core/storage/local_store.dart';
import '../models/hydration_entry.dart';

const _storageKey = 'hydration.drinks.v1';

/// Port of the original hydrationStorage.ts + hydrationService.ts.
class HydrationRepository {
  const HydrationRepository(this._store);

  final LocalStore _store;

  Future<List<HydrationEntry>> getAllDrinks() async {
    final json = await _store.readJson(_storageKey);
    final rawDrinks = json?['drinks'];
    if (rawDrinks is! List) {
      return [];
    }

    return rawDrinks
        .whereType<Map<String, dynamic>>()
        .map(HydrationEntry.fromJson)
        .toList();
  }

  Future<HydrationEntry> logDrink(int amountMl, {DateTime? at}) async {
    final entry = HydrationEntry(
      timestamp: (at ?? DateTime.now()).millisecondsSinceEpoch,
      amountMl: amountMl,
    );

    final drinks = await getAllDrinks();
    drinks.add(entry);
    await _store.writeJson(_storageKey, {
      'drinks': drinks.map((d) => d.toJson()).toList(),
    });

    return entry;
  }

  Future<void> clearAll() async {
    await _store.writeJson(_storageKey, {'drinks': <Map<String, dynamic>>[]});
  }

  Future<List<HydrationEntry>> getDrinksToday({DateTime? now}) async {
    final drinks = await getAllDrinks();
    final start = _startOfDay(now ?? DateTime.now());
    final end = start.add(const Duration(days: 1));

    final todays = drinks.where((d) {
      final at = DateTime.fromMillisecondsSinceEpoch(d.timestamp);
      return !at.isBefore(start) && at.isBefore(end);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return todays;
  }

  Future<DrinksTodaySummary> getDrinksTodaySummary({DateTime? now}) async {
    final drinksToday = await getDrinksToday(now: now);
    final totalAmountMl = drinksToday.fold<int>(0, (sum, e) => sum + e.amountMl);

    return DrinksTodaySummary(
      count: drinksToday.length,
      totalAmountMl: totalAmountMl,
      // Every drink today, not just the last few — the Recent card grows
      // to fit the whole list rather than capping it (see RecentDrinksList).
      recent: drinksToday,
    );
  }

  /// The "day" for hydration purposes runs 2am-to-2am, not midnight-to-
  /// midnight — a drink logged at 1am still counts toward the day that's
  /// ending, rather than starting a fresh "today" (and a fresh flood/recent
  /// list) at the stroke of midnight.
  DateTime _startOfDay(DateTime now) {
    final todayBoundary = DateTime(now.year, now.month, now.day, 2);
    return now.isBefore(todayBoundary)
        ? todayBoundary.subtract(const Duration(days: 1))
        : todayBoundary;
  }
}
