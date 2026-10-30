import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/accounts_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

import 'fake_accounts_repository.dart';

void main() {
  const space = ' ';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  Money eur(int minorUnits) => Money(minorUnits, Currency.eur);

  final opened = <String>[];
  var added = 0;
  var left = 0;

  Future<void> pump(
    WidgetTester tester,
    FakeAccountsRepository repository,
  ) async {
    tester.view.physicalSize = const Size(780, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) => AccountsCubit(repository),
          child: AccountsPage(
            onBack: () => left++,
            onAdd: () => added++,
            onOpen: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    opened.clear();
    added = 0;
    left = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('without accounts it invites to add one', (tester) async {
    await pump(tester, FakeAccountsRepository());

    expect(find.text('Пока нет счетов'), findsOneWidget);
    await tester.tap(find.text('ДОБАВИТЬ СЧЁТ'));
    expect(added, 1);
  });

  testWidgets('shows the main account as a card and in the list', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Зарплатная', rub(41230000), lastDigits: '4568'),
        row('Наличные', rub(1850000), type: AccountType.cash),
      ]),
    );

    expect(find.text('ЗАРПЛАТНАЯ'), findsOneWidget);
    expect(find.text('Зарплатная'), findsOneWidget);
    expect(find.text('Рубли · •• 4568'), findsNWidgets(2));
    expect(find.text('412${space}300$space₽'), findsNWidgets(2));
    expect(find.text('основной'), findsOneWidget);
    expect(find.text('Рубли · Наличные'), findsOneWidget);
  });

  testWidgets('adds the capital up per currency with the right ending', (
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

    final capital = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText() ==
              'Капитал 1${space}500$space₽ и €2${space}140 в 3 счетах'
                  .replaceAll('€2${space}140', '2${space}140$space€'),
    );
    expect(capital, findsOneWidget);
  });

  testWidgets('a single account takes the singular ending', (tester) async {
    await pump(tester, FakeAccountsRepository([row('Карта', rub(100))]));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().endsWith('в 1 счёте'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a debt shows in the color of a fall', (tester) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Карта', rub(100)),
        row('Кредитка', rub(-100000), type: AccountType.credit),
      ]),
    );

    final amount = tester.widget<AmountText>(
      find.widgetWithText(AmountText, '−1${space}000$space₽'),
    );
    expect(amount.tone, AmountTone.negative);
  });

  testWidgets('the rows, the card and the buttons do their jobs', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Карта', rub(100)),
        row('Наличные', rub(100)),
      ]),
    );

    await tester.tap(find.text('Наличные'));
    await tester.tap(find.text('КАРТА'));
    await tester.tap(find.bySemanticsLabel('Добавить счёт'));
    await tester.tap(find.bySemanticsLabel('Назад'));

    expect(opened, ['Наличные', 'Карта']);
    expect(added, 1);
    expect(left, 1);
  });

  testWidgets('archived accounts go to their own section', (tester) async {
    await pump(
      tester,
      FakeAccountsRepository([
        row('Карта', rub(100)),
        row('Старая', rub(100), archived: true),
      ]),
    );

    expect(find.text('АРХИВ'), findsOneWidget);
    await tester.tap(find.text('Старая'));
    expect(opened, ['Старая']);
  });

  testWidgets('with only archived accounts it still shows them', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAccountsRepository([row('Старая', rub(100), archived: true)]),
    );

    expect(find.text('Пока нет счетов'), findsNothing);
    expect(find.text('Старая'), findsOneWidget);
    expect(find.byType(CardArtSurface), findsOneWidget);
  });

  testWidgets('a failed read offers to try again', (tester) async {
    final repository = FakeAccountsRepository()..broken = true;
    await pump(tester, repository);
    expect(find.text('Не удалось прочитать счета.'), findsOneWidget);

    repository
      ..broken = false
      ..rows = [row('Карта', rub(100))];
    await tester.tap(find.text('ПОВТОРИТЬ'));
    // Cancelling a finished stream completes outside the fake clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Карта'), findsOneWidget);
  });
}
