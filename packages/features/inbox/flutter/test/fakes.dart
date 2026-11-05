import 'package:decimal/decimal.dart';
import 'package:device_settings/device_settings.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The settings in memory.
final class FakeSettingsStore implements SettingsStore {
  /// What the settings hold.
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// The ledger of the inbox in memory: what it holds once, and what the
/// inbox asked of it.
final class FakeInboxRepository implements InboxRepository {
  /// Creates the ledger of [transactions], the latest first.
  FakeInboxRepository({
    this.transactions = const [],
    this.accounts = const [],
    this.categories = const [],
    this.rates = const RateBook.empty(),
    this.imports = const [],
  });

  /// The transactions, the latest first.
  final List<Transaction> transactions;

  /// The accounts.
  final List<Account> accounts;

  /// The categories of both kinds.
  final List<Category> categories;

  /// The rates of the Bank of Russia.
  final RateBook rates;

  /// The past imports, the latest first.
  final List<LedgerImport> imports;

  /// The transactions given a category, by id, with the category.
  final categorized = <(String, String)>[];

  /// The pairs made into transfers.
  final transfers = <TransferPair>[];

  @override
  Stream<List<Transaction>> watchTransactions() => Stream.value(transactions);

  @override
  Stream<List<Account>> watchAccounts() => Stream.value(accounts);

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) => Stream.value([
    for (final it in categories)
      if (it.kind == kind) it,
  ]);

  @override
  Stream<RateBook> watchRates() => Stream.value(rates);

  @override
  Stream<List<LedgerImport>> watchImports() => Stream.value(imports);

  @override
  Future<void> categorize(List<(Transaction, String)> choices) async =>
      categorized.addAll([
        for (final (transaction, categoryId) in choices)
          (transaction.id, categoryId),
      ]);

  @override
  Future<String> makeTransfer(TransferPair pair) async {
    transfers.add(pair);
    return 'transfer-${transfers.length}';
  }
}

Transaction _operation(
  String id,
  TransactionKind kind,
  String account,
  Money amount,
  CivilDate day,
  String note, {
  String? category,
  String? importId,
}) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: importId == null
      ? TransactionSource.manual
      : TransactionSource.import,
  entries: [
    Entry(
      accountId: account,
      amount: kind == TransactionKind.expense ? -amount : amount,
    ),
  ],
  allocations: [Allocation(categoryId: category, amount: amount)],
  importId: importId,
);

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

/// A made-up ledger after an import of Alfa-Bank in October: a coffee place
/// sorted three times in September and again without a category, a
/// transfer to a person, and a top-up from Wise that pairs with the money
/// that left Wise.
FakeInboxRepository october() => FakeInboxRepository(
  accounts: [
    Account(
      id: 'card',
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: _rub(0),
      includeInTotals: true,
      archived: false,
      sortOrder: 0,
    ),
    Account(
      id: 'wise',
      name: 'Wise USD',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.usd),
      includeInTotals: true,
      archived: false,
      sortOrder: 1,
    ),
  ],
  categories: const [
    Category(
      id: 'cafe',
      kind: CategoryKind.expense,
      name: 'Кафе',
      archived: false,
      sortOrder: 0,
      color: '#FBBF24',
    ),
    Category(
      id: 'shop',
      kind: CategoryKind.expense,
      name: 'Покупки',
      archived: false,
      sortOrder: 1,
    ),
  ],
  rates: RateBook([
    DayRates(CivilDate(2026, 9, 30), {'USD': Decimal.parse('81.20')}),
  ]),
  imports: [
    LedgerImport(
      id: 'october',
      fileName: 'alfa-2026-10.xlsx',
      firstDay: CivilDate(2026, 10, 1),
      lastDay: CivilDate(2026, 10, 21),
      importedAt: DateTime(2026, 11, 2),
      transactions: 3,
      accountIds: const {'card'},
      format: 'alfa',
    ),
  ],
  transactions: [
    _operation(
      'ivan',
      TransactionKind.expense,
      'card',
      _rub(3000),
      CivilDate(2026, 10, 9),
      'Перевод Ивану К.',
      importId: 'october',
    ),
    _operation(
      'soko',
      TransactionKind.expense,
      'card',
      _rub(1450),
      CivilDate(2026, 10, 4),
      'ИП Соколов А. В.',
      importId: 'october',
    ),
    _operation(
      'top-up',
      TransactionKind.income,
      'card',
      _rub(185000),
      CivilDate(2026, 10, 1),
      'Пополнение с Wise',
      importId: 'october',
    ),
    _operation(
      'wise-out',
      TransactionKind.expense,
      'wise',
      Money(231000, Currency.usd),
      CivilDate(2026, 9, 30),
      'Card top-up',
    ),
    for (final day in [25, 12, 3])
      _operation(
        'soko-$day',
        TransactionKind.expense,
        'card',
        _rub(1450),
        CivilDate(2026, 9, day),
        'ИП Соколов А. В.',
        category: 'cafe',
      ),
  ],
);
