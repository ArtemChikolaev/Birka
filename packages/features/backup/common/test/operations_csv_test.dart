import 'package:backup_common/backup_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

Account account(String id, String name, Currency currency) => Account(
  id: id,
  name: name,
  type: AccountType.debit,
  openingBalance: Money.zero(currency),
  includeInTotals: true,
  archived: false,
  sortOrder: 0,
);

Category category(String id, String name, {String? parentId}) => Category(
  id: id,
  kind: CategoryKind.expense,
  name: name,
  archived: false,
  sortOrder: 0,
  parentId: parentId,
);

Transaction transaction(
  String id,
  TransactionKind kind,
  CivilDate day, {
  required List<Entry> entries,
  List<Allocation> allocations = const [],
  String note = '',
}) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: TransactionSource.manual,
  entries: entries,
  allocations: allocations,
);

final export = OperationsExport(
  accounts: [
    account('card', 'Card', Currency.rub),
    account('euro', 'Euro; savings', Currency.eur),
  ],
  categories: [
    category('food', 'Food'),
    category('cafe', 'Cafe', parentId: 'food'),
  ],
  transactions: [
    transaction(
      'b',
      TransactionKind.transfer,
      CivilDate(2026, 10, 29),
      entries: [
        Entry(accountId: 'card', amount: rub(-1000000)),
        Entry(accountId: 'euro', amount: eur(10000)),
      ],
    ),
    transaction(
      'a',
      TransactionKind.expense,
      CivilDate(2026, 10, 29),
      entries: [Entry(accountId: 'card', amount: rub(-45050))],
      allocations: [
        Allocation(categoryId: 'cafe', amount: rub(30050)),
        Allocation(categoryId: 'food', amount: rub(15000)),
      ],
      note: 'Lunch with "Anna"',
    ),
    transaction(
      'c',
      TransactionKind.adjustment,
      CivilDate(2026, 10, 28),
      entries: [Entry(accountId: 'euro', amount: eur(-150))],
      note: '=1+1',
    ),
  ],
);

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a table has a row for each category and each account', () {
    expect(
      operationsCsv(export, csvLanguage()),
      '\uFEFF'
      'Date,Type,Amount,Currency,Account,Category,Subcategory,Note\r\n'
      "2026-10-28,Adjustment,-1.50,EUR,Euro; savings,,,'=1+1\r\n"
      '2026-10-29,Expense,-300.50,RUB,Card,Food,Cafe,"Lunch with ""Anna"""\r\n'
      '2026-10-29,Expense,-150.00,RUB,Card,Food,,"Lunch with ""Anna"""\r\n'
      '2026-10-29,Transfer,-10000.00,RUB,Card,,,\r\n'
      '2026-10-29,Transfer,100.00,EUR,Euro; savings,,,\r\n',
    );
  });

  test('a table in Russian takes its marks', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);

    final lines = operationsCsv(export, csvLanguage()).split('\r\n');

    expect(
      lines.first,
      '\uFEFFДата;Тип;Сумма;Валюта;Счёт;Категория;Подкатегория;Заметка',
    );
    expect(
      lines[1],
      "2026-10-28;Корректировка;-1,50;EUR;\"Euro; savings\";;;'=1+1",
    );
  });

  test('an income is positive and a name that is gone stays empty', () {
    final income = OperationsExport(
      accounts: const [],
      categories: const [],
      transactions: [
        transaction(
          'pay',
          TransactionKind.income,
          CivilDate(2026, 10, 30),
          entries: [Entry(accountId: 'gone', amount: rub(9000000))],
          allocations: [Allocation(categoryId: 'gone', amount: rub(9000000))],
        ),
      ],
    );

    expect(
      operationsCsv(income, csvLanguage()).split('\r\n')[1],
      '2026-10-30,Income,90000.00,RUB,,,,',
    );
  });
}
