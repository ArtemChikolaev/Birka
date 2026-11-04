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

  /// Puts what [plan] adds into the ledger at once and returns the id of the
  /// import, which can take all of it out again. [progress] hears how many of
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
/// holds: the transactions of the accounts it goes into around its days and
/// their balances on the day of its last operation.
Future<ImportPlan> prepareImport(
  ImportRepository repository,
  Statement statement,
  ImportChoices choices,
) async {
  final first = statement.from;
  final last = statement.to;
  if (first == null || last == null) return planImport(statement, choices);
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
  );
}

/// The day [days] days after [day], or before it when [days] is below zero.
CivilDate shiftDay(CivilDate day, int days) => CivilDate.of(
  DateTime.utc(day.year, day.month, day.day).add(Duration(days: days)),
);
