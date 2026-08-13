class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.emoji,
  });

  final String id;
  final String name;
  final int cost;

  /// Placeholder glyph shown until real accessory art/sprites are dropped
  /// into assets/pet/. See PetView for how equipped items are rendered.
  final String emoji;
}

/// A small hardcoded catalog of cosmetic accessories. Swap or extend freely
/// once real assets are sourced — nothing else needs to change.
const shopCatalog = <ShopItem>[
  ShopItem(id: 'bow', name: 'Bow', cost: 30, emoji: '🎀'),
  ShopItem(id: 'glasses', name: 'Sunglasses', cost: 40, emoji: '🕶️'),
  ShopItem(id: 'scarf', name: 'Scarf', cost: 50, emoji: '🧣'),
  ShopItem(id: 'crown', name: 'Crown', cost: 80, emoji: '👑'),
  ShopItem(id: 'flower', name: 'Flower Crown', cost: 60, emoji: '🌸'),
  ShopItem(id: 'top_hat', name: 'Top Hat', cost: 70, emoji: '🎩'),
];
