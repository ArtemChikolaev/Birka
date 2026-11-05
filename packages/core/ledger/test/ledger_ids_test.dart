import 'dart:math';

import 'package:ledger/src/ledger_ids.dart';
import 'package:test/test.dart';

/// The text of a UUIDv7: the version 7 and the variant of RFC 9562.
final uuidV7 = RegExp(
  '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-'
  r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// The millisecond an [id] was made in.
int timeOf(String id) =>
    int.parse(id.replaceAll('-', '').substring(0, 12), radix: 16);

/// Expects each of [ids] to come after the one before it.
void expectRising(List<String> ids) {
  for (var i = 1; i < ids.length; i++) {
    expect(
      ids[i].compareTo(ids[i - 1]),
      greaterThan(0),
      reason: '${ids[i]} after ${ids[i - 1]}',
    );
  }
}

void main() {
  final moment = DateTime.utc(2026, 11, 5, 12);
  final millisecond = moment.millisecondsSinceEpoch;

  DateTime shifted(int milliseconds) =>
      moment.add(Duration(milliseconds: milliseconds));

  test('are UUIDv7 of the millisecond they were made in', () {
    final ids = LedgerIds(now: () => moment);
    final id = ids();

    expect(id, matches(uuidV7));
    expect(timeOf(id), millisecond);
  });

  test('take the time of the clock by default', () {
    final ids = LedgerIds();
    final before = DateTime.timestamp().millisecondsSinceEpoch;
    final id = ids();
    final after = DateTime.timestamp().millisecondsSinceEpoch;

    expect(timeOf(id), inInclusiveRange(before, after));
  });

  test('of one millisecond rise in the order they are made', () {
    final ids = LedgerIds(now: () => moment, random: Random(1));
    final made = [for (var i = 0; i < 2000; i++) ids()];

    expectRising(made);
    expect(made.map(timeOf).toSet(), {millisecond});
  });

  test('keep rising when the clock goes back', () {
    final times = [moment, shifted(-5000), shifted(-1)];
    final ids = LedgerIds(now: () => times.removeAt(0));
    final made = [ids(), ids(), ids()];

    expectRising(made);
    expect(made.map(timeOf).toSet(), {millisecond});
  });

  test('go on into the next millisecond when one runs out of them', () {
    var now = moment;
    final ids = LedgerIds(now: () => now, random: Random(2));
    final made = [for (var i = 0; i < 5000; i++) ids()];
    now = shifted(1);
    made.add(ids());
    now = shifted(10);
    made.add(ids());

    expectRising(made);
    expect(timeOf(made[4999]), greaterThan(millisecond));
    expect(timeOf(made.last), millisecond + 10);
  });

  test('are random after the count, which tells devices apart', () {
    final ids = LedgerIds(now: () => moment, random: Random(3));
    final tails = {for (var i = 0; i < 100; i++) ids().substring(19)};

    expect(tails, hasLength(100));
  });
}
