import 'package:decimal/decimal.dart';
import 'package:import_common/src/domain/statement.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// Where the operations of an account of a statement go.
sealed class AccountChoice {
  const AccountChoice();
}

/// Into an account that the ledger has.
final class IntoAccount extends AccountChoice {
  /// Creates the choice.
  const IntoAccount(this.account);

  /// The account.
  final Account account;
}

/// Into an account that the import adds.
final class NewAccount extends AccountChoice {
  /// Creates the choice.
  const NewAccount({
    required this.name,
    required this.type,
    required this.openingBalance,
    this.lastDigits,
  });

  /// The name of the account.
  final String name;

  /// What kind of account it is.
  final AccountType type;

  /// What it held before the statement, in its currency for good.
  final Money openingBalance;

  /// The last digits of its card.
  final String? lastDigits;
}

/// Nowhere: the operations of the account stay out of the ledger.
final class LeaveOut extends AccountChoice {
  /// Creates the choice.
  const LeaveOut();
}

/// A category that a bank gave operations of one kind, or none when its name
/// is `null`.
typedef BankCategory = ({CategoryKind kind, String? name});

/// Where the operations of a category of the bank go.
sealed class CategoryChoice {
  const CategoryChoice();
}

/// Into a category that the ledger has.
final class IntoCategory extends CategoryChoice {
  /// Creates the choice.
  const IntoCategory(this.categoryId);

  /// The id of the category.
  final String categoryId;
}

/// Into a category that the import adds, inside the category [parentId] that
/// the ledger has or the new category [parentName] that the import adds too.
final class NewCategory extends CategoryChoice {
  /// Creates the choice.
  const NewCategory(this.name, {this.parentId, this.parentName})
    : assert(
        parentId == null || parentName == null,
        'A category has one parent',
      );

  /// The name of the category.
  final String name;

  /// The parent that the ledger has.
  final String? parentId;

  /// The name of the parent that the import adds.
  final String? parentName;
}

/// Into no category: the operation waits in the inbox for one.
final class Unsorted extends CategoryChoice {
  /// Creates the choice.
  const Unsorted();
}

/// What a person chose for the import of a statement.
@immutable
final class ImportChoices {
  /// Creates the choices.
  const ImportChoices({
    required this.accounts,
    this.categories = const {},
    this.fees = const Unsorted(),
    this.keep = const {},
  });

  /// Where each account of the file goes, by [SourceAccount.key]. One that is
  /// not here stays out.
  final Map<String, AccountChoice> accounts;

  /// Where each category of the bank goes. One that is not here waits in the
  /// inbox.
  final Map<BankCategory, CategoryChoice> categories;

  /// Where fees go.
  final CategoryChoice fees;

  /// The lines of the rows that go in although they look like a transaction
  /// that the ledger has.
  final Set<int> keep;

  /// The same choices with [keep] instead.
  ImportChoices keeping(Set<int> keep) => ImportChoices(
    accounts: accounts,
    categories: categories,
    fees: fees,
    keep: keep,
  );
}

/// Why an operation of a statement looks like a transaction of the ledger.
enum DuplicateReason {
  /// The import of a statement brought the transaction with the same day,
  /// amount and text.
  imported,

  /// The same amount.
  sameAmount,

  /// The same day.
  sameDay,

  /// A day before the operation.
  dayBefore,

  /// A day after it.
  dayAfter,

  /// The same account.
  sameAccount,

  /// A name like the description of the operation.
  similarName,
}

/// A transaction of the ledger that an operation of a statement looks like.
@immutable
final class Duplicate {
  /// Creates a duplicate.
  const Duplicate(this.transaction, this.reasons);

  /// The transaction.
  final Transaction transaction;

  /// Why it looks the same.
  final Set<DuplicateReason> reasons;
}

/// Why a row of a statement cannot go into the ledger as chosen.
enum PlanFault {
  /// Its currency is not the currency of the account it goes into.
  otherCurrency,

  /// Its amount has more digits after the point than the currency.
  tooPrecise,

