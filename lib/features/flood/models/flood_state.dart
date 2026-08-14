class FloodState {
  const FloodState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastGoalMetDate,
    this.lastSeenDate,
    this.lifetimeCups = 0,
  });

  final int currentStreak;
  final int longestStreak;

  /// ISO date string (yyyy-MM-dd) of the last day the daily goal was met.
  final String? lastGoalMetDate;

  /// ISO date string (yyyy-MM-dd) of the last day the app was opened —
  /// drives quiet day-rollover so a stale streak doesn't linger on screen.
  final String? lastSeenDate;

  final int lifetimeCups;

  FloodState copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastGoalMetDate,
    String? lastSeenDate,
    int? lifetimeCups,
  }) {
    return FloodState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastGoalMetDate: lastGoalMetDate ?? this.lastGoalMetDate,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      lifetimeCups: lifetimeCups ?? this.lifetimeCups,
    );
  }

  factory FloodState.fromJson(Map<String, dynamic> json) {
    return FloodState(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastGoalMetDate: json['lastGoalMetDate'] as String?,
      lastSeenDate: json['lastSeenDate'] as String?,
      lifetimeCups: json['lifetimeCups'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastGoalMetDate': lastGoalMetDate,
        'lastSeenDate': lastSeenDate,
        'lifetimeCups': lifetimeCups,
      };
}
