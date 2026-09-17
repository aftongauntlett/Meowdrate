import 'dart:math';

/// A "no repeat until the pool is exhausted" picker: shuffles the full
/// range of indices [0, poolLength) once, then hands them out from the
/// front in order, only reshuffling once every index has been drawn.
/// Guarantees every index appears exactly once per cycle before any of
/// them repeat — unlike a plain random pick (or a date-seeded one), which
/// can land on the same index on consecutive pulls.
class ShuffleBag {
  ShuffleBag(this.poolLength, {List<int>? queue, Random? random})
      : _random = random ?? Random(),
        _queue = List.of(queue ?? const []) {
    if (poolLength <= 0) {
      throw ArgumentError.value(poolLength, 'poolLength', 'must be positive');
    }
    // A restored queue from a previous, differently-sized pool would hand
    // out indices that no longer exist — drop anything out of range rather
    // than let a stale save crash the first pull after an edit to the pool.
    _queue.removeWhere((index) => index < 0 || index >= poolLength);
    if (_queue.isEmpty) {
      _refill();
    }
  }

  final int poolLength;
  final Random _random;
  final List<int> _queue;
  int? _lastEmitted;

  /// The remaining, not-yet-emitted order — persist this (with
  /// [poolLength]) to resume the same sequence in a later session instead
  /// of reshuffling.
  List<int> get remaining => List.unmodifiable(_queue);

  int next() {
    if (_queue.isEmpty) {
      _refill();
    }
    final index = _queue.removeAt(0);
    _lastEmitted = index;
    return index;
  }

  /// Shuffles a fresh full cycle and swaps its first entry away from
  /// [_lastEmitted] when possible, so the seam between one cycle and the
  /// next doesn't show the same line twice in a row.
  void _refill() {
    final indices = List.generate(poolLength, (i) => i)..shuffle(_random);
    if (poolLength > 1 && indices.first == _lastEmitted) {
      final swapWith = 1 + _random.nextInt(indices.length - 1);
      final tmp = indices[0];
      indices[0] = indices[swapWith];
      indices[swapWith] = tmp;
    }
    _queue.addAll(indices);
  }
}
