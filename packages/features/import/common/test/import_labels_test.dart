import 'package:decimal/decimal.dart';
import 'package:import_common/import_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

LedgerImport _import({
  String? format = 'alfa',
  Set<String> accountIds = const {'salary'},
  int transactions = 198,
}) => LedgerImport(
  id: 'import',
  fileName: 'alfa-2026-09.xlsx',
  firstDay: CivilDate(2026, 9, 1),
  lastDay: CivilDate(2026, 9, 30),
  importedAt: DateTime(2026, 10, 2, 21, 40),
  transactions: transactions,
  accountIds: accountIds,
  format: format,
);

Account _account(String id, String name) => Account(
  id: id,
  name: name,
  type: AccountType.debit,
  openingBalance: Money(0, Currency.rub),
  includeInTotals: true,
  archived: false,
  sortOrder: 0,
);

SourceAccount _source(String key, {Set<String> cards = const {}}) =>
    SourceAccount(
      key: key,
      operations: 1,
      spent: Decimal.zero,
      received: Decimal.zero,
      currency: 'RUB',
      cards: cards,
    );

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('the days of a statement', () {
    test('are one day, a month, or days of one month', () {
      expect(
        periodLabel(CivilDate(2026, 10, 3), CivilDate(2026, 10, 3)),
        '3 октября 2026',
      );
      expect(
        periodLabel(CivilDate(2026, 9, 1), CivilDate(2026, 9, 30)),
        'сентябрь 2026',
      );
      expect(
        periodLabel(CivilDate(2026, 10, 1), CivilDate(2026, 10, 15)),
        '1–15 октября 2026',
      );
    });

    test('of several months or years name both days', () {
      expect(
        periodLabel(CivilDate(2026, 9, 3), CivilDate(2026, 11, 4)),
        '3 сентября – 4 ноября 2026',
      );
      expect(
        periodLabel(CivilDate(2025, 12, 15), CivilDate(2026, 1, 14)),
        '15 декабря 2025 – 14 января 2026',
      );
    });

    test('in English put the month first', () {
      LocaleSettings.setLocaleSync(AppLocale.en);

      expect(
        periodLabel(CivilDate(2026, 10, 1), CivilDate(2026, 10, 15)),
        'October 1–15, 2026',
      );
    });
  });

  group('a past import', () {
    test('is its bank and its days, or its file', () {
      expect(importLabel(_import()), 'Альфа-Банк · сентябрь 2026');
      expect(
        importLabel(_import(format: null)),
        'alfa-2026-09.xlsx · сентябрь 2026',
      );
    });

    test('says how many operations went where and when', () {
      final accounts = [_account('salary', 'Зарплатная карта')];

      expect(
        importLine(_import(), accounts, now: DateTime(2026, 11, 4)),
        '198 операций → Зарплатная карта · 2 октября',
      );
      expect(
        importLine(
          _import(accountIds: {'salary', 'cash'}, transactions: 4310),
          accounts,
          now: DateTime(2027, 1, 4),
        ),
        '${formatCount(4310)} операций → 2 счёта · 2 октября 2026',
      );
    });
  });

  group('the heading of an account of the file', () {
    test('names its card, its name or nothing', () {
      expect(
        sourceTitle(_source('RUB', cards: {'4821'})),
        'Куда записать операции карты ••4821',
      );
      expect(
        sourceTitle(_source('Карта Сбера')),
        'Куда записать операции «Карта Сбера»',
      );
      expect(sourceTitle(_source('RUB')), 'Куда записать операции');
    });
  });

  group('the match of an account', () {
    test('says what ties it to the file', () {
      expect(matchLabel(AccountMatch.card), 'совпал номер карты');
      expect(matchLabel(AccountMatch.name), 'совпало название');
    });
  });

  group('the balance of the bank', () {
    SourceAccount closing(String? currency, String? balance) => SourceAccount(
      key: '',
      operations: 1,
      spent: Decimal.zero,
      received: Decimal.zero,
      currency: currency,
      closing: balance == null ? null : Decimal.parse(balance),
    );

    test('is the one at the end of the file, in its currency', () {
      expect(
        bankBalance(closing('RUB', '188913.71'), Money(0, Currency.rub)),
        Money(18891371, Currency.rub),
      );
    });

    test('is in the currency after the import when the file names none', () {
      expect(
        bankBalance(closing(null, '12.5'), Money(0, Currency.eur)),
        Money(1250, Currency.eur),
      );
    });

    test('is none when the file gives none', () {
      expect(bankBalance(closing('RUB', null), Money(0, Currency.rub)), isNull);
    });
  });

  group('the categories of the bank', () {
    const BankCategory food = (kind: CategoryKind.expense, name: 'Продукты');
    const BankCategory cafe = (kind: CategoryKind.expense, name: 'Кафе');
    const BankCategory gifts = (kind: CategoryKind.expense, name: 'Цветы');
    const layout = StatementLayout(
      header: 0,
      columns: [],
      roles: [],
      options: ReadingOptions(),
      format: alfa,
    );

    ImportState placed(
      Map<BankCategory, CategoryChoice> categories, {
      Set<BankCategory> chosen = const {},
      bool remembered = false,
      StatementLayout? layout = layout,
    }) => ImportState(
      layout: layout,
      choices: ImportChoices(accounts: const {}, categories: categories),
      chosen: chosen,
      remembered: remembered,
    );

    test('count those that Birka placed itself', () {
      final state = placed({
        food: const IntoCategory('food'),
        cafe: const NewCategory('Кафе'),
        gifts: const Unsorted(),
      });

      expect(categoriesLine(state), '2 из 3 узнали сами');
      expect(
        categoriesIntro(state),
        '2 из 3 узнали по названиям. Операции сразу встанут в ваши '
        'категории, а без выбора подождут во «Входящих».',
      );
    });

    test('leave out those that the person placed', () {
      final state = placed(
        {
          food: const IntoCategory('food'),
          cafe: const IntoCategory('cafe'),
          gifts: const IntoCategory('gifts'),
        },
        chosen: {cafe, gifts},
      );

      expect(categoriesLine(state), '1 из 3 узнали сами');
    });

    test('say when Birka knows none of them', () {
      final state = placed({food: const Unsorted(), gifts: const Unsorted()});

      expect(categoriesLine(state), 'Birka их пока не знает');
      expect(
        categoriesIntro(state),
        'Выберите, куда записать операции каждой категории банка. Без '
        'выбора они подождут во «Входящих».',
      );
    });

    test('say when they are placed as for the last file', () {
      final state = placed({
        food: const IntoCategory('food'),
      }, remembered: true);

      expect(categoriesLine(state), 'Как в прошлой выписке');
      expect(
        categoriesIntro(state),
        'Взяли ваш выбор с прошлой выписки Альфа-Банка. Поменяйте, если '
        'что-то теперь иначе.',
      );
      expect(
        categoriesIntro(
          placed({food: const Unsorted()}, remembered: true, layout: null),
        ),
        startsWith('Взяли ваш выбор с прошлой выписки вашего формата.'),
      );
    });

    test('stay for the next statements of the bank', () {
      expect(categoriesKept(alfa), 'Выбор запомним для выписок Альфа-Банка');
      expect(categoriesKept(null), 'Выбор запомним для выписок вашего формата');
    });
  });

  group('the rows that stay out', () {
    test('name their operation and what is wrong with their row', () {
      expect(
        rowProblemLabel(
          const RowProblem(
            131,
            RowFault.noSuchDay,
            '31.09.2026',
            description: 'Аптека №12',
          ),
        ),
        (title: 'Аптека №12', line: 'Строка 131 · 31.09.2026, такого дня нет'),
      );
      expect(
        rowProblemLabel(
          const RowProblem(
            57,
            RowFault.noAmount,
            'Перевод по номеру телефона',
            description: 'Перевод по номеру телефона',
          ),
        ),
        (title: 'Перевод по номеру телефона', line: 'Строка 57 · нет суммы'),
      );
      expect(
        rowProblemLabel(const RowProblem(12, RowFault.unreadableDate, 'вчера')),
        (title: 'вчера', line: 'Строка 12 · дата не читается'),
      );
      expect(
        planProblemLabel(
          const PlanProblem(
            4,
            PlanFault.otherCurrency,
            'USD',
            description: 'Burger',
          ),
        ),
        (title: 'Burger', line: 'Строка 4 · USD, у счёта другая валюта'),
      );
    });

    test('tell those that did not read from those the bank declined', () {
      final statement = readStatement(
        tableOf([
          ['Дата', 'Описание', 'Сумма'],
          ['01.10.2026', 'Кофейня', '-420,00'],
          ['31.09.2026', 'Аптека', '-1180,00'],
          ['02.10.2026', 'Перевод', ''],
        ]),
        const StatementLayout(
          header: 0,
          columns: [],
          roles: [
            ColumnRole.date,
            ColumnRole.description,
            ColumnRole.amount,
          ],
          options: ReadingOptions(),
        ),
      );

      expect(unreadRows(statement).map((it) => it.line), [3, 4]);
      expect(declinedRows(statement), isEmpty);
      expect(mostlyUnread(statement), isTrue);
    });

    test('count each kind under their number', () {
      expect(
        leftLine(unread: 2, declined: 1, unfit: 0),
        '2 не прочитались, 1 не прошла в банке',
      );
      expect(leftLine(unread: 0, declined: 0, unfit: 1), '1 не подходит счёту');
    });
  });

  test('the regular payments that a statement brings go by their names', () {
    List<FoundSchedule> found(List<String> names) => [
      for (final name in names)
        FoundSchedule(
          Schedule(
            id: name,
            kind: TransactionKind.expense,
            name: name,
            accountId: 'card',
            amount: Money(4500000, Currency.rub),
            every: ScheduleEvery.month,
            day: 25,
            next: CivilDate(2026, 11, 25),
            onDay: ScheduleOnDay.ask,
            reminder: ScheduleReminder.onDay,
          ),
          const [],
        ),
    ];

    expect(foundNames(found(['Аренда'])), 'Аренда');
    expect(foundNames(found(['Аренда', 'Интернет'])), 'Аренда и Интернет');
    expect(
      foundNames(found(['Аренда', 'Интернет', 'Спортзал'])),
      'Аренда, Интернет и Спортзал',
    );
    expect(
      foundNames(found(['Аренда', 'Интернет', 'Спортзал', 'Музыка'])),
      'Аренда, Интернет и ещё 2',
    );
  });

  group('an amount of a file', () {
    test('is money of its currency, or of the fallback', () {
      expect(
        moneyOf(Decimal.parse('1234.5'), 'RUB'),
        Money(123450, Currency.rub),
      );
      expect(
        moneyOf(Decimal.parse('0.123456'), 'USDT')!.minorUnits,
        123456,
      );
      expect(
        moneyOf(Decimal.parse('10'), null, fallback: Currency.eur),
        Money(1000, Currency.eur),
      );
    });

    test('with more digits than its currency is none', () {
      expect(moneyOf(Decimal.parse('0.001'), 'RUB'), isNull);
    });

    test('past what money holds is none', () {
      expect(moneyOf(Decimal.parse('100000000000000000'), 'RUB'), isNull);
      expect(moneyOf(Decimal.parse('-100000000000000000'), 'RUB'), isNull);
    });
  });
}
