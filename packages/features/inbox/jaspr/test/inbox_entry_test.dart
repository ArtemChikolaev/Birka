import 'package:decimal/decimal.dart';
import 'package:device_settings/device_settings.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_jaspr/inbox_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The settings in memory.
final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

Transaction _operation(
  String id,
  TransactionKind kind,
  String account,
  Money amount,
  CivilDate day,
) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: id,
  status: TransactionStatus.cleared,
  source: TransactionSource.import,
  entries: [
    Entry(
      accountId: account,
      amount: kind == TransactionKind.expense ? -amount : amount,
    ),
  ],
  allocations: [Allocation(categoryId: null, amount: amount)],
);

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

/// A made-up ledger after an import of Alfa-Bank: two operations without a
/// category and a top-up from Wise, or nothing at all.
final class _Ledger implements InboxRepository {
  _Ledger({this.empty = false});

  final bool empty;

  @override
  Stream<List<Transaction>> watchTransactions() => Stream.value([
    if (!empty) ...[
      _operation(
        'ivan',
        TransactionKind.expense,
        'card',
        _rub(3000),
        CivilDate(2026, 10, 9),
      ),
      _operation(
        'soko',
        TransactionKind.expense,
        'card',
        _rub(1450),
        CivilDate(2026, 10, 4),
      ),
      _operation(
        'top-up',
        TransactionKind.income,
        'card',
        _rub(185000),
        CivilDate(2026, 10, 1),
      ),
      _operation(
        'wise-out',
        TransactionKind.expense,
        'wise',
        Money(231000, Currency.usd),
        CivilDate(2026, 9, 30),
      ),
    ],
  ]);

  @override
  Stream<List<Account>> watchAccounts() => Stream.value([
    for (final (id, name, currency) in [
      ('card', 'Зарплатная карта', Currency.rub),
      ('wise', 'Wise USD', Currency.usd),
    ])
      Account(
        id: id,
        name: name,
        type: AccountType.debit,
        openingBalance: Money(0, currency),
        includeInTotals: true,
        archived: false,
        sortOrder: 0,
      ),
  ]);

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      Stream.value(const []);

  @override
  Stream<RateBook> watchRates() => Stream.value(
    RateBook([
      DayRates(CivilDate(2026, 9, 30), {'USD': Decimal.parse('81.20')}),
    ]),
  );

  @override
  Stream<List<LedgerImport>> watchImports() => Stream.value([
    if (!empty)
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
  ]);

  @override
  Future<void> categorize(List<(Transaction, String)> choices) async {}

  @override
  Future<String> makeTransfer(TransferPair pair) async => 'transfer';
}

void main() {
  late InboxSummaryCubit summary;

  Future<InboxState> counted(InboxRepository ledger) async {
    summary = InboxSummaryCubit(ledger, DismissedPairs(_Store()));
    return summary.stream.firstWhere((state) => !state.loading);
  }

  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() async {
    await summary.close();
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('the strip on the overview says what waits and leads in', (
    tester,
  ) async {
    await counted(_Ledger());
    tester.pumpComponent(
      BlocProvider.value(
        value: summary,
        child: const InboxCard(href: 'inbox/'),
      ),
    );
    await tester.pump();

    expect(find.text('3 ждут решения во «Входящих»'), findsOneComponent);
    expect(
      find.text(
        '2 без категории и перевод со счёта «Wise USD» · после импорта '
        'Альфа-Банка',
      ),
      findsOneComponent,
    );
    expect(links(), ['inbox/']);
  });

  testComponents('the strip stays away when nothing waits', (tester) async {
    await counted(_Ledger(empty: true));
    tester.pumpComponent(
      BlocProvider.value(
        value: summary,
        child: const InboxCard(href: 'inbox/'),
      ),
    );
    await tester.pump();

    expect(find.tag('a'), findsNothing);
  });

  testComponents('the row in More counts what waits after which import', (
    tester,
  ) async {
    final state = await counted(_Ledger());
    tester.pumpComponent(InboxTile(href: 'inbox/', state: state));

    expect(find.text('Входящие'), findsOneComponent);
    expect(
      find.text('3 ждут решения · после импорта Альфа-Банка'),
      findsOneComponent,
    );
    expect(find.text('3'), findsOneComponent);
    expect(links(), ['inbox/']);
  });

  testComponents('the row says that all is sorted, or nothing unread', (
    tester,
  ) async {
    final state = await counted(_Ledger(empty: true));
    tester.pumpComponent(InboxTile(href: 'inbox/', state: state));

    expect(find.text('Всё разобрано'), findsOneComponent);
    expect(find.text('0'), findsOneComponent);

    tester.pumpComponent(const InboxTile(href: 'inbox/'));
    await tester.pump();

    expect(find.text('Входящие'), findsOneComponent);
    expect(find.text('Всё разобрано'), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
