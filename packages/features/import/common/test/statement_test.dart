import 'package:decimal/decimal.dart';
import 'package:import_common/import_common.dart';
import 'package:ledger/ledger.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Decimal _d(String value) => Decimal.parse(value);

Statement _read(StatementTable table, [ReadingOptions? options]) {
  final layout = detectLayout(table);
  return readStatement(
    table,
    options == null ? layout : layout.withOptions(options),
  );
}

/// A card of Alfa-Bank in October, as on the boards of the import.
final StatementTable _alfa = tableOf([
  ['АО «Альфа-Банк»'],
  [
    'Дата операции',
    'Дата проводки',
    'Описание',
    'Сумма',
    'Валюта',
    'Категория',
    'Номер карты',
    'Код MCC',
  ],
  for (final [date, text, amount, category] in [
    ['01.10.2026 10:00', 'TOPUP WISE EUROPE', '185 000,00', 'Переводы'],
    [
      '02.10.2026 18:40',
      'PRODUKTY BEREZKA MOSKVA',
      '−2 340,50',
      'Супермаркеты',
    ],
    ['03.10.2026 21:05', 'TAXI CITY', '−612,00', 'Такси и транспорт'],
    ['03.10.2026 09:12', 'ZERNO COFFEE', '−420,00', 'Рестораны и кафе'],
    ['04.10.2026 09:30', 'ZERNO COFFEE', '−420,00', 'Рестораны и кафе'],
    ['05.10.2026', 'APTEKA 12', '−1 180,00', 'Аптеки'],
    ['06.10.2026', 'Перевод по номеру телефона', '', 'Переводы'],
    ['31.09.2026', 'MARKET ONLINE', '−100,00', 'Маркетплейсы'],
    ['07.10.2026', 'ZHKU MOSKVA', '−6 845,30', 'ЖКХ'],
    ['09.10.2026', 'PEREVOD PO NOMERU', '−3 000,00', ''],
    ['12.10.2026', 'MARKET ONLINE', '−2 199,00', 'Маркетплейсы'],
  ])
    [date, '', text, amount, 'RUR', category, '220015******4821', '5411'],
  ['Итого', '', '', '−17 016,80'],
], file: TableFile.xlsx);

