import 'package:import_common/src/domain/import_plan.dart';
import 'package:import_common/src/domain/import_repository.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The import on the ledger of the device (ADR 0021).
final class LedgerImportRepository implements ImportRepository {
  /// Creates the repository.
  const LedgerImportRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Future<List<Account>> accounts() =>
      _ledger.watchAccounts(includeArchived: true).first;

  @override
  Future<List<Category>> categories(CategoryKind kind) =>
      _ledger.watchCategories(kind, includeArchived: true).first;

  @override
  Future<List<Transaction>> transactions(
    String accountId, {
    required CivilDate from,
    required CivilDate to,
  }) => _ledger
      .watchTransactions(accountId: accountId, from: from, to: to, limit: null)
      .first;

  @override
  Future<List<Transaction>> history() =>
      _ledger.watchTransactions(limit: null).first;

  @override
  Future<List<Schedule>> schedules() => _ledger.watchSchedules().first;

  @override
  Future<Money> balanceOn(String accountId, CivilDate day) async {
    var balance = await _ledger.balance(accountId);
    final later = await _ledger
        .watchDayChanges(from: shiftDay(day, 1), accountId: accountId)
        .first;
    for (final change in later) {
      balance -= change.change;
    }
    return balance;
  }

  @override
  Future<String> write(
    ImportPlan plan, {
    required String fileName,
    String? format,
    void Function(int done, int total)? progress,
  }) {
    final operations = plan.added.toList();
    final first = plan.statement.from;
    final last = plan.statement.to;
    if (operations.isEmpty || first == null || last == null) {
      throw StateError('The plan adds nothing');
    }
    return _ledger.atomically(() async {
      final id = await _ledger.addImport(
        fileName: fileName,
        format: format,
        firstDay: first,
        lastDay: last,
      );
      final accounts = <String, String>{};
      for (final MapEntry(:key, :value) in plan.choices.accounts.entries) {
        switch (value) {
          case IntoAccount(:final account):
            accounts[key] = account.id;
          case NewAccount():
            final account = await _ledger.addAccount(
              name: value.name,
              type: value.type,
              openingBalance: value.openingBalance,
              lastDigits: value.lastDigits,
              importId: id,
            );
            accounts[key] = account.id;
          case LeaveOut():
            break;
        }
      }
      final categories = _NewCategories(_ledger, id);
      // The transaction that stands for each operation: its own, or the one
      // of the ledger that it is a copy of.
      final transactions = <PlannedOperation, String>{
        for (final operation in plan.copies)
          operation: operation.duplicate!.transaction.id,
      };
      Future<String?> categoryOf(CategoryChoice? choice, CategoryKind kind) =>
          switch (choice) {
            IntoCategory(:final categoryId) => Future.value(categoryId),
            final NewCategory choice => categories.idOf(choice, kind),
            _ => Future.value(),
          };
      for (final (index, operation) in operations.indexed) {
        final row = operation.row;
        final day = row.date.day;
        final at = row.date.time == null
            ? null
            : DateTime(day.year, day.month, day.day).add(row.date.time!);
        final note = noteOf(row);
        TransactionDraft one(
          String accountId,
          Money amount,
          String? category,
        ) => operation.kind == TransactionKind.income
            ? TransactionDraft.income(
                accountId: accountId,
                allocations: [Allocation(categoryId: category, amount: amount)],
                occurredOn: day,
                occurredAt: at,
                note: note,
                source: TransactionSource.import,
              )
            : TransactionDraft.expense(
                accountId: accountId,
                allocations: [Allocation(categoryId: category, amount: amount)],
                occurredOn: day,
                occurredAt: at,
                note: note,
                source: TransactionSource.import,
              );
        final kind = operation.kind == TransactionKind.income
            ? CategoryKind.income
            : CategoryKind.expense;
        transactions[operation] = await _ledger.record(switch (operation.kind) {
          TransactionKind.transfer => TransactionDraft.transfer(
            fromAccountId: accounts[operation.from]!,
            sent: operation.amount,
            toAccountId: accounts[operation.to]!,
            received: operation.received!,
            occurredOn: day,
            occurredAt: at,
            note: note,
            source: TransactionSource.import,
          ),
          _ => one(
            accounts[operation.from ?? operation.to]!,
            operation.amount,
            operation.learned?.categoryId ??
                await categoryOf(
                  plan.choices.categories[operation.category],
                  kind,
                ),
          ),
        }, importId: id);
        if (operation.fee case final fee?) {
          await _ledger.record(
            TransactionDraft.expense(
              accountId: accounts[operation.from ?? operation.to]!,
              allocations: [
                Allocation(
                  categoryId: await categoryOf(
                    plan.choices.fees,
                    CategoryKind.expense,
                  ),
                  amount: fee,
                ),
              ],
              occurredOn: day,
              occurredAt: at,
              note: note,
              source: TransactionSource.import,
            ),
            importId: id,
          );
        }
        progress?.call(index + 1, operations.length);
      }
      for (final found in plan.found) {
        await _ledger.findSchedule(
          found.schedule.id,
          through: found.last.time,
          transactionId: transactions[found.last.operation]!,
          importId: id,
        );
      }
      return id;
    });
  }

  @override
  Future<void> undo(String id) => _ledger.undoImport(id);

  @override
  Stream<List<LedgerImport>> watchImports() => _ledger.watchImports();
}

/// The categories that an import adds, each once, a parent before its
/// subcategories.
final class _NewCategories {
  _NewCategories(this._ledger, this._importId);

  final LedgerRepository _ledger;
  final String _importId;
  final _ids = <(CategoryKind, String?, String), String>{};

  Future<String> idOf(NewCategory choice, CategoryKind kind) async {
    var parentId = choice.parentId;
    if (choice.parentName case final parent?) {
      parentId = await idOf(NewCategory(parent), kind);
    }
    final key = (kind, parentId, choice.name);
    if (_ids[key] case final id?) return id;
    final category = await _ledger.addCategory(
      kind: kind,
      name: choice.name,
      parentId: parentId,
      importId: _importId,
    );
    return _ids[key] = category.id;
  }
}
