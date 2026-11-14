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
String dayLabel(CivilDate day, {required CivilDate today}) => dateLabel(
  year: day.year,
  month: day.month,
  day: day.day,
  thisYear: today.year,
);

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
String signedAmountLabel(Money amount) => signedMoney(amount);

/// What the operation does to the money: `−370 ₽` and `+370 ₽`, and `370 ₽` for
/// a transfer, which only moves it. A transfer of a debt says what it did to
/// the account of the person: `−5 000 ₽` lent, `+2 000 ₽` back (ADR 0029).
String operationAmount(Operation operation) {
  final own = operation.ownAccount;
  if (own != null) return signedAmountLabel(operation.amountOn(own.id));
  return operation.kind == TransactionKind.transfer
      ? formatMoney(operation.amount.abs())
      : signedAmountLabel(operation.amount);
}

/// What [move] did, after the name of the other person: «в долг»,
/// «возврат», «заняли» or «отдали».
String debtMoveLabel(DebtMove move) => switch (move) {
  DebtMove.lent => t.transactions.debt.lent,
  DebtMove.returned => t.transactions.debt.returned,
  DebtMove.borrowed => t.transactions.debt.borrowed,
  DebtMove.repaid => t.transactions.debt.repaid,
};

/// What the operation does to account [accountId], with a sign even for a
/// transfer, which brings money to one account and takes it from the other.
String operationAmountOn(Operation operation, String accountId) =>
    signedAmountLabel(operation.amountOn(accountId));

/// The main line of an operation: the note, or what it is for. A transfer of
/// a debt names the other person and what it did: «Маша · в долг».
String operationTitle(Operation operation) {
  final debt = operation.debt;
  final move = operation.debtMove;
  if (debt != null && move != null) {
    return '${debt.name} · ${debtMoveLabel(move)}';
  }
  if (operation.note.isNotEmpty) return operation.note;
  return operation.category?.name ?? transactionKindLabel(operation.kind);
}

/// The quieter line of an operation: what the title leaves out. A transfer of
/// a debt says that it is one, then the account of the person and the note:
/// «Долг · Наличные · на билеты».
String operationSubtitle(Operation operation) {
  final own = operation.ownAccount;
  if (own != null) {
    return [
      t.transactions.debt.title,
      own.name,
      if (operation.note.isNotEmpty) operation.note,
    ].join(' · ');
  }
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
