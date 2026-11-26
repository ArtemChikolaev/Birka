import 'package:ledger/ledger.dart' show AccountBalance;
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/src/rate_book.dart';

/// The native balance of one currency and how many accounts contributed.
typedef CurrencyHolding = ({Money balance, int accounts, bool exceedsRange});

/// What the accounts that count hold, added up in one currency.
@immutable
final class Capital {
  /// Creates a capital.
  const Capital({
    this.main,
    this.others = const [],
    this.currencies = 0,
    this.converted = false,
    this.holdings = const [],
  });

  /// Adds up [accounts], without those outside the totals. Everything turns
  /// into [base], or into the currency of the first account when none is
  /// picked or when nothing can reach the picked one yet.
  factory Capital.of(
    List<AccountBalance> accounts, {
    required RateBook rates,
    Currency? base,
  }) {
    final balances = accounts
        .where((row) => row.account.includeInTotals)
        .map((row) => row.balance);
    final held = <Currency, ({BigInt sum, int accounts})>{};
    for (final balance in balances) {
      final prior = held[balance.currency];
      held[balance.currency] = (
        sum: (prior?.sum ?? BigInt.zero) + BigInt.from(balance.minorUnits),
        accounts: (prior?.accounts ?? 0) + 1,
      );
    }
    if (held.isEmpty) return const Capital();
    final picked = base ?? held.keys.first;
    final reachable = held.keys.any((from) => rates.canConvert(from, picked));
    final target = reachable ? picked : held.keys.first;

    final holdings = [
      for (final MapEntry(:key, :value) in held.entries)
        _holding(key, value.sum, value.accounts),
    ];
    // Convert the original balances: a bounded native subtotal can still
    // cancel against another currency, or fit in the target currency.
    final counted = [
      for (final amount in balances)
        if (rates.canConvert(amount.currency, target)) amount,
    ];
    return Capital(
      main: rates.sum(counted, target),
      others: [
        for (final holding in holdings)
          if (!rates.canConvert(holding.balance.currency, target))
            holding.balance,
      ],
      currencies: holdings.length,
      holdings: holdings,
      converted: counted.any((amount) => amount.currency != target),
    );
  }

  // Cancellation happens before bounding the result, including on JavaScript.
  static CurrencyHolding _holding(Currency currency, BigInt sum, int count) {
    final exceedsRange = sum.abs() > BigInt.from(Money.maxMinorUnits);
    final minor = exceedsRange ? sum.sign * Money.maxMinorUnits : sum.toInt();
    return (
      balance: Money(minor, currency),
      accounts: count,
      exceedsRange: exceedsRange,
    );
  }

  /// Per-currency balances before exchange, in first-account order.
  final List<CurrencyHolding> holdings;

  /// What the accounts come to, or `null` without accounts that count.
  final Money? main;

  /// The amounts that no rate can turn into [main] yet.
  final List<Money> others;

  /// How many currencies the accounts hold.
  final int currencies;

  /// Whether [main] went through a rate.
  final bool converted;
}
