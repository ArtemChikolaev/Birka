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

  late FakeAccountsRepository repository;
  var closed = 0;

  Future<void> pump(WidgetTester tester, {String? accountId}) async {
    tester.view.physicalSize = const Size(780, 2800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) => AccountFormCubit(repository, accountId: accountId),
          child: AccountFormPage(onClose: () => closed++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byType(BirkaTextField),
  );

  String value(WidgetTester tester, String label) => tester
      .widget<TextField>(
        find.descendant(of: field(label), matching: find.byType(TextField)),
      )
      .controller!
      .text;

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.enterText(
      find.descendant(of: field(label), matching: find.byType(TextField)),
      text,
    );
    await tester.pump();
  }

  setUp(() {
    repository = FakeAccountsRepository();
    closed = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('saves a new account and closes', (tester) async {
    await pump(tester);

    await type(tester, 'Название', 'Зарплатная');
    await tester.tap(find.text('EUR'));
    await type(tester, 'Остаток сейчас', '2140');
    await type(tester, 'Последние 4 цифры карты', '1207');
    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    final draft = repository.added.single;
    expect(draft.name, 'Зарплатная');
    expect(draft.balance, Money(214000, Currency.eur));
    expect(draft.lastDigits, '1207');
    expect(closed, 1);
  });

  testWidgets('says what is wrong and stays open', (tester) async {
    await pump(tester);

    await type(tester, 'Остаток сейчас', 'много');
    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    expect(find.text('Дайте счёту название.'), findsOneWidget);
    expect(find.text('Введите сумму, например 1250,50.'), findsOneWidget);
    expect(repository.added, isEmpty);
    expect(closed, 0);
  });

  testWidgets('the card follows what is typed', (tester) async {
    await pump(tester);

    await type(tester, 'Название', 'Копилка');
    await type(tester, 'Остаток сейчас', '1250');

    expect(find.text('КОПИЛКА'), findsOneWidget);
    expect(find.text('1${space}250$space₽'), findsOneWidget);
  });

  testWidgets('a credit card asks for the debt', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Кредитная карта'));
    await tester.pump();
    expect(find.text('Долг по карте'), findsOneWidget);

    await type(tester, 'Название', 'Кредитка');
    await type(tester, 'Долг по карте', '1000');
    expect(find.text('−1${space}000$space₽'), findsOneWidget);

    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();
    expect(repository.added.single.balance, rub(-100000));
  });

  testWidgets('asks for card digits only on cards', (tester) async {
    await pump(tester);
    expect(field('Последние 4 цифры карты'), findsOneWidget);

    await tester.tap(find.text('Наличные'));
    await tester.pump();
    expect(field('Последние 4 цифры карты'), findsNothing);
  });

  testWidgets('saves the look and the choice about the capital', (
    tester,
  ) async {
    await pump(tester);

    await type(tester, 'Название', 'Карта');
    await tester.tap(find.bySemanticsLabel('sapphire'));
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('СОХРАНИТЬ'));
    await tester.pumpAndSettle();

    final draft = repository.added.single;
    expect(draft.art, AccountArt.sapphire);
    expect(draft.includeInTotals, isFalse);
  });

  testWidgets('the cross closes without saving', (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Закрыть'));
    expect(closed, 1);
    expect(repository.added, isEmpty);
  });

  group('an existing account', () {
    setUp(() {
      repository = FakeAccountsRepository([
        row('Карта', rub(125050), lastDigits: '4568', art: AccountArt.amber),
      ]);
    });

    testWidgets('fills in the fields and fixes its currency', (tester) async {
      await pump(tester, accountId: 'Карта');

      expect(find.text('Счёт'), findsOneWidget);
      expect(value(tester, 'Название'), 'Карта');
      expect(value(tester, 'Остаток сейчас'), '1250.50');
      expect(value(tester, 'Последние 4 цифры карты'), '4568');
      expect(find.text('RUB'), findsOneWidget);
      expect(find.text('EUR'), findsNothing);
    });

    testWidgets('saves over itself', (tester) async {
      await pump(tester, accountId: 'Карта');

      await type(tester, 'Название', 'Основная');
      await tester.tap(find.text('СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(repository.updated['Карта']?.name, 'Основная');
      expect(repository.added, isEmpty);
      expect(closed, 1);
    });

    testWidgets('shows what it holds, not what it started from', (
      tester,
    ) async {
      repository = FakeAccountsRepository([
        row('Карта', rub(3376000), opening: rub(1500000)),
      ]);
      await pump(tester, accountId: 'Карта');

      expect(value(tester, 'Остаток сейчас'), '33760.00');
      expect(find.text(formatMoney(rub(3376000))), findsOneWidget);
    });

    testWidgets('a name alone leaves the balance as it is', (tester) async {
      await pump(tester, accountId: 'Карта');

      await type(tester, 'Название', 'Основная');
      await tester.tap(find.text('СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(repository.updated['Карта']?.balance, isNull);
    });

    testWidgets('a new amount becomes the new balance', (tester) async {
      await pump(tester, accountId: 'Карта');

      await type(tester, 'Остаток сейчас', '2000');
      await tester.tap(find.text('СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(repository.updated['Карта']?.balance, rub(200000));
    });

    testWidgets('a new type keeps what it holds, and the field follows', (
      tester,
    ) async {
      await pump(tester, accountId: 'Карта');

      await tester.tap(find.text('Кредитная карта'));
      await tester.pumpAndSettle();

      expect(value(tester, t.accounts.form.debt), '-1250.50');
      expect(find.text(formatMoney(rub(125050))), findsOneWidget);

      await tester.tap(find.text('СОХРАНИТЬ'));
      await tester.pumpAndSettle();

      expect(repository.updated['Карта']?.balance, isNull);
    });

    testWidgets('can be moved to the archive', (tester) async {
      await pump(tester, accountId: 'Карта');

      await tester.tap(find.text('Убрать в архив'));
      await tester.pumpAndSettle();

      expect(repository.archived, {'Карта': true});
      expect(closed, 1);
    });

    testWidgets('offers to come back from the archive', (tester) async {
      repository.rows = [row('Старая', rub(100), archived: true)];
      await pump(tester, accountId: 'Старая');

      await tester.tap(find.text('Вернуть из архива'));
      await tester.pumpAndSettle();

      expect(repository.archived, {'Старая': false});
    });
  });

  testWidgets('a new account has nothing to archive', (tester) async {
    await pump(tester);
    expect(find.text('Убрать в архив'), findsNothing);
  });
}
