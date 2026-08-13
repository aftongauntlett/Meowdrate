enum PetMood {
  idle,
  happy,
  thirsty;

  String get label {
    switch (this) {
      case PetMood.idle:
        return 'Feeling okay';
      case PetMood.happy:
        return 'Nice and hydrated!';
      case PetMood.thirsty:
        return 'Getting thirsty…';
    }
  }

  /// Lottie/sprite asset name PetView will look for under assets/pet/.
  String get assetName {
    switch (this) {
      case PetMood.idle:
        return 'idle';
      case PetMood.happy:
        return 'happy';
      case PetMood.thirsty:
        return 'thirsty';
    }
  }

  /// Placeholder glyph shown when no asset has been dropped in yet.
  String get placeholderEmoji {
    switch (this) {
      case PetMood.idle:
        return '🐢';
      case PetMood.happy:
        return '🥳';
      case PetMood.thirsty:
        return '🥵';
    }
  }

  static PetMood fromLastDrinkAt(DateTime? lastDrinkAt, {DateTime? now}) {
    if (lastDrinkAt == null) {
      return PetMood.idle;
    }

    final current = now ?? DateTime.now();
    final since = current.difference(lastDrinkAt);

    if (since <= const Duration(minutes: 20)) {
      return PetMood.happy;
    }
    if (since >= const Duration(hours: 3)) {
      return PetMood.thirsty;
    }
    return PetMood.idle;
  }
}