  /// A transfer in one currency whose two amounts differ.
  unevenTransfer,
}

/// A row of a statement that cannot go into the ledger as chosen.
@immutable
final class PlanProblem {
  /// Creates a problem.
  const PlanProblem(this.line, this.fault, this.text);

  /// The number of the row in the file.
  final int line;

  /// What is wrong.
  final PlanFault fault;

  /// What to show: the currency or the amount that does not fit.
  final String text;
}

/// An operation of a statement as it goes into the ledger.
@immutable
final class PlannedOperation {
  /// Creates an operation.
  const PlannedOperation({
    required this.row,
    required this.kind,
    required this.amount,
    this.from,
    this.to,
    this.received,
    this.fee,
    this.category,
    this.duplicate,
  });

  /// The row of the statement.
  final StatementRow row;

  /// An expense, an income or a transfer.
  final TransactionKind kind;

  /// The key of the account that money leaves, for an expense and a transfer.
  final String? from;

  /// The key of the account that money reaches, for an income and a transfer.
  final String? to;

  /// The amount in the currency of its account: what left it for an expense
  /// and a transfer, what reached it for an income.
  final Money amount;

  /// What reached the other account of a transfer.
  final Money? received;

  /// A fee on top, which goes in as an expense of its own.
  final Money? fee;

  /// The category of the bank, for an expense and an income.
  final BankCategory? category;

  /// The transaction of the ledger that it looks like.
  final Duplicate? duplicate;

  /// What it changes on the account of [key].
  Money? changeOn(String key) {
    Money? change;
    void add(Money money) => change = change == null ? money : change! + money;
    if (from == key) add(-amount);
    if (to == key) add(kind == TransactionKind.transfer ? received! : amount);
    if (fee case final fee? when (from ?? to) == key) add(-fee);
    return change;
  }
}

/// What an import will do, before it does it.
@immutable
final class ImportPlan {
  /// Creates a plan.
  const ImportPlan({
    required this.statement,
    required this.choices,
    required this.operations,
    required this.problems,
    required this.left,
    required this.balances,
  });

  /// The statement.
  final Statement statement;

  /// What the person chose.
  final ImportChoices choices;

  /// The operations that can go in, in the order of time, those that look
  /// like a transaction of the ledger included.
  final List<PlannedOperation> operations;

  /// The rows that cannot go in as chosen.
  final List<PlanProblem> problems;

  /// How many operations stay out with an account that the person left out.
  final int left;

  /// What each account of the file holds after the import on the day of its
  /// last operation, by [SourceAccount.key], for the accounts the import
  /// goes into.
  final Map<String, Money> balances;

  /// Whether [operation] stays out as a copy of a transaction the ledger has.
  bool skips(PlannedOperation operation) =>
      operation.duplicate != null && !choices.keep.contains(operation.row.line);

  /// The operations that go in.
  Iterable<PlannedOperation> get added =>
      operations.where((operation) => !skips(operation));

  /// The operations that stay out as copies.
  Iterable<PlannedOperation> get copies => operations.where(skips);

  /// How many operations that go in wait in the inbox for a category.
  int get unsorted => [
    for (final operation in added)
      if (operation.kind != TransactionKind.transfer &&
          choices.categories[operation.category] is! IntoCategory &&
          choices.categories[operation.category] is! NewCategory)
        operation,
  ].length;
}

