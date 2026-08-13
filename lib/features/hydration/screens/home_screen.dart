import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../pet/providers/pet_providers.dart';
import '../../pet/widgets/pet_view.dart';
import '../../reminders/reminder_service.dart';
import '../../shop/models/shop_item.dart';
import '../../shop/screens/shop_screen.dart';
import '../hydration_constants.dart';
import '../models/hydration_entry.dart';
import '../providers/hydration_providers.dart';
import 'drink_moment_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _syncReminderState();
  }

  Future<void> _syncReminderState() async {
    try {
      final pending = await reminderService.pending();
      if (!mounted) {
        return;
      }
      setState(() => _remindersEnabled = pending.isNotEmpty);
    } catch (_) {
      // Notifications aren't available on this platform/environment.
    }
  }

  Future<void> _toggleReminders() async {
    try {
      if (_remindersEnabled) {
        await reminderService.cancelReminders();
        setState(() => _remindersEnabled = false);
        return;
      }

      final granted = await reminderService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission was denied.')),
        );
        return;
      }

      await reminderService.scheduleHourlyReminder();
      setState(() => _remindersEnabled = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminders aren’t available on this platform.')),
      );
    }
  }

  Future<void> _openDrinkMoment() async {
    final didLogDrink = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DrinkMomentScreen()),
    );

    if (didLogDrink == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nice — drink logged.')),
      );
    }
  }

  void _openShop() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(hydrationSummaryProvider);
    final petAsync = ref.watch(petStateProvider);
    final mood = ref.watch(petMoodProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(hydrationSummaryProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(
              top: AppSpacing.xl,
              bottom: AppSpacing.xxl,
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Water Buddy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  IconButton(
                    tooltip: _remindersEnabled ? 'Reminders on' : 'Reminders off',
                    onPressed: _toggleReminders,
                    icon: Icon(
                      _remindersEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: _remindersEnabled ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: PetView(
                  mood: mood,
                  accessoryEmoji: petAsync.maybeWhen(
                    data: (pet) => _emojiFor(pet.equippedItemId),
                    orElse: () => null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  mood.label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              summaryAsync.when(
                data: (summary) => _ProgressCard(summary: summary),
                loading: () => const _ProgressCard(summary: DrinksTodaySummary.empty),
                error: (_, _) => const _ProgressCard(summary: DrinksTodaySummary.empty),
              ),
              const SizedBox(height: AppSpacing.lg),
              petAsync.when(
                data: (pet) => _StatsRow(
                  points: pet.points,
                  streak: pet.currentStreak,
                  onTapShop: _openShop,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openDrinkMoment,
                  child: const Text('Log a drink'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              summaryAsync.maybeWhen(
                data: (summary) => _RecentList(entries: summary.recent),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _emojiFor(String equippedItemId) {
    if (equippedItemId == 'none') {
      return null;
    }
    for (final item in shopCatalog) {
      if (item.id == equippedItemId) {
        return item.emoji;
      }
    }
    return null;
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary});

  final DrinksTodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final progress = (summary.totalAmountMl / kDailyGoalMl).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${summary.totalAmountMl} / $kDailyGoalMl ml',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${summary.count} drinks today',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.points,
    required this.streak,
    required this.onTapShop,
  });

  final int points;
  final int streak;
  final VoidCallback onTapShop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatChip(icon: '🔥', label: '$streak day streak')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: onTapShop,
            child: _StatChip(icon: '💎', label: '$points points'),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.entries});

  final List<HydrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (entries.isEmpty)
            const Text('No drinks yet.', style: TextStyle(color: AppColors.textMuted))
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${_formatTime(entry.timestamp)} • ${entry.amountMl} ml',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int timestampMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
