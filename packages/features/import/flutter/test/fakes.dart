import 'dart:convert';
import 'dart:typed_data';

import 'package:device_settings/device_settings.dart';
import 'package:import_common/import_common.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The settings in memory.
final class FakeSettingsStore implements SettingsStore {
  /// What the settings hold.
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

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

/// The ledger of the import in memory: its accounts and categories, without
/// transactions, and the imports written into it.
final class FakeImportRepository implements ImportRepository {
  /// Creates the ledger of [ledgerAccounts] and [ledgerCategories].
  FakeImportRepository(this.ledgerAccounts, {this.ledgerCategories = const []});

  /// The accounts of the ledger.
  final List<Account> ledgerAccounts;

  /// The categories of the ledger.
  final List<Category> ledgerCategories;

  /// The plans written, in turn.
  final written = <ImportPlan>[];

  /// The imports taken back out.
  final undone = <String>[];

  @override
  Future<List<Account>> accounts() async => ledgerAccounts;

  @override
  Future<List<Category>> categories(CategoryKind kind) async => [
    for (final category in ledgerCategories)
      if (category.kind == kind) category,
  ];

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

/// The categories of a ledger in which «Продукты», «Кафе» and «Дом» stand
/// for three categories of the bank of [october], and «Переводы» for none.
const ledgerCategories = [
  Category(
    id: 'food',
    kind: CategoryKind.expense,
    name: 'Продукты',
    archived: false,
    sortOrder: 0,
    color: '#4ADE80',
  ),
  Category(
    id: 'cafe',
    kind: CategoryKind.expense,
    name: 'Кафе',
    archived: false,
    sortOrder: 1,
    color: '#FBBF24',
  ),
  Category(
    id: 'home',
    kind: CategoryKind.expense,
    name: 'Дом',
    archived: false,
    sortOrder: 2,
    color: '#22D3EE',
  ),
  Category(
    id: 'salary',
    kind: CategoryKind.income,
    name: 'Зарплата',
    archived: false,
    sortOrder: 3,
  ),
];

/// A made-up CSV of Revolut in October: a coffee with a fee, and a top-up.
ChosenStatement revolutOctober() => ChosenStatement(
  'revolut-2026-10.csv',
  _text([
    for (final cells in [
      [
        'Type',
        'Product',
        'Started Date',
        'Completed Date',
        'Description',
        'Amount',
        'Fee',
        'Currency',
        'State',
        'Balance',
      ],
      [
        'TOPUP',
        'Current',
        '2026-10-01 10:00:00',
        '2026-10-01 10:00:00',
        'Top-up',
        '100.00',
        '0.00',
        'EUR',
        'COMPLETED',
        '100.00',
      ],
      [
        'CARD_PAYMENT',
        'Current',
        '2026-10-03 09:12:00',
        '2026-10-03 10:00:00',
        'Coffee',
        '-4.20',
        '0.50',
        'EUR',
        'COMPLETED',
        '95.30',
      ],
    ])
      cells.join(','),
  ]),
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
