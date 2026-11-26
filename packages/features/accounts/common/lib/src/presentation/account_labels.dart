import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The name of [type].
String accountTypeLabel(AccountType type) =>
    t.accounts.types[type.name] ?? type.name;

/// The quiet line of an account: `Рубли · •• 4568` or `Рубли · Вклад`.
String accountSubtitle({
  required Currency currency,
  required AccountType type,
  String? lastDigits,
}) => accountLine(
  currency: currency.code,
  type: type.name,
  lastDigits: lastDigits,
);

/// The currency name used in the account directory, including custom assets.
String holdingName(CurrencyHolding holding) {
  final code = holding.balance.currency.code;
  return t.app.currencies[code] ?? code;
}

/// When a total exceeds the money range, the displayed figure is a bound.
String holdingAmount(CurrencyHolding holding) {
  final amount = formatMoney(holding.balance);
  if (!holding.exceedsRange) return amount;
  return holding.balance.isNegative ? '< $amount' : '> $amount';
}
