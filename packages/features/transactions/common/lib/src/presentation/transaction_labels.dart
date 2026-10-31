import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:transactions_common/src/domain/amount_expression.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/presentation/operations_cubit.dart';

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

/// The name of [filter] over the list of operations.
String filterLabel(OperationsFilter filter) => switch (filter) {
  OperationsFilter.all => t.transactions.filterAll,
  OperationsFilter.expenses => t.transactions.filterExpenses,
  OperationsFilter.income => t.transactions.filterIncome,
  OperationsFilter.transfers => t.transactions.filterTransfers,
};

/// A month that starts on [month]: `Октябрь` or `October`, with the year when
/// it is not the year of [today].
String monthLabel(CivilDate month, {required CivilDate today}) {
  final name = t.transactions.monthNames[month.month - 1];
  return month.year == today.year ? name : '$name ${month.year}';
}

/// The heading of [day] in a list: today, yesterday or the date.
String dayHeading(CivilDate day, {required CivilDate today}) {
  if (day == today) return t.transactions.today;
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  if (day == CivilDate.of(yesterday)) return t.transactions.yesterday;
  return dayLabel(day, today: today);
}

/// The time of [moment] on the clock of this device: `08:42`.
String timeLabel(DateTime moment) {
  final local = moment.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Where an operation came from.
String sourceLabel(TransactionSource source) => switch (source) {
  TransactionSource.manual => t.transactions.sources.manual,
  TransactionSource.import => t.transactions.sources.import,
  TransactionSource.notification => t.transactions.sources.notification,
  TransactionSource.recurring => t.transactions.sources.recurring,
  TransactionSource.bank => t.transactions.sources.bank,
};

/// [amounts] in one line, with a plus before money that comes in. Amounts in
/// different currencies stay apart until exchange rates can add them up.
String amountsLabel(List<Money> amounts) =>
    amounts.map(signedAmountLabel).join(' · ');

/// [amount] with a plus when it is above zero.
String signedAmountLabel(Money amount) =>
    amount.isPositive ? '+${formatMoney(amount)}' : formatMoney(amount);

/// What the operation does to the money: `−370 ₽` and `+370 ₽`, and `370 ₽` for
/// a transfer, which only moves it.
String operationAmount(Operation operation) =>
    operation.kind == TransactionKind.transfer
    ? formatMoney(operation.amount.abs())
    : signedAmountLabel(operation.amount);

/// The main line of an operation: the note, or what it is for.
String operationTitle(Operation operation) {
  if (operation.note.isNotEmpty) return operation.note;
  return operation.category?.name ?? transactionKindLabel(operation.kind);
}

/// The quieter line of an operation: what the title leaves out.
String operationSubtitle(Operation operation) {
  final account = operation.account?.name ?? '';
  final parts = operation.kind == TransactionKind.transfer
      ? [
          if (operation.note.isNotEmpty) transactionKindLabel(operation.kind),
          '$account → ${operation.toAccount?.name ?? ''}',
        ]
      : [
          if (operation.note.isNotEmpty)
            operation.category?.name ?? transactionKindLabel(operation.kind),
          account,
        ];
  return parts.join(' · ');
}
