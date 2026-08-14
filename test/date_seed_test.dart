import 'package:flutter_test/flutter_test.dart';
import 'package:meowdrate/core/utils/date_seed.dart';

void main() {
  group('dateSeededIndex', () {
    test('same date/salt/occurrence always yields the same index', () {
      final date = DateTime(2026, 8, 13);
      expect(
        dateSeededIndex(date, 25, salt: 1, occurrence: 3),
        dateSeededIndex(date, 25, salt: 1, occurrence: 3),
      );
    });

    test('index stays within bounds across a wide range of dates/pools', () {
      final start = DateTime(2026, 1, 1);
      for (var poolLength = 1; poolLength <= 30; poolLength++) {
        for (var day = 0; day < 400; day++) {
          final index = dateSeededIndex(
            start.add(Duration(days: day)),
            poolLength,
            salt: 7,
            occurrence: day % 5,
          );
          expect(index, inInclusiveRange(0, poolLength - 1));
        }
      }
    });

    test('different salts can diverge for the same date', () {
      final start = DateTime(2026, 8, 13);
      var anyDifferent = false;
      for (var day = 0; day < 30; day++) {
        final date = start.add(Duration(days: day));
        if (dateSeededIndex(date, 100, salt: 1) != dateSeededIndex(date, 100, salt: 2)) {
          anyDifferent = true;
          break;
        }
      }
      expect(anyDifferent, isTrue);
    });
  });
}
