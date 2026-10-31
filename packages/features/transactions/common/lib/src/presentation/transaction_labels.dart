import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:transactions_common/src/domain/amount_expression.dart';

/// The name of [kind] on the switch of quick add.
String transactionKindLabel(TransactionKind kind) => switch (kind) {
  TransactionKind.expense => t.transactions.expense,
  TransactionKind.income => t.transactions.income,
  TransactionKind.transfer => t.transactions.transfer,
  TransactionKind.adjustment => t.transactions.adjustment,
};

/// A day for people: `30 октября` or `October 30`, with the year when it is
/// not the year of [today].
String dayLabel(CivilDate day, {required CivilDate today}) {
  final date = t.transactions.dayOfMonth(
    day: day.day,
    month: t.transactions.months[day.month - 1],
  );
  return day.year == today.year ? date : '$date ${day.year}';
}

/// What [expression] comes to for [kind]: `−370 ₽`, `+370 ₽` or `370 ₽`, and a
/// dash when it comes to nothing, such as after a division by zero.
String amountLabel(
  TransactionKind kind,
  AmountExpression expression,
  Currency currency,
) {
  final amount = expression.isEmpty
      ? Money.zero(currency)
      : expression.valueIn(currency);
  if (amount == null) return '—';
  if (!amount.isPositive) return formatMoney(amount);
  return switch (kind) {
    TransactionKind.expense => formatMoney(-amount),
    TransactionKind.income => '+${formatMoney(amount)}',
    _ => formatMoney(amount),
  };
}
