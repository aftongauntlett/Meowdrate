class HydrationEntry {
  const HydrationEntry({required this.timestamp, required this.amountMl});

  final int timestamp;
  final int amountMl;

  factory HydrationEntry.fromJson(Map<String, dynamic> json) {
    return HydrationEntry(
      timestamp: json['timestamp'] as int,
      amountMl: json['amountMl'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'amountMl': amountMl,
      };
}

class DrinksTodaySummary {
  const DrinksTodaySummary({
    required this.count,
    required this.totalAmountMl,
    required this.recent,
  });

  final int count;
  final int totalAmountMl;
  final List<HydrationEntry> recent;

  static const empty = DrinksTodaySummary(count: 0, totalAmountMl: 0, recent: []);
}