/// Plans the import of [statement] by [choices] against what the ledger holds:
/// [existing] are the transactions of the accounts it goes into, by the id of
/// the account, from a day before the statement to a day after it, and
/// [balances] what those accounts held on the day of its last operation.
///
/// An operation looks like a transaction of the ledger when that one moves
/// the same amount on the same account within a day of it. Each transaction
/// stands for one operation at most, so two equal operations of one file
/// both go in when the ledger has one of them.
ImportPlan planImport(
  Statement statement,
  ImportChoices choices, {
  Map<String, List<Transaction>> existing = const {},
  Map<String, Money> balances = const {},
}) {
  final operations = <PlannedOperation>[];
  final problems = <PlanProblem>[];
  var left = 0;
  final used = <String>{};
  Currency? currencyOf(String? key) => switch (choices.accounts[key]) {
    IntoAccount(:final account) => account.openingBalance.currency,
    NewAccount(:final openingBalance) => openingBalance.currency,
    _ => null,
  };
  // Two accounts of the file can go into one account of the ledger.
  String? targetOf(String? key) => switch (choices.accounts[key]) {
    IntoAccount(:final account) => 'ledger ${account.id}',
    NewAccount() => 'new $key',
    _ => null,
  };

  for (final row in statement.rows) {
    var out = row.out;
    var into = row.into;
    if (out != null && currencyOf(out.account) == null) out = null;
    if (into != null && currencyOf(into.account) == null) into = null;
    if (out == null && into == null ||
        out != null &&
            into != null &&
            targetOf(out.account) == targetOf(into.account)) {
      left++;
      continue;
    }
    final problem = _fitting(row, [?out, ?into], currencyOf);
    if (problem != null) {
      problems.add(problem);
      continue;
    }
    final fee = row.fee == null
        ? null
        : _money(row.fee!, currencyOf((out ?? into)!.account)!);
    final PlannedOperation planned;
    if (out != null && into != null) {
      planned = PlannedOperation(
        row: row,
        kind: TransactionKind.transfer,
        from: out.account,
        to: into.account,
        amount: _money(out.amount, currencyOf(out.account)!)!,
        received: _money(into.amount, currencyOf(into.account)!),
        fee: fee,
      );
    } else {
      final leg = (out ?? into)!;
      final kind = out != null
          ? TransactionKind.expense
          : TransactionKind.income;
      planned = PlannedOperation(
        row: row,
        kind: kind,
        from: out?.account,
        to: into?.account,
        amount: _money(leg.amount, currencyOf(leg.account)!)!,
        fee: fee,
        category: (
          kind: kind == TransactionKind.expense
              ? CategoryKind.expense
              : CategoryKind.income,
          name: row.category,
        ),
      );
    }
    operations.add(
      _withDuplicate(planned, choices, existing, used),
    );
  }

  final after = <String, Money>{};
  for (final MapEntry(:key, :value) in choices.accounts.entries) {
    final start = switch (value) {
      IntoAccount(:final account) => balances[account.id],
      NewAccount(:final openingBalance) => openingBalance,
      LeaveOut() => null,
    };
    if (start == null) continue;
    var balance = start;
    for (final operation in operations) {
      if (operation.duplicate != null &&
          !choices.keep.contains(operation.row.line)) {
        continue;
      }
      if (operation.changeOn(key) case final change?) balance += change;
    }
    after[key] = balance;
  }
  return ImportPlan(
    statement: statement,
    choices: choices,
    operations: List.unmodifiable(operations),
    problems: List.unmodifiable(problems),
    left: left,
    balances: Map.unmodifiable(after),
  );
}

/// The problem of [row] with the currencies of its [legs], or `null` when it
/// fits.
PlanProblem? _fitting(
  StatementRow row,
  List<StatementLeg> legs,
  Currency? Function(String?) currencyOf,
) {
  for (final leg in legs) {
    final currency = currencyOf(leg.account)!;
    if (leg.currency != null && leg.currency != currency.code) {
      return PlanProblem(row.line, PlanFault.otherCurrency, leg.currency!);
    }
    if (_money(leg.amount, currency) == null) {
      return PlanProblem(row.line, PlanFault.tooPrecise, '${leg.amount}');
    }
  }
  if (row.fee case final fee?) {
    if (_money(fee, currencyOf(legs.first.account)!) == null) {
      return PlanProblem(row.line, PlanFault.tooPrecise, '$fee');
    }
  }
  if (legs.length == 2 &&
      currencyOf(legs.first.account) == currencyOf(legs.last.account) &&
      legs.first.amount != legs.last.amount) {
    return PlanProblem(
      row.line,
      PlanFault.unevenTransfer,
      '${legs.first.amount} / ${legs.last.amount}',
    );
  }
  return null;
}

