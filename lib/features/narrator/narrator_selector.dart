import '../../core/utils/date_seed.dart';
import 'narrator_line_pools.dart';
import 'narrator_trigger.dart';

String selectNarratorLine(NarratorTrigger trigger, {DateTime? date, int occurrence = 0}) {
  final pool = narratorLinePools[trigger]!;
  final index = dateSeededIndex(
    date ?? DateTime.now(),
    pool.length,
    salt: trigger.index,
    occurrence: occurrence,
  );
  return pool[index];
}
