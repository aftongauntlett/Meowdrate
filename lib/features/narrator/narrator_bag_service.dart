import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_store.dart';
import '../../core/utils/iso_date.dart';
import '../../core/utils/shuffle_bag.dart';
import '../hydration/providers/hydration_providers.dart';
import 'narrator_trigger.dart';

const _storageKey = 'narrator.bags.v1';

/// Which lines have already been assigned today for a trigger whose
/// selection is re-derived reactively (drinkLogged, goalMet) rather than
/// pulled once at a discrete event — see [NarratorBagService.pull].
class _DailyAssignments {
  _DailyAssignments(this.date);
  String date;
  final Map<int, String> byOccurrence = {};
}

/// Hands out narrator lines via a per-trigger [ShuffleBag] instead of the
/// old date-seeded pick: every line in a pool is shown once before any of
/// them repeat, and the bag's remaining order is persisted so it survives
/// closing and reopening the app rather than reshuffling every session.
///
/// Loaded lazily and asynchronously (see [_load]): a pull that happens
/// before the load finishes just gets a freshly shuffled bag instead of
/// the persisted one — the same "swallow it, don't block on it" tolerance
/// [SoundService]'s own async setup uses, and low-stakes for a flavor
/// line.
class NarratorBagService {
  NarratorBagService(this._store) {
    unawaited(_load());
  }

  final LocalStore _store;
  final Map<NarratorTrigger, ShuffleBag> _bags = {};
  final Map<NarratorTrigger, _DailyAssignments> _dailyAssignments = {};

  /// Picks the next line for [trigger] from [pool].
  ///
  /// With [occurrence] left null, every call pulls a fresh line — correct
  /// for triggers that are only ever selected once per real, discrete
  /// event (app open, settings closed, drink skipped, ...).
  ///
  /// With [occurrence] set, the same (trigger, occurrence) pair always
  /// returns the same line for the rest of the day: [currentNarratorLineProvider]
  /// re-derives drinkLogged/goalMet reactively (e.g. a settings change can
  /// rebuild it without a new drink), and without this memoization that
  /// rebuild would silently burn another line from the bag despite
  /// nothing having actually happened.
  String pull(NarratorTrigger trigger, List<String> pool, {int? occurrence}) {
    if (occurrence == null) {
      return _pullFresh(trigger, pool);
    }

    final today = isoDate(DateTime.now());
    final assignments = _dailyAssignments.putIfAbsent(
      trigger,
      () => _DailyAssignments(today),
    );
    if (assignments.date != today) {
      assignments.date = today;
      assignments.byOccurrence.clear();
    }
    return assignments.byOccurrence.putIfAbsent(
      occurrence,
      () => _pullFresh(trigger, pool),
    );
  }

  /// Debug-only: wipes every bag and the daily-assignment cache, both in
  /// memory and on disk, for exercising the fresh-install experience.
  Future<void> debugReset() async {
    _bags.clear();
    _dailyAssignments.clear();
    await _store.writeJson(_storageKey, const {});
  }

  String _pullFresh(NarratorTrigger trigger, List<String> pool) {
    final bag = _bagFor(trigger, pool.length);
    final line = pool[bag.next()];
    unawaited(_persist());
    return line;
  }

  ShuffleBag _bagFor(NarratorTrigger trigger, int poolLength) {
    final existing = _bags[trigger];
    if (existing != null && existing.poolLength == poolLength) {
      return existing;
    }
    final created = ShuffleBag(poolLength);
    _bags[trigger] = created;
    return created;
  }

  Future<void> _load() async {
    try {
      final json = await _store.readJson(_storageKey);
      if (json == null) {
        return;
      }
      for (final trigger in NarratorTrigger.values) {
        if (_bags.containsKey(trigger)) {
          // Already pulled from (and so already given a fresh in-memory
          // bag) before this load finished — the persisted order is
          // stale for it now, keep what's already in memory instead of
          // rewinding it.
          continue;
        }
        final entry = json[trigger.name];
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final poolLength = entry['poolLength'] as int?;
        final queue = (entry['queue'] as List<dynamic>?)?.cast<int>();
        if (poolLength == null || queue == null) {
          continue;
        }
        _bags[trigger] = ShuffleBag(poolLength, queue: queue);
      }
    } catch (_) {
      // Corrupt/missing local storage — fall back to fresh bags, same
      // tolerance every other local-store read in this app already has.
    }
  }

  Future<void> _persist() async {
    final json = <String, dynamic>{
      for (final entry in _bags.entries)
        entry.key.name: {
          'poolLength': entry.value.poolLength,
          'queue': entry.value.remaining,
        },
    };
    await _store.writeJson(_storageKey, json);
  }
}

final narratorBagServiceProvider = Provider<NarratorBagService>((ref) {
  return NarratorBagService(ref.watch(localStoreProvider));
});
