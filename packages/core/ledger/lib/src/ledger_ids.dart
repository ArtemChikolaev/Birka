import 'dart:math';

import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

/// The ids of the ledger in the order they are made (ADR 0009): UUIDv7,
/// whose twelve bits after the version count up within one millisecond, as
/// RFC 9562 allows, so that two records of one millisecond sort as they were
/// written.
///
/// A clock that goes back leaves the time where it was, and a millisecond
/// that needs more ids than its count holds goes on into the next one.
final class LedgerIds {
  /// Creates the ids on the clock of [now], with [random] for the bits that
  /// only tell ids apart.
  LedgerIds({DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _now;
  final Random _random;
  var _time = -1;
  var _count = 0;

  /// The largest count of a millisecond, in twelve bits.
  static const _most = 0xFFF;

  /// The count of a new millisecond starts below this, which leaves at least
  /// half of it for the ids after.
  static const _start = 0x800;

  /// A new id, after every one made before it.
  String call() {
    final time = _now().millisecondsSinceEpoch;
    if (time > _time) {
      _time = time;
      _count = _random.nextInt(_start);
    } else if (_count < _most) {
      _count++;
    } else {
      _time++;
      _count = _random.nextInt(_start);
    }
    return const Uuid().v7(
      config: V7Options(_time, [
        _count >> 8,
        _count & 0xFF,
        for (var byte = 0; byte < 8; byte++) _random.nextInt(256),
      ]),
    );
  }
}
