import 'dart:convert';
import 'dart:typed_data';

import 'package:import_common/import_common.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The window of files, with the files that the person chooses in turn.
final class FakeStatementFiles implements StatementFiles {
  /// Creates the window with [files], where `null` is a window closed.
  FakeStatementFiles(this.files);

  /// What the next choices give.
  final List<ChosenStatement?> files;

  @override
  Future<ChosenStatement?> choose() async =>
      files.isEmpty ? null : files.removeAt(0);
}

/// The ledger of the import in memory: its accounts, without categories and
/// transactions, and the imports written into it.
final class FakeImportRepository implements ImportRepository {
  /// Creates the ledger of [ledgerAccounts].
  FakeImportRepository(this.ledgerAccounts);

  /// The accounts of the ledger.
  final List<Account> ledgerAccounts;

  /// The plans written, in turn.
  final written = <ImportPlan>[];

  /// The imports taken back out.
  final undone = <String>[];

  @override
  Future<List<Account>> accounts() async => ledgerAccounts;

  @override
  Future<List<Category>> categories(CategoryKind kind) async => const [];

  @override
  Future<List<Transaction>> transactions(
    String accountId, {
    required CivilDate from,
    required CivilDate to,
  }) async => const [];

  @override
  Future<Money> balanceOn(String accountId, CivilDate day) async =>
      Money(0, Currency.rub);

  @override
  Future<List<Transaction>> history() async => const [];

  @override
  Future<String> write(
    ImportPlan plan, {
    required String fileName,
    String? format,
    void Function(int done, int total)? progress,
  }) async {
    written.add(plan);
    final total = plan.added.length;
    progress?.call(total, total);
    return 'import-${written.length}';
  }

  @override
  Future<void> undo(String id) async => undone.add(id);

  @override
  Stream<List<LedgerImport>> watchImports() => Stream.value(const []);
}

/// The card of the ledger that the statement of [october] belongs to.
final card = Account(
  id: 'card',
  name: 'Зарплатная карта',
  type: AccountType.debit,
  openingBalance: Money(0, Currency.rub),
  includeInTotals: true,
  archived: false,
  sortOrder: 0,
  lastDigits: '4821',
);

/// A made-up CSV of a card of Alfa-Bank in October.
ChosenStatement october() => ChosenStatement(
  'alfa-2026-10.csv',
  _text([
    'Дата операции;Описание;Сумма;Валюта;Категория;Номер карты',
    '01.10.2026 10:00;TOPUP WISE;185 000,00;RUR;Переводы;*4821',
    '02.10.2026 18:40;PRODUKTY BEREZKA;−2 340,50;RUR;Продукты;*4821',
    '03.10.2026 09:12;ZERNO COFFEE;−420,00;RUR;Рестораны и кафе;*4821',
    '07.10.2026;ZHKU MOSKVA;−6 845,30;RUR;ЖКХ;*4821',
  ]),
);

/// A made-up CSV of columns that no format names: a date, a text, a sum
/// with a comma that the guess leaves out, and a balance.
ChosenStatement unknown() => ChosenStatement(
  'statement_oct_2026.csv',
  _text([
    'День;Назначение платежа;Сумма в валюте счёта;Остаток',
    '01.10.2026;Зарплата;96500,00;142679,81',
    '03.10.2026;Кофейня Зерно;-420,00;142259,81',
  ]),
);

/// A file that holds no table.
ChosenStatement picture() =>
    ChosenStatement('receipt.png', Uint8List.fromList([137, 80, 78, 71, 0]));

Uint8List _text(List<String> lines) => utf8.encode(lines.join('\n'));
