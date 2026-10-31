import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart' show Currency;
import 'package:overview_common/overview_common.dart' hide Category;
import 'package:overview_jaspr/overview_jaspr.dart';

final class _FakeRepository implements OverviewRepository {
  _FakeRepository({
    this.accounts = const [],
    this.changes = const [],
    this.spending = const [],
  });

  List<AccountBalance> accounts;
  List<DayChange> changes;
  List<CategoryTotal> spending;
  Exception? readFailure;

  Stream<T> _read<T>(T value) => Stream.multi((controller) {
    if (readFailure case final failure?) {
      controller.addError(failure);
    } else {
      controller.add(value);
    }
  });

  @override
  Stream<List<AccountBalance>> watchAccounts() => _read(accounts);

  @override
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) =>
      _read(changes);

  @override
  Stream<List<CategoryTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => _read(spending);
}

AccountBalance _account(String name, Money balance, {String? digits}) =>
    AccountBalance(
      Account(
        id: name,
        name: name,
        type: AccountType.debit,
        openingBalance: Money.zero(balance.currency),
        lastDigits: digits,
        includeInTotals: true,
        archived: false,
        sortOrder: 0,
      ),
      balance,
    );

CategoryTotal _total(String name, Money total) => CategoryTotal(
  Category(
    id: name,
    kind: CategoryKind.expense,
    name: name,
    archived: false,
    sortOrder: 0,
    color: '#4ade80',
  ),
  total,
);

/// Holds whether the amounts are hidden, as the host does.
class _Host extends StatefulComponent {
  const _Host({required this.child});

  final Component child;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  var _hidden = false;

  @override
  Component build(BuildContext context) => HiddenAmounts(
    hidden: _hidden,
    onToggle: () => setState(() => _hidden = !_hidden),
    child: component.child,
  );
}

