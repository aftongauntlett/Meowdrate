import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../pet/providers/pet_providers.dart';
import '../models/shop_item.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Closet')),
      body: petAsync.when(
        data: (pet) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${pet.points} points',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...shopCatalog.map(
              (item) => _ShopItemTile(
                item: item,
                isUnlocked: pet.unlockedItemIds.contains(item.id),
                isEquipped: pet.equippedItemId == item.id,
                canAfford: pet.points >= item.cost,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Something went wrong.', style: TextStyle(color: AppColors.textMuted)),
        ),
      ),
    );
  }
}

class _ShopItemTile extends ConsumerWidget {
  const _ShopItemTile({
    required this.item,
    required this.isUnlocked,
    required this.isEquipped,
    required this.canAfford,
  });

  final ShopItem item;
  final bool isUnlocked;
  final bool isEquipped;
  final bool canAfford;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEquipped ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                ),
                Text(
                  isUnlocked ? 'Unlocked' : '${item.cost} points',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          _ActionButton(
            item: item,
            isUnlocked: isUnlocked,
            isEquipped: isEquipped,
            canAfford: canAfford,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  const _ActionButton({
    required this.item,
    required this.isUnlocked,
    required this.isEquipped,
    required this.canAfford,
  });

  final ShopItem item;
  final bool isUnlocked;
  final bool isEquipped;
  final bool canAfford;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isEquipped) {
      return OutlinedButton(
        onPressed: () => ref.read(petStateProvider.notifier).equipItem('none'),
        child: const Text('Unequip'),
      );
    }

    if (isUnlocked) {
      return ElevatedButton(
        onPressed: () => ref.read(petStateProvider.notifier).equipItem(item.id),
        child: const Text('Equip'),
      );
    }

    return ElevatedButton(
      onPressed: canAfford
          ? () => ref.read(petStateProvider.notifier).unlockItem(item)
          : null,
      child: const Text('Unlock'),
    );
  }
}
