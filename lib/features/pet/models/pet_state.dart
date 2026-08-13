class PetState {
  const PetState({
    this.points = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastGoalMetDate,
    this.unlockedItemIds = const {'none'},
    this.equippedItemId = 'none',
  });

  final int points;
  final int currentStreak;
  final int longestStreak;

  /// ISO date string (yyyy-MM-dd) of the last day the daily goal was met.
  final String? lastGoalMetDate;
  final Set<String> unlockedItemIds;
  final String equippedItemId;

  PetState copyWith({
    int? points,
    int? currentStreak,
    int? longestStreak,
    String? lastGoalMetDate,
    Set<String>? unlockedItemIds,
    String? equippedItemId,
  }) {
    return PetState(
      points: points ?? this.points,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastGoalMetDate: lastGoalMetDate ?? this.lastGoalMetDate,
      unlockedItemIds: unlockedItemIds ?? this.unlockedItemIds,
      equippedItemId: equippedItemId ?? this.equippedItemId,
    );
  }

  factory PetState.fromJson(Map<String, dynamic> json) {
    return PetState(
      points: json['points'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastGoalMetDate: json['lastGoalMetDate'] as String?,
      unlockedItemIds: ((json['unlockedItemIds'] as List?)?.cast<String>().toSet()) ??
          {'none'},
      equippedItemId: json['equippedItemId'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() => {
        'points': points,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastGoalMetDate': lastGoalMetDate,
        'unlockedItemIds': unlockedItemIds.toList(),
        'equippedItemId': equippedItemId,
      };
}