void main() {
  group('a card of Alfa-Bank', () {
    final statement = _read(_alfa);

    test('gives its operations in the order of time', () {
      expect(statement.rows, hasLength(9));
      expect(statement.from, CivilDate(2026, 10, 1));
      expect(statement.to, CivilDate(2026, 10, 12));
      expect(statement.rows.map((row) => row.description).take(4), [
        'TOPUP WISE EUROPE',
        'PRODUKTY BEREZKA MOSKVA',
        'ZERNO COFFEE',
        'TAXI CITY',
      ]);
      final topUp = statement.rows.first;
      expect(topUp.out, isNull);
      expect(topUp.into!.amount, _d('185000'));
      expect(topUp.into!.currency, 'RUB');
      expect(topUp.category, 'Переводы');
      expect(topUp.card, '4821');
      expect(topUp.date.time, const Duration(hours: 10));
      final bread = statement.rows[1];
      expect(bread.out!.amount, _d('2340.5'));
      expect(bread.change, _d('-2340.5'));
      expect(statement.rows[7].category, isNull);
      expect(statement.looksInverted, isFalse);
    });

    test('names the rows it leaves out and skips the total', () {
      expect(statement.problems.map((it) => (it.line, it.fault, it.text)), [
        (9, RowFault.noAmount, 'Перевод по номеру телефона'),
        (10, RowFault.noSuchDay, '31.09.2026'),
      ]);
    });

    test('sums up its one account', () {
      final account = statement.accounts.single;
      expect(account.key, 'RUB');
      expect(account.currency, 'RUB');
      expect(account.cards, {'4821'});
      expect(account.operations, 9);
      expect(account.spent, _d('17016.8'));
      expect(account.received, _d('185000'));
      expect(account.opening, isNull);
      expect(account.closing, isNull);
    });

    test('looks the wrong way round with the other sign', () {
      final flipped = _read(
        _alfa,
        statement.layout.options.copyWith(sign: AmountSign.expensePositive),
      );
      expect(flipped.rows.first.out!.amount, _d('185000'));
      expect(flipped.looksInverted, isTrue);
    });

    test('reads no amount with the other decimal mark', () {
      final wrong = _read(
        _alfa,
        statement.layout.options.copyWith(decimalMark: DecimalMark.dot),
      );
      expect(wrong.rows, isEmpty);
      expect(
        wrong.problems.where((it) => it.fault == RowFault.unreadableAmount),
        hasLength(9),
      );
      expect(wrong.problems.first.text, '185 000,00');
    });
  });

  test('takes the balances of a file that lists the latest first', () {
    final statement = _read(
      tableOf([
        [
          'TransferWise ID',
          'Date',
          'Amount',
          'Currency',
          'Description',
          'Running Balance',
          'Total fees',
        ],
        ['TW3', '01-10-2026', '-2310.00', 'USD', 'Card top-up', '190.00', '0'],
        ['TW2', '30-09-2026', '-5.50', 'USD', 'Coffee', '2500.00', '0'],
        ['TW1', '30-09-2026', '1000.00', 'USD', 'Salary', '2505.50', '0'],
        ['TW0', '28-09-2026', '-12.00', 'EUR', 'Bread', '88.00', '0'],
      ]),
    );
    expect(statement.layout.format, wise);
    expect(statement.rows.map((row) => row.description), [
      'Bread',
      'Salary',
      'Coffee',
      'Card top-up',
    ]);
    final [usd, eur] = statement.accounts;
    expect(usd.key, 'USD');
    expect(usd.operations, 3);
    expect(usd.opening, _d('1505.5'));
    expect(usd.closing, _d('190'));
    expect(eur.key, 'EUR');
    expect(eur.opening, _d('100'));
    expect(eur.closing, _d('88'));
  });

  test('reads the accounts, categories and transfers of Zenmoney', () {
    final statement = _read(
      tableOf([
        [
          'date',
          'categoryName',
          'payee',
          'comment',
          'outcomeAccountName',
          'outcome',
          'outcomeCurrencyShortTitle',
          'incomeAccountName',
          'income',
          'incomeCurrencyShortTitle',
          'createdDate',
          'changedDate',
          'qrCode',
        ],
        [
          '2026-10-01',
          'Продукты / Супермаркеты',
          'Берёзка',
          '',
          'Карта',
          '1234.50',
          'RUB',
          'Карта',
          '0',
          'RUB',
          '',
          '',
          '',
        ],
        [
          '2026-10-02',
          'Зарплата',
          'ООО Ромашка',
          'октябрь',
          'Карта',
          '0',
          'RUB',
          'Карта',
          '150000',
          'RUB',
          '',
          '',
          '',
        ],
        [
          '2026-10-03',
          '',
          '',
          'обмен',
          'Карта',
          '80090',
          'RUB',
          'Наличные USD',
          '1000',
          'USD',
          '',
          '',
          '',
        ],
      ]),
    );
    expect(statement.layout.format, zenmoney);
    expect(statement.layout.options.decimalMark, DecimalMark.dot);
    final [bread, salary, exchange] = statement.rows;
    expect(bread.out!.account, 'Карта');
    expect(bread.into, isNull);
    expect(bread.category, 'Продукты / Супермаркеты');
    expect(bread.description, 'Берёзка');
    expect(salary.into!.amount, _d('150000'));
    expect(salary.note, 'октябрь');
    expect(exchange.isTransfer, isTrue);
    expect(exchange.out!.amount, _d('80090'));
    expect(exchange.into!.account, 'Наличные USD');
    expect(exchange.into!.currency, 'USD');
    final [card, cash] = statement.accounts;
    expect(card.key, 'Карта');
    expect(card.currency, 'RUB');
    expect(card.spent, _d('81324.5'));
    expect(card.received, _d('150000'));
    expect(cash.key, 'Наличные USD');
    expect(cash.currency, 'USD');
    expect(cash.received, _d('1000'));
  });

  test('reads the export of T-Bank with its accounts and transfers', () {
    const headers = [
      'Имя счёта',
      'Номер карты',
      'Дата операции',
      'Сумма операции',
      'Валюта операции',
      'Сумма в валюте счёта',
      'Валюта счёта',
      'Статус',
      'Категория по-умолчанию',
      'Ваша категория',
      'MCC',
      'Описание',
      'Сообщение',
      'Округление',
      'Сумма операции с округлением',
      'Бонусы (включая кэшбэк)',
      'Учёт в аналитике',
    ];
    List<String> row(
      String account,
      String card,
      String date,
      String amount,
      String inAccount,
      String status,
      String category,
      String own,
      String text, {
      String currency = 'RUB',
      String message = '',
    }) => [
      account,
      card,
      date,
      amount,
      currency,
      inAccount,
      'RUB',
      status,
      category,
      own,
      '',
      text,
      message,
      '0,00',
      inAccount,
      '0,00',
      'Да',
    ];
    final statement = _read(
      tableOf([
        headers,
        row(
          'Карта',
          '*1234',
          '03.11.2026 19:56:45',
          '-1495,00',
          '-1495,00',
          'Ок',
          'Переводы',
          '',
          'Иван П.',
        ),
        row(
          'Карта',
          '*1234',
          '03.11.2026 14:18:36',
          '2000,00',
          '2000,00',
          'Ок',
          'Переводы',
          '',
          'Между своими счетами',
        ),
        row(
          'Копилка',
          '*5678',
          '03.11.2026 14:18:31',
          '-2000,00',
          '-2000,00',
          'Ок',
          'Переводы',
          '',
          'Между своими счетами',
        ),
        row(
          'Копилка',
          '*5678',
          '03.11.2026 14:18:21',
          '-2000,00',
          '-2000,00',
          'Ошибка',
          'Переводы',
          '',
          'Между своими счетами',
        ),
        row(
          'Карта',
          '*1234',
          '02.11.2026 20:38:40',
          '-10,00',
          '-1050,00',
          'Ок',
          'Фастфуд',
          'Обеды',
          'Burger Berlin',
          currency: 'EUR',
        ),
        row(
          'Карта',
          '*1234',
          '02.11.2026 17:31:14',
          '3000,00',
          '3000,00',
          'Ок',
          'Переводы',
          '',
          'Между своими счетами',
          message: 'на обед',
        ),
      ]),
    );
    expect(statement.layout.format, tbank);
    expect(statement.layout.known, headers.length);
    expect(statement.problems.map((it) => (it.line, it.fault)), [
      (5, RowFault.declined),
    ]);
    final [alone, burger, transfer, ivan] = statement.rows;
    expect(alone.into!.amount, _d('3000'));
    expect(alone.out, isNull);
    expect(alone.note, 'на обед');
    expect(burger.out!.amount, _d('1050'));
    expect(burger.out!.currency, 'RUB');
    expect(burger.category, 'Обеды');
    expect(burger.card, '1234');
    expect(transfer.isTransfer, isTrue);
    expect(transfer.out!.account, 'Копилка');
    expect(transfer.out!.card, '5678');
    expect(transfer.into!.account, 'Карта');
    expect(transfer.into!.card, '1234');
    expect(transfer.out!.amount, _d('2000'));
    expect(
      transfer.date.time,
      const Duration(hours: 14, minutes: 18, seconds: 31),
    );
    expect(transfer.line, 3);
    expect(ivan.out!.amount, _d('1495'));
    final [card, piggy] = statement.accounts;
    expect((card.key, card.operations), ('Карта', 4));
    expect(card.cards, {'1234'});
    expect(card.spent, _d('2545'));
    expect(card.received, _d('5000'));
    expect((piggy.key, piggy.operations), ('Копилка', 1));
    expect(piggy.cards, {'5678'});
    expect(piggy.spent, _d('2000'));
  });

  test('joins only what one transfer can be', () {
    final statement = _read(
      tableOf([
        ['Account', 'Date', 'Amount', 'Description'],
        ['Card', '03.11.2026 10:00:00', '-500', 'Between accounts'],
        ['Savings', '03.11.2026 10:05:00', '500', 'Between accounts'],
        ['Card', '03.11.2026 12:00:00', '-700', 'Shop'],
        ['Savings', '03.11.2026 12:00:30', '700', 'Salary'],
        ['Card', '03.11.2026 13:00:00', '-800', 'Same account'],
        ['Card', '03.11.2026 13:00:10', '800', 'Same account'],
        ['Card', '04.11.2026', '-900', 'To savings'],
        ['Savings', '04.11.2026', '900', 'To savings'],
      ]),
    );
    expect(statement.rows, hasLength(7));
    final transfer = statement.rows.singleWhere((row) => row.isTransfer);
    expect(transfer.out!.account, 'Card');
    expect(transfer.into!.account, 'Savings');
    expect(transfer.out!.amount, _d('900'));
  });

  test('leaves out what an older export of T-Bank did not carry out', () {
    final statement = _read(
      tableOf([
        [
          'Дата операции',
          'Дата платежа',
          'Номер карты',
          'Статус',
          'Сумма операции',
          'Валюта операции',
          'Сумма платежа',
          'Валюта платежа',
          'Кэшбэк',
          'Категория',
          'MCC',
          'Описание',
          'Бонусы (включая кэшбэк)',
          'Округление на инвесткопилку',
          'Сумма операции с округлением',
        ],
        [
          '03.10.2026 12:00:00',
          '04.10.2026',
          '*4821',
          'OK',
          '-10,00',
          'EUR',
          '-1 050,00',
          'RUB',
          '',
          'Рестораны',
          '5812',
          'Cafe Berlin',
          '0,00',
          '0,00',
          '-10,00',
        ],
        [
          '04.10.2026 13:00:00',
          '',
          '*4821',
          'FAILED',
          '-500,00',
          'RUB',
          '-500,00',
          'RUB',
          '',
          'Супермаркеты',
          '5411',
          'Магнит',
          '',
          '',
          '',
        ],
      ]),
    );
    final cafe = statement.rows.single;
    expect(cafe.out!.amount, _d('1050'));
    expect(cafe.out!.currency, 'RUB');
    expect(cafe.card, '4821');
    expect(statement.problems.single.fault, RowFault.declined);
    expect(statement.problems.single.text, 'Магнит');
  });

  test('takes the fees of Revolut and what it completed', () {
    final statement = _read(
      tableOf([
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
          'CARD_PAYMENT',
          'Current',
          '2026-10-03 10:00:00',
          '2026-10-04 10:00:00',
          'Cafe',
          '-10.00',
          '0.50',
          'EUR',
          'COMPLETED',
          '89.50',
        ],
        [
          'TOPUP',
          'Current',
          '2026-10-02 09:00:00',
          '2026-10-02 09:00:00',
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
          '2026-10-05 10:00:00',
          '',
          'Refused',
          '-3.00',
          '0.00',
          'EUR',
          'DECLINED',
          '89.50',
        ],
      ]),
    );
    final [topUp, cafe] = statement.rows;
    expect(topUp.fee, isNull);
    expect(cafe.fee, _d('0.5'));
    expect(cafe.change, _d('-10.5'));
    final account = statement.accounts.single;
    expect(account.spent, _d('10.5'));
    expect(account.opening, _d('0'));
    expect(account.closing, _d('89.5'));
    expect(statement.problems.single.text, 'Refused');
  });

  test('reads columns of money in and out', () {
    final statement = _read(
      tableOf([
        ['Date', 'Narrative', 'Debit', 'Credit', 'Balance'],
        ['01/10/2026', 'TOPUP', '', '1,250.00', '1,300.00'],
        ['13/10/2026', 'TAXI CITY', '6.12', '', '1,293.88'],
        ['14/10/2026', 'NOTHING', '0.00', '', '1,293.88'],
      ]),
    );
    final [topUp, taxi] = statement.rows;
    expect(topUp.into!.amount, _d('1250'));
    expect(taxi.out!.amount, _d('6.12'));
    expect(statement.accounts.single.opening, _d('50'));
    expect(statement.problems.single.fault, RowFault.zeroAmount);
  });

  test('reads nothing until a layout has a date and an amount', () {
    final table = tableOf([
      ['Название', 'Комментарий'],
      ['Кофе', 'с Олей'],
    ]);
    final statement = readStatement(table, detectLayout(table));
    expect(statement.rows, isEmpty);
    expect(statement.problems, isEmpty);
    expect(statement.accounts, isEmpty);
  });
}
