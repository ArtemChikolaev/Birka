import 'package:import_common/src/domain/import_plan.dart';
import 'package:import_common/src/domain/statement.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// What the import needs of the ledger.
abstract interface class ImportRepository {
  /// The accounts, archived ones included, to choose from.
  Future<List<Account>> accounts();

  /// The categories of [kind], archived ones included, to choose from.
  Future<List<Category>> categories(CategoryKind kind);

  /// The transactions of [accountId] from [from] to [to], both ends included.
  Future<List<Transaction>> transactions(
    String accountId, {
    required CivilDate from,
    required CivilDate to,
  });

  /// What [accountId] held at the end of [day].
  Future<Money> balanceOn(String accountId, CivilDate day);

  /// Every transaction of the ledger, for what the past choices of the
  /// person teach the import.
  Future<List<Transaction>> history();

  /// The regular payments, whose times a statement can bring (ADR 0023).
  Future<List<Schedule>> schedules();

  /// Puts what [plan] adds into the ledger at once and returns the id of the
  /// import, which can take all of it out again, and marks the times of the
  /// regular payments that it brings as done. [progress] hears how many of
  /// the operations are in.
  Future<String> write(
    ImportPlan plan, {
    required String fileName,
    String? format,
    void Function(int done, int total)? progress,
  });

  /// Takes the import [id] out of the ledger.
  Future<void> undo(String id);

  /// The past imports, the latest first.
  Stream<List<LedgerImport>> watchImports();
}

/// The plan of importing [statement] by [choices], with what [repository]
/// holds: the transactions of the accounts it goes into around its days,
/// their balances on the day of its last operation, the regular payments,
/// and the past choices of the person, which [memory] gives when they are
/// already read.
Future<ImportPlan> prepareImport(
  ImportRepository repository,
  Statement statement,
  ImportChoices choices, {
  CategoryMemory? memory,
}) async {
  final learned = memory ?? await learnFrom(repository);
  final first = statement.from;
  final last = statement.to;
  if (first == null || last == null) {
    return planImport(statement, choices, memory: learned);
  }
  final existing = <String, List<Transaction>>{};
  final balances = <String, Money>{};
  for (final choice in choices.accounts.values.whereType<IntoAccount>()) {
    final id = choice.account.id;
    if (existing.containsKey(id)) continue;
    existing[id] = await repository.transactions(
      id,
      from: shiftDay(first, -1),
      to: shiftDay(last, 1),
    );
    balances[id] = await repository.balanceOn(id, last);
  }
  return planImport(
    statement,
    choices,
    existing: existing,
    balances: balances,
    memory: learned,
    schedules: existing.isEmpty ? const [] : await repository.schedules(),
  );
}

/// What the past choices of the person in [repository] teach the import: the
/// operations of the ledger whose categories are open (ADR 0022).
Future<CategoryMemory> learnFrom(ImportRepository repository) async {
  final open = {
    for (final kind in CategoryKind.values)
      for (final category in await repository.categories(kind))
        if (!category.archived) category.id,
  };
  return CategoryMemory([
    for (final transaction in await repository.history())
      if (transaction.allocations.every(
        (it) => it.categoryId == null || open.contains(it.categoryId),
      ))
        transaction,
  ]);
}

/// The day [days] days after [day], or before it when [days] is below zero.
CivilDate shiftDay(CivilDate day, int days) => CivilDate.of(
  DateTime.utc(day.year, day.month, day.day).add(Duration(days: days)),
);
