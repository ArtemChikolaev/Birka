import 'package:import_common/import_common.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('detectLayout', () {
    test('knows the workbook of Alfa-Bank under its title rows', () {
      final layout = detectLayout(
        tableOf([
          ['АО «Альфа-Банк»'],
          ['Выписка по карте ••4821', '', 'за 01.10.2026 - 31.10.2026'],
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
          [
            '03.10.2026 14:22',
            '05.10.2026',
            'PRODUKTY BEREZKA MOSKVA',
            '−2 340,50',
            'RUR',
            'Супермаркеты',
            '220015******4821',
            '5411',
          ],
        ], file: TableFile.xlsx),
      );
      expect(layout.format, alfa);
      expect(layout.header, 2);
      expect(layout.known, 8);
      expect(layout.roles, [
        ColumnRole.date,
        ColumnRole.skip,
        ColumnRole.description,
        ColumnRole.amount,
        ColumnRole.currency,
        ColumnRole.category,
        ColumnRole.card,
        ColumnRole.skip,
      ]);
      expect(layout.options.decimalMark, DecimalMark.comma);
      expect(layout.columns[3].header, 'Сумма');
      expect(layout.columns[3].sample.text, '−2 340,50');
      expect(layout.missing, isEmpty);
    });

    test('knows the older CSV of Alfa-Bank with money in and out', () {
      final layout = detectLayout(
        tableOf([
          [
            'Тип счёта',
            'Номер счета',
            'Валюта',
            'Дата операции',
            'Референс проводки',
            'Описание операции',
            'Приход',
            'Расход',
            '',
          ],
          ['Текущий', '40817', 'RUR', '03.10.26', 'X1', 'ZERNO', '0', '420'],
        ]),
      );
      expect(layout.format, alfa);
      expect(layout.roles.sublist(2, 8), [
        ColumnRole.currency,
        ColumnRole.date,
        ColumnRole.skip,
        ColumnRole.description,
        ColumnRole.income,
        ColumnRole.expense,
      ]);
    });

    test('knows T-Bank, Zenmoney, Wise and Revolut', () {
      final headers = {
        tbank: [
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
        zenmoney: [
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
        wise: [
          'TransferWise ID',
          'Date',
          'Amount',
          'Currency',
          'Description',
          'Payment Reference',
          'Running Balance',
          'Exchange From',
          'Exchange To',
          'Exchange Rate',
          'Payer Name',
          'Payee Name',
          'Payee Account Number',
          'Merchant',
          'Card Last Four Digits',
          'Card Holder Full Name',
          'Attachment',
          'Note',
          'Total fees',
          'Exchange To Amount',
        ],
        revolut: [
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
      };
      for (final MapEntry(key: format, value: row) in headers.entries) {
        final layout = detectLayout(tableOf([row]));
        expect(layout.format, format, reason: format.id);
        expect(layout.known, row.length, reason: format.id);
      }
    });

    test('guesses a format it does not know from words', () {
      final layout = detectLayout(
        tableOf([
          ['Date', 'Narrative', 'Debit', 'Credit', 'Balance'],
          ['01/10/2026', 'TOPUP', '', '1,250.00', '1,300.00'],
          ['13/10/2026', 'TAXI CITY', '6.12', '', '1,293.88'],
        ]),
      );
      expect(layout.format, isNull);
      expect(layout.header, 0);
      expect(layout.roles, [
        ColumnRole.date,
        ColumnRole.description,
        ColumnRole.expense,
        ColumnRole.income,
        ColumnRole.balance,
      ]);
      expect(layout.options.decimalMark, DecimalMark.dot);
      expect(layout.options.dateOrder, DateOrder.dayMonthYear);
    });

    test('guesses the roles from values when there are no headers', () {
      final layout = detectLayout(
        tableOf([
          ['ZERNO', '03.10.2026', '-420,00'],
          ['TAXI', '04.10.2026', '-612,00'],
        ]),
      );
      expect(layout.header, -1);
      expect(layout.roles, [
        ColumnRole.skip,
        ColumnRole.date,
        ColumnRole.amount,
      ]);
      expect(layout.columns.first.header, '');
      expect(layout.columns.first.sample.text, 'ZERNO');
    });

    test('says what a layout lacks', () {
      final layout = detectLayout(
        tableOf([
          ['Выписка'],
          ['Название', 'Комментарий'],
          ['Кофе', 'с Олей'],
        ]),
      );
      expect(layout.missing, {ColumnRole.date, ColumnRole.amount});
      expect(layout.header, 1);
      expect(layout.columns.map((column) => column.header), [
        'Название',
        'Комментарий',
      ]);
    });
  });

  test('reads a table as the format a person chose, the rest by words', () {
    final table = tableOf([
      ['Дата операции', 'Описание', 'Сумма', 'Статус'],
      ['03.10.2026', 'ZERNO', '-420,00', 'OK'],
    ]);
    expect(detectLayout(table).format, alfa);
    final layout = layoutAs(table, tbank);
    expect(layout.format, tbank);
    expect(layout.known, 3);
    expect(layout.roles, [
      ColumnRole.date,
      ColumnRole.description,
      ColumnRole.amount,
      ColumnRole.status,
    ]);
    expect(layout.missing, isEmpty);
  });

  test('moves a role that one column holds', () {
    final layout = detectLayout(
      tableOf([
        ['Date', 'Value date', 'Details', 'Payee', 'Amount'],
        ['03.10.2026', '05.10.2026', 'ZERNO', 'Zerno LLC', '-420.00'],
      ]),
    );
    expect(layout.roles, [
      ColumnRole.date,
      ColumnRole.skip,
      ColumnRole.description,
      ColumnRole.description,
      ColumnRole.amount,
    ]);
    final moved = layout.withRole(1, ColumnRole.date);
    expect(moved.roles.take(2), [ColumnRole.skip, ColumnRole.date]);
    final both = layout.withRole(1, ColumnRole.description);
    expect(
      both.roles.where((role) => role == ColumnRole.description),
      hasLength(3),
    );
    final options = layout.options.copyWith(sign: AmountSign.expensePositive);
    expect(
      layout.withOptions(options).options.sign,
      AmountSign.expensePositive,
    );
  });
}
