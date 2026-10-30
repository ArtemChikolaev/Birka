import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The name of [type].
String accountTypeLabel(AccountType type) =>
    t.accounts.types[type.name] ?? type.name;

/// The quiet line of an account: `Рубли · •• 4568` or `Рубли · Вклад`.
String accountSubtitle({
  required Currency currency,
  required AccountType type,
  String? lastDigits,
}) {
  final name = t.app.currencies[currency.code] ?? currency.code;
  final detail = lastDigits == null || lastDigits.isEmpty
      ? accountTypeLabel(type)
      : '•• $lastDigits';
  return '$name · $detail';
}