void main() {
  const space = ' ';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  late _FakeRepository repository;

  Future<void> pump(ComponentTester tester, {String? note}) async {
    tester.pumpComponent(
      _Host(
        child: BlocProvider(
          create: (_) => OverviewCubit(
            repository,
            now: () => DateTime(2026, 10, 31, 9, 30),
          ),
          child: OverviewPage(
            addAccountHref: 'new-account',
            accountsHref: 'accounts',
            hrefOfAccount: (id) => 'open/$id',
            note: note,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  Finder named(String label) => find.byComponentPredicate(
    (component) =>
        component is DomComponent &&
        component.attributes?['aria-label'] == label,
    description: 'element "$label"',
  );

  setUp(() {
    repository = _FakeRepository(
      accounts: [
        _account('Карта', rub(100000000), digits: '4568'),
        _account('Наличные', rub(5000000)),
        _account('Доллары', Money(120000, Currency.usd)),
      ],
      changes: [
        DayChange(CivilDate(2026, 10, 20), rub(2000000)),
        DayChange(CivilDate(2026, 10, 30), rub(-500000)),
      ],
      spending: [
        _total('Продукты', rub(3000000)),
        _total('Кафе', rub(1000000)),
        _total('Такси', rub(500000)),
        _total('Спорт', rub(200000)),
      ],
    );
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('shows the capital and what changed it', (tester) async {
    await pump(tester);

    expect(find.text('Октябрь'), findsOneComponent);
    expect(find.text('Капитал · 2 валюты'), findsOneComponent);
    expect(find.text('1${space}050${space}000$space₽'), findsOneComponent);
    // The other currency, and its account.
    expect(find.text('1${space}200$space\$'), findsNComponents(2));
    expect(find.text('+15${space}000$space₽'), findsOneComponent);
    expect(find.text('за октябрь'), findsOneComponent);
    expect(find.byType(BirkaLineChart), findsOneComponent);
  });

  testComponents('says where the data lives', (tester) async {
    await pump(tester, note: 'Только в этом браузере');

    expect(find.text('Только в этом браузере'), findsOneComponent);
  });

  testComponents('another period changes what the change covers', (
    tester,
  ) async {
    await pump(tester);

    await tap(tester, 'Неделя');

    expect(find.text('за неделю'), findsOneComponent);
    expect(find.text('−5${space}000$space₽'), findsOneComponent);
  });

  testComponents('a fall shows in its own color', (tester) async {
    repository.changes = [
      DayChange(CivilDate(2026, 10, 30), rub(-500000)),
    ];
    await pump(tester);

    final pill = find.byComponentPredicate(
      (component) =>
          component is DomComponent &&
          component.classes == 'overview__pill overview__pill--fall',
    );
    expect(pill, findsOneComponent);
  });

  testComponents('one currency says nothing of currencies', (tester) async {
    repository.accounts = [_account('Карта', rub(100000))];
    await pump(tester);

    expect(find.text('Капитал'), findsOneComponent);
  });

  testComponents('no change has no pill', (tester) async {
    repository.changes = const [];
    await pump(tester);

    expect(find.text('за октябрь'), findsNothing);
  });

  testComponents('accounts outside the totals leave no capital to chart', (
    tester,
  ) async {
    repository.accounts = [
      AccountBalance(
        const Account(
          id: 'old',
          name: 'Старый',
          type: AccountType.debit,
          openingBalance: Money.zero(Currency.rub),
          includeInTotals: false,
          archived: false,
          sortOrder: 0,
        ),
        rub(100),
      ),
    ];
    await pump(tester);

    expect(find.byType(BirkaLineChart), findsNothing);
    expect(find.text('Старый'), findsOneComponent);
  });

  testComponents('the cards lead to their accounts', (tester) async {
    await pump(tester);

    expect(links(), [
      'accounts',
      'open/Карта',
      'open/Наличные',
      'open/Доллары',
    ]);
    expect(find.text('Все 3'), findsOneComponent);
    expect(find.text('Рубли · •• 4568'), findsOneComponent);
  });

  testComponents('one account takes the whole row', (tester) async {
    repository.accounts = [_account('Карта', rub(100000))];
    await pump(tester);

    final inRow = find.byComponentPredicate(
      (component) =>
          component is DomComponent && component.classes == 'overview__cards',
    );
    expect(inRow, findsNothing);
    expect(find.byType(AccountCard), findsOneComponent);
  });

  testComponents('shows what the month cost', (tester) async {
    await pump(tester);

    expect(find.text('Траты в октябре'), findsOneComponent);
    expect(find.text('−47${space}000$space₽'), findsOneComponent);
    expect(find.text('Продукты'), findsOneComponent);
    expect(find.text('30${space}000$space₽'), findsOneComponent);
    expect(find.text('Такси'), findsOneComponent);
    expect(find.text('Спорт'), findsNothing);
    final ring =
        find.byType(BirkaRing).evaluate().single.component as BirkaRing;
    expect(ring.slices, hasLength(4));
    expect(ring.slices.first.color, '#4ade80');
  });

  testComponents('other currencies stand under the categories', (tester) async {
    repository.spending = [
      _total('Продукты', rub(3000000)),
      _total('Кафе', Money(5000, Currency.eur)),
    ];
    await pump(tester);

    expect(find.text('50$space€'), findsOneComponent);
  });

  testComponents('a month without spending says so', (tester) async {
    repository.spending = const [];
    await pump(tester);

    expect(find.text('В этом месяце трат пока нет.'), findsOneComponent);
    expect(find.byType(BirkaRing), findsNothing);
  });

  testComponents('without accounts it leads to adding one', (tester) async {
    repository.accounts = const [];
    await pump(tester);

    expect(find.text('Пока нет счетов'), findsOneComponent);
    expect(links(), ['new-account']);
  });

  testComponents('the eye hides every amount and brings it back', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('1${space}050${space}000$space₽'), findsOneComponent);

    await tester.click(named('Скрыть суммы'));
    await tester.pump();

    expect(find.text('1${space}050${space}000$space₽'), findsNothing);
    expect(find.text('•••$space₽'), findsComponents);
    expect(named('Показать суммы'), findsOneComponent);

    await tester.click(named('Показать суммы'));
    await tester.pump();

    expect(find.text('1${space}050${space}000$space₽'), findsOneComponent);
  });

  testComponents('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать обзор.'), findsOneComponent);

    repository.readFailure = null;
    await tap(tester, 'Повторить');
    await tester.pump();

    expect(find.text('Карта'), findsOneComponent);
  });
}
