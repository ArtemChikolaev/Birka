import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// A transaction with the accounts and the category it names.
@immutable
final class Operation {
  /// Creates an operation.
  const Operation({
    required this.transaction,
    this.account,
    this.toAccount,
    this.category,
  });

  /// Looks up what [transaction] names. Archived accounts and categories have
  /// to be among [accounts] and [categories], since old operations keep them.
  factory Operation.of(
    Transaction transaction, {
    required Map<String, Account> accounts,
    required Map<String, Category> categories,
  }) {
    final entries = transaction.entries;
    return Operation(
      transaction: transaction,
      account: accounts[entries.first.accountId],
      toAccount: transaction.kind == TransactionKind.transfer
          ? accounts[entries.last.accountId]
          : null,
      category: categories[transaction.allocations.firstOrNull?.categoryId],
    );
  }

  /// The transaction.
  final Transaction transaction;

  /// The account, which money leaves in a transfer.
  final Account? account;

  /// The account a transfer goes to.
  final Account? toAccount;

  /// The category.
  final Category? category;

  /// The id.
  String get id => transaction.id;

  /// What kind of event it is.
  TransactionKind get kind => transaction.kind;

  /// The day it happened.
  CivilDate get day => transaction.occurredOn;

  /// The note of the user.
  String get note => transaction.note;

  /// What it does to the account: below zero when money leaves.
  Money get amount => transaction.entries.first.amount;

  /// What arrives on the other account of a transfer.
  Money? get received =>
      kind == TransactionKind.transfer ? transaction.entries.last.amount : null;

  /// Whether it counts as money spent or earned. A transfer only moves money,
  /// a correction fixes a balance, and a planned operation has not happened.
  bool get counts =>
      (kind == TransactionKind.expense || kind == TransactionKind.income) &&
      transaction.status != TransactionStatus.planned;

  /// Whether quick add can show all of it, which is one category at most and
  /// not a correction.
  bool get canChange =>
      kind != TransactionKind.adjustment && transaction.allocations.length <= 1;

  /// Whether every word of [query] is in the note, in a name or is an amount.
  ///
  /// `250` finds 250 and 250,50, and `250,5` only the second one. Case and the
  /// letter ё do not matter.
  bool matches(String query) {
    final words = _plain(query).split(RegExp(r'\s+'));
    final texts = [
      _plain(note),
      for (final name in [category?.name, account?.name, toAccount?.name])
        if (name != null) _plain(name),
    ];
    return words.every(
      (word) => texts.any((text) => text.contains(word)) || _hasAmount(word),
    );
  }

  bool _hasAmount(String word) {
    final number = word.replaceFirst(',', '.');
    return transaction.entries.any((entry) {
      final amount = entry.amount.abs().toDecimalString();
      return number.contains('.')
          ? amount.startsWith(number)
          : amount.split('.').first == number;
    });
  }

  static String _plain(String text) =>
      text.trim().toLowerCase().replaceAll('ё', 'е');
}

/// The operations of one day.
@immutable
final class OperationDay {
  /// Creates a day.
  const OperationDay(this.day, this.operations);

  /// The day.
  final CivilDate day;

  /// The operations, the latest first.
  final List<Operation> operations;

  /// What the day comes to, one amount for each currency.
  List<Money> get total => sumByCurrency(
    operations.where((operation) => operation.counts).map((it) => it.amount),
  );
}

/// Puts [operations], the latest first, into days.
List<OperationDay> groupByDay(List<Operation> operations) {
  final days = <CivilDate, List<Operation>>{};
  for (final operation in operations) {
    (days[operation.day] ??= []).add(operation);
  }
  return [
    for (final MapEntry(key: day, value: operations) in days.entries)
      OperationDay(day, operations),
  ];
}

/// Adds up [amounts], one sum for each currency in the order they first came.
/// A sum of zero is left out. A sum too big to hold stops at the limit, so that
/// the list survives two absurd amounts.
List<Money> sumByCurrency(Iterable<Money> amounts) {
  final sums = <Currency, int>{};
  for (final amount in amounts) {
    sums[amount.currency] = (sums[amount.currency] ?? 0) + amount.minorUnits;
  }
  return [
    for (final MapEntry(key: currency, value: sum) in sums.entries)
      if (sum != 0)
        Money(
          sum.clamp(-Money.maxMinorUnits, Money.maxMinorUnits),
          currency,
        ),
  ];
}
