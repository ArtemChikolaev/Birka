import 'package:ledger/ledger.dart' show AccountBalance;
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/src/rate_book.dart';

/// What the accounts that count hold, added up in one currency.
@immutable
final class Capital {
  /// Creates a capital.
  const Capital({
    this.main,
    this.others = const [],
    this.currencies = 0,
    this.converted = false,
  });

  /// Adds up [accounts], without those outside the totals. Everything turns
  /// into [base], or into the currency of the first account when none is
  /// picked or when nothing can reach the picked one yet.
  factory Capital.of(
    List<AccountBalance> accounts, {
    required RateBook rates,
    Currency? base,
  }) {
    final held = <Currency, int>{};
    for (final AccountBalance(:account, :balance) in accounts) {
      if (!account.includeInTotals) continue;
      held[balance.currency] =
          (held[balance.currency] ?? 0) + balance.minorUnits;
    }
    if (held.isEmpty) return const Capital();
    final picked = base ?? held.keys.first;
    final reachable = held.keys.any((from) => rates.canConvert(from, picked));
    final target = reachable ? picked : held.keys.first;

    final amounts = [
      for (final MapEntry(key: currency, value: minorUnits) in held.entries)
        _money(minorUnits, currency),
    ];
    final counted = [
      for (final amount in amounts)
        if (rates.canConvert(amount.currency, target)) amount,
    ];
    return Capital(
      main: rates.sum(counted, target),
      others: [
        for (final amount in amounts)
          if (!rates.canConvert(amount.currency, target)) amount,
      ],
      currencies: held.length,
      converted: counted.any((amount) => amount.currency != target),
    );
  }

  static Money _money(int minorUnits, Currency currency) => Money(
    minorUnits.clamp(-Money.maxMinorUnits, Money.maxMinorUnits),
    currency,
  );

  /// What the accounts come to, or `null` without accounts that count.
  final Money? main;

  /// The amounts that no rate can turn into [main] yet.
  final List<Money> others;

  /// How many currencies the accounts hold.
  final int currencies;

  /// Whether [main] went through a rate.
  final bool converted;
}
