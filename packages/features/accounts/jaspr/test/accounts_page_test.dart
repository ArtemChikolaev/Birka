import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/accounts_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

import 'fake_accounts_repository.dart';

void main() {
  const space = '\u00A0';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

  Future<void> pump(
    ComponentTester tester,
    FakeAccountsRepository repository, {
    String? note,
  }) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => AccountsCubit(repository),
        child: AccountsPage(
          backHref: './',
          addHref: 'add',
          hrefOf: (id) => 'open/$id',
          note: note,
        ),
      ),
    );
    await tester.pump();
  }

  List<String?> links() => [
    for (final element in find.tag('a').evaluate())
      (element.component as DomComponent).attributes?['href'],
  ];

  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('without accounts it invites to add one', (tester) async {
    await pump(tester, FakeAccountsRepository());

    expect(find.text('Пока нет счетов'), findsOneComponent);
    expect(links(), ['./', 'add', 'add']);
  });

  testComponents('shows the main account as a card and in the list', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Зарплатная', rub(41230000), lastDigits: '4568'),
        row('Наличные', rub(1850000), type: AccountType.cash),
      ]),
    );

    expect(find.text('Зарплатная'), findsNComponents(2));
    expect(find.text('Рубли · •• 4568'), findsNComponents(2));
    expect(find.text('412${space}300$space₽'), findsNComponents(2));
    expect(find.text('основной'), findsOneComponent);
    expect(find.text('Рубли · Наличные'), findsOneComponent);
  });

  testComponents('adds the capital up per currency with the right ending', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Карта', rub(100000)),
        row('Евро', eur(214000)),
        row('Наличные', rub(50000)),
        row('Копилка', rub(1), includeInTotals: false),
      ]),
    );

    expect(find.text('Капитал '), findsOneComponent);
    expect(find.text('1${space}500$space₽'), findsOneComponent);
    expect(find.text(' и '), findsOneComponent);
    expect(find.text('2${space}140$space€'), findsNComponents(2));
    expect(find.text(' в 3 счетах'), findsOneComponent);
  });

  testComponents('a debt shows in the color of a fall', (tester) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Карта', rub(100)),
        row('Кредитка', rub(-100000), type: AccountType.credit),
      ]),
    );

    final amount =
        find
                .componentWithText(AmountText, '−1${space}000$space₽')
                .evaluate()
                .single
                .component
            as AmountText;
    expect(amount.tone, AmountTone.negative);
  });

  testComponents('the rows, the card and the buttons are links', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Карта', rub(100)),
        row('Наличные', rub(100)),
      ]),
    );

    expect(links(), [
      './',
      'add',
      'open/Карта',
      'open/Карта',
      'open/Наличные',
    ]);
  });

  testComponents('archived accounts go to their own section', (tester) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Карта', rub(100)),
        row('Старая', rub(100), archived: true),
      ]),
    );

    expect(find.text('Архив'), findsOneComponent);
    expect(links(), contains('open/Старая'));
  });

  testComponents('with only archived accounts it still shows them', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountsRepository([row('Старая', rub(100), archived: true)]),
    );

    expect(find.text('Пока нет счетов'), findsNothing);
    expect(find.text('Старая'), findsOneComponent);
    expect(find.byType(GlassPageHeader), findsOneComponent);
  });

  testComponents('a failed read offers to try again', (tester) async {
    final repository = FakeAccountsRepository()..broken = true;
    await pump(tester, repository);
    expect(find.text('Не удалось прочитать счета.'), findsOneComponent);

    repository
      ..broken = false
      ..rows = [row('Карта', rub(100))];
    await tester.click(find.tag('button'));
    await tester.pump();
    expect(find.text('Карта'), findsNComponents(2));
  });

  testComponents('a note shows once the accounts are here', (tester) async {
    await pump(tester, FakeAccountsRepository(), note: 'В этом браузере');

    expect(find.text('В этом браузере'), findsOneComponent);
  });
}
