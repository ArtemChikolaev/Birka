import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:rational/rational.dart';

/// An expense on one account and an income on another that look like one
/// transfer of the person between them (ADR 0022): what left one reached
/// the other, as a top-up from a card abroad or a payment to one's own
/// account in another bank.
@immutable
final class TransferPair {
  /// Creates the pair.
  const TransferPair({required this.out, required this.into});

  /// The money that left one account.
  final Transaction out;

  /// The money that reached the other, which waits for a category.
  final Transaction into;

  /// What tells the pair from others, to keep that it is not a transfer.
  String get key => '${out.id}>${into.id}';

  /// What left, as a positive amount.
  Money get sent => -out.entries.single.amount;

  /// What arrived.
  Money get received => into.entries.single.amount;

  /// The account that the money left.
  String get fromAccountId => out.entries.single.accountId;

  /// The account that the money reached.
  String get toAccountId => into.entries.single.accountId;
}

/// The transfers that [transactions] hide (ADR 0022): an income without a
/// category on one account and an expense on another within [days] days of
/// it, of the same amount in one currency, or within [percent] percent of
/// the rate of [rates] on the day the money left between two currencies.
/// Each transaction is in one pair at most, the closest first, and the pairs
/// of [dismissed] stay out.
List<TransferPair> transferPairs(
  List<Transaction> transactions, {
  required RateBook rates,
  Set<String> dismissed = const {},
  int days = 3,
  int percent = 10,
}) {
  final tolerance = Rational(BigInt.from(percent), BigInt.from(100));
  bool single(Transaction transaction) => transaction.entries.length == 1;
  final incomes = [
    for (final transaction in transactions)
      if (transaction.kind == TransactionKind.income &&
          single(transaction) &&
          transaction.allocations.every((it) => it.categoryId == null))
        transaction,
  ];
  final expenses = [
    for (final transaction in transactions)
      if (transaction.kind == TransactionKind.expense && single(transaction))
        transaction,
  ];
  final candidates = <({TransferPair pair, int apart, Rational off})>[];
  for (final into in incomes) {
    for (final out in expenses) {
      final pair = TransferPair(out: out, into: into);
      if (pair.fromAccountId == pair.toAccountId) continue;
      if (dismissed.contains(pair.key)) continue;
      final apart = _daysBetween(out.occurredOn, into.occurredOn).abs();
      if (apart > days) continue;
      final off = _offBy(pair, rates);
      if (off == null || off > tolerance) continue;
      candidates.add((pair: pair, apart: apart, off: off));
    }
  }
  candidates.sort((a, b) {
    final byDays = a.apart.compareTo(b.apart);
    return byDays != 0 ? byDays : a.off.compareTo(b.off);
  });
  final used = <String>{};
  final pairs = <TransferPair>[];
  for (final (:pair, apart: _, off: _) in candidates) {
    if (used.contains(pair.out.id) || used.contains(pair.into.id)) continue;
    used
      ..add(pair.out.id)
      ..add(pair.into.id);
    pairs.add(pair);
  }
  return pairs;
}

/// How far what arrived is from what left, as an exact share: zero for the
/// same amount in one currency, `null` when it cannot be one transfer.
Rational? _offBy(TransferPair pair, RateBook rates) {
  final sent = pair.sent;
  final received = pair.received;
  if (sent.currency == received.currency) {
    return sent == received ? Rational.zero : null;
  }
  final expected = rates.convert(
    sent,
    received.currency,
    on: pair.out.occurredOn,
  );
  if (expected == null || !expected.isPositive) return null;
  return Rational(
    BigInt.from(received.minorUnits - expected.minorUnits).abs(),
    BigInt.from(expected.minorUnits),
  );
}

int _daysBetween(CivilDate a, CivilDate b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
