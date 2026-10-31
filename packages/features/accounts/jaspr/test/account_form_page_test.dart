import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/accounts_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

import 'fake_accounts_repository.dart';

void main() {
  const space = '\u00A0';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  late FakeAccountsRepository repository;
  var closed = 0;

  Future<void> pump(ComponentTester tester, {String? accountId}) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => AccountFormCubit(repository, accountId: accountId),
        child: AccountFormPage(onClose: () => closed++),
      ),
    );
    await tester.pump();
  }

  Iterable<BirkaTextField> fields() => find
      .byType(BirkaTextField)
      .evaluate()
      .map((element) => element.component as BirkaTextField);

  BirkaTextField field(String label) =>
      fields().singleWhere((field) => field.label == label);

  Future<void> type(
    ComponentTester tester,
    String label,
    String text,
  ) async {
    field(label).onChanged(text);
    await tester.pump();
  }

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  Future<void> save(ComponentTester tester) async {
    (find.byType(BirkaForm).evaluate().single.component as BirkaForm)
        .onSubmit();
    await tester.pump();
  }

  setUp(() {
    setIsClientForTesting(true);
    repository = FakeAccountsRepository();
    closed = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('saves a new account and closes', (tester) async {
    await pump(tester);

    await type(tester, 'Название', 'Зарплатная');
    await tap(tester, 'EUR');
    await type(tester, 'Остаток сейчас', '2140');
    await type(tester, 'Последние 4 цифры карты', '1207');
    await save(tester);

    final draft = repository.added.single;
    expect(draft.name, 'Зарплатная');
    expect(draft.balance, Money(214000, Currency.eur));
    expect(draft.lastDigits, '1207');
    expect(closed, 1);
  });

  testComponents('says what is wrong and stays open', (tester) async {
    await pump(tester);

    await type(tester, 'Остаток сейчас', 'много');
    await save(tester);

    expect(find.text('Дайте счёту название.'), findsOneComponent);
    expect(find.text('Введите сумму, например 1250,50.'), findsOneComponent);
    expect(repository.added, isEmpty);
    expect(closed, 0);
  });

  testComponents('the card follows what is typed', (tester) async {
    await pump(tester);

    await type(tester, 'Название', 'Копилка');
    await type(tester, 'Остаток сейчас', '1250');

    expect(find.text('Копилка'), findsOneComponent);
    expect(find.text('1${space}250$space₽'), findsOneComponent);
  });

  testComponents('a credit card asks for the debt', (tester) async {
    await pump(tester);

    await tap(tester, 'Кредитная карта');
    await type(tester, 'Название', 'Кредитка');
    await type(tester, 'Долг по карте', '1000');
    expect(find.text('−1${space}000$space₽'), findsOneComponent);

    await save(tester);
    expect(repository.added.single.balance, rub(-100000));
  });

  testComponents('asks for card digits only on cards', (tester) async {
    await pump(tester);
    expect(fields().map((field) => field.label), contains(contains('цифры')));

    await tap(tester, 'Наличные');
    expect(
      fields().map((field) => field.label),
      isNot(contains(contains('цифры'))),
    );
  });

  testComponents('saves the look and the choice about the capital', (
    tester,
  ) async {
    await pump(tester);

    await type(tester, 'Название', 'Карта');
    await tester.click(
      find.ancestor(
        of: find.byComponentPredicate(
          (component) =>
              component is CardArtThumbnail &&
              component.art == CardArt.sapphire,
        ),
        matching: find.tag('button'),
      ),
    );
    await tester.click(find.byType(BirkaSwitch));
    await save(tester);

    final draft = repository.added.single;
    expect(draft.art, AccountArt.sapphire);
    expect(draft.includeInTotals, isFalse);
  });

  testComponents('the cross closes without saving', (tester) async {
    await pump(tester);

    await tester.click(find.byType(GlassIconButton));

    expect(closed, 1);
    expect(repository.added, isEmpty);
  });

  testComponents('a new account has nothing to archive', (tester) async {
    await pump(tester);

    expect(find.text('Убрать в архив'), findsNothing);
  });

  testComponents('an account that is not here closes the form', (tester) async {
    await pump(tester, accountId: 'nobody');

    expect(closed, 1);
  });

  group('an existing account', () {
    setUp(() {
      repository = FakeAccountsRepository([
        row('Карта', rub(125050), lastDigits: '4568', art: AccountArt.amber),
      ]);
    });

    testComponents('fills in the fields and fixes its currency', (
      tester,
    ) async {
      await pump(tester, accountId: 'Карта');

      expect(find.text('Счёт'), findsOneComponent);
      expect(field('Название').value, 'Карта');
      expect(field('Остаток сейчас').value, '1250.50');
      expect(field('Последние 4 цифры карты').value, '4568');
      expect(find.text('RUB'), findsOneComponent);
      expect(find.text('EUR'), findsNothing);
    });

    testComponents('saves over itself', (tester) async {
      await pump(tester, accountId: 'Карта');

      await type(tester, 'Название', 'Основная');
      await save(tester);

      expect(repository.updated['Карта']?.name, 'Основная');
      expect(repository.added, isEmpty);
      expect(closed, 1);
    });

    testComponents('shows what it holds, not what it started from', (
      tester,
    ) async {
      repository = FakeAccountsRepository([
        row('Карта', rub(3376000), opening: rub(1500000)),
      ]);
      await pump(tester, accountId: 'Карта');

      expect(field('Остаток сейчас').value, '33760.00');
    });

    testComponents('a name alone leaves the balance as it is', (tester) async {
      await pump(tester, accountId: 'Карта');

      await type(tester, 'Название', 'Основная');
      await save(tester);

      expect(repository.updated['Карта']?.balance, isNull);
    });

    testComponents('a new amount becomes the new balance', (tester) async {
      await pump(tester, accountId: 'Карта');

      await type(tester, 'Остаток сейчас', '2000');
      await save(tester);

      expect(repository.updated['Карта']?.balance, rub(200000));
    });

    testComponents('a new type keeps what it holds, and the field follows', (
      tester,
    ) async {
      await pump(tester, accountId: 'Карта');

      await tap(tester, 'Кредитная карта');

      expect(field(t.accounts.form.debt).value, '-1250.50');

      await save(tester);

      expect(repository.updated['Карта']?.balance, isNull);
    });

    testComponents('can be moved to the archive', (tester) async {
      await pump(tester, accountId: 'Карта');

      await tap(tester, 'Убрать в архив');

      expect(repository.archived, {'Карта': true});
      expect(closed, 1);
    });

    testComponents('offers to come back from the archive', (tester) async {
      repository.rows = [row('Старая', rub(100), archived: true)];
      await pump(tester, accountId: 'Старая');

      await tap(tester, 'Вернуть из архива');

      expect(repository.archived, {'Старая': false});
    });
  });
}
