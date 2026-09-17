import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meowdrate/core/utils/shuffle_bag.dart';

void main() {
  group('ShuffleBag', () {
    test('emits every index exactly once before any repeat', () {
      final bag = ShuffleBag(10, random: Random(1));
      final firstCycle = List.generate(10, (_) => bag.next());
      expect(firstCycle.toSet(), hasLength(10));
      expect(firstCycle, everyElement(inInclusiveRange(0, 9)));
    });

    test('never repeats the previous cycle\'s last item as the next cycle\'s first', () {
      final bag = ShuffleBag(3, random: Random(42));
      int? previousLast;
      for (var cycle = 0; cycle < 50; cycle++) {
        final indices = List.generate(3, (_) => bag.next());
        if (previousLast != null) {
          expect(indices.first, isNot(previousLast));
        }
        previousLast = indices.last;
      }
    });

    test('a poolLength of 1 always returns the same index', () {
      final bag = ShuffleBag(1);
      expect(bag.next(), 0);
      expect(bag.next(), 0);
    });

    test('resumes from a persisted queue instead of reshuffling', () {
      final bag = ShuffleBag(4, queue: [3, 1]);
      expect(bag.next(), 3);
      expect(bag.next(), 1);
    });

    test('drops out-of-range entries from a restored queue', () {
      // Simulates a pool that shrank since the queue was last persisted.
      final bag = ShuffleBag(2, queue: [3, 1, 5]);
      expect(bag.next(), 1);
    });

    test('remaining reflects what is left in the queue', () {
      final bag = ShuffleBag(4, queue: [2, 0, 1, 3]);
      bag.next();
      expect(bag.remaining, [0, 1, 3]);
    });
  });
}