/// [amount] in minor units of [currency], or `null` when it has more digits
/// after the point than the currency.
Money? _money(Decimal amount, Currency currency) {
  final minor = amount.shift(currency.decimalDigits);
  if (!minor.isInteger) return null;
  final units = minor.toBigInt();
  if (units.abs() > BigInt.from(Money.maxMinorUnits)) return null;
  return Money(units.toInt(), currency);
}

PlannedOperation _withDuplicate(
  PlannedOperation planned,
  ImportChoices choices,
  Map<String, List<Transaction>> existing,
  Set<String> used,
) {
  // The account that the ledger already has is where a copy can be.
  for (final (key, change) in [
    (planned.from, planned.from == null ? null : -planned.amount),
    (
      planned.to,
      planned.to == null
          ? null
          : planned.kind == TransactionKind.transfer
          ? planned.received
          : planned.amount,
    ),
  ]) {
    final choice = choices.accounts[key];
    if (key == null || change == null || choice is! IntoAccount) continue;
    final duplicate = _duplicateOf(
      planned.row,
      choice.account.id,
      change,
      existing[choice.account.id] ?? const [],
      used,
    );
    if (duplicate != null) {
      used.add(duplicate.transaction.id);
      return PlannedOperation(
        row: planned.row,
        kind: planned.kind,
        from: planned.from,
        to: planned.to,
        amount: planned.amount,
        received: planned.received,
        fee: planned.fee,
        category: planned.category,
        duplicate: duplicate,
      );
    }
  }
  return planned;
}

Duplicate? _duplicateOf(
  StatementRow row,
  String accountId,
  Money change,
  List<Transaction> transactions,
  Set<String> used,
) {
  Duplicate? best;
  var bestScore = -1;
  final text = noteOf(row);
  for (final transaction in transactions) {
    if (used.contains(transaction.id)) continue;
    final moves = transaction.entries.any(
      (entry) => entry.accountId == accountId && entry.amount == change,
    );
    if (!moves) continue;
    final days = _daysBetween(row.date.day, transaction.occurredOn);
    if (days.abs() > 1) continue;
    final similar = _similar(text, transaction.note);
    final imported =
        transaction.importId != null && days == 0 && transaction.note == text;
    final reasons = {
      if (imported) DuplicateReason.imported,
      DuplicateReason.sameAmount,
      switch (days) {
        0 => DuplicateReason.sameDay,
        1 => DuplicateReason.dayBefore,
        _ => DuplicateReason.dayAfter,
      },
      DuplicateReason.sameAccount,
      if (similar) DuplicateReason.similarName,
    };
    final score = (imported ? 8 : 0) + (days == 0 ? 4 : 0) + (similar ? 2 : 0);
    if (score > bestScore) {
      best = Duplicate(transaction, Set.unmodifiable(reasons));
      bestScore = score;
    }
  }
  return best;
}

/// The note that an operation of [row] gets in the ledger: what the bank
/// wrote, and what a person wrote after it.
String noteOf(StatementRow row) => [
  row.description,
  row.note,
].where((text) => text.isNotEmpty).join(' · ');

/// How many days [day] comes after [other].
int _daysBetween(CivilDate day, CivilDate other) => DateTime.utc(
  day.year,
  day.month,
  day.day,
).difference(DateTime.utc(other.year, other.month, other.day)).inDays;

/// Whether two names share a word of three letters or more, or one holds the
/// other.
bool _similar(String a, String b) {
  List<String> words(String text) => text
      .toLowerCase()
      .replaceAll('ё', 'е')
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((word) => word.length >= 3)
      .toList();
  final left = words(a);
  final right = words(b);
  if (left.isEmpty || right.isEmpty) return false;
  if (left.join(' ').contains(right.join(' ')) ||
      right.join(' ').contains(left.join(' '))) {
    return true;
  }
  return left.toSet().intersection(right.toSet()).isNotEmpty;
}
