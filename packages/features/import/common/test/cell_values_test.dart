import 'package:decimal/decimal.dart';
import 'package:import_common/import_common.dart';
import 'package:ledger/ledger.dart';
import 'package:test/test.dart';

Decimal? _amount(String text, DecimalMark mark) =>
    readAmount(Cell.text(text), mark);

Matcher _fault(CellFault fault) => throwsA(
  isA<CellException>().having((error) => error.fault, 'fault', fault),
);

void main() {
  group('readAmount', () {
    test('reads Russian amounts by the comma', () {
      expect(_amount('−2 340,50', DecimalMark.comma), Decimal.parse('-2340.5'));
      expect(
        _amount('+185 000,00 ₽', DecimalMark.comma),
        Decimal.parse('185000'),
      );
      expect(_amount('1.234,56', DecimalMark.comma), Decimal.parse('1234.56'));
      expect(_amount('420', DecimalMark.comma), Decimal.parse('420'));
    });

    test('reads English amounts by the dot', () {
      expect(_amount('2,340.50', DecimalMark.dot), Decimal.parse('2340.5'));
      expect(_amount('-12.3 USD', DecimalMark.dot), Decimal.parse('-12.3'));
      expect(_amount('1,234', DecimalMark.dot), Decimal.parse('1234'));
    });

    test('takes the other separator only between groups of three', () {
      expect(
        () => _amount('−2 340,50', DecimalMark.dot),
        _fault(CellFault.unreadableAmount),
      );
      expect(
        () => _amount('2340.50', DecimalMark.comma),
        _fault(CellFault.unreadableAmount),
      );
      expect(_amount('1,234', DecimalMark.comma), Decimal.parse('1.234'));
    });

    test('reads every kind of space, minus and negative', () {
      final space = String.fromCharCode(0xa0);
      final narrow = String.fromCharCode(0x202f);
      expect(
        _amount('1${space}234${narrow}567,00', DecimalMark.comma),
        Decimal.parse('1234567'),
      );
      expect(
        _amount('(1 234,56)', DecimalMark.comma),
        Decimal.parse('-1234.56'),
      );
      expect(_amount('120,00-', DecimalMark.comma), Decimal.parse('-120'));
      expect(_amount('–7,5', DecimalMark.comma), Decimal.parse('-7.5'));
    });

    test('is null on a blank cell and fails on words', () {
      expect(_amount('  ', DecimalMark.comma), isNull);
      expect(
        () => _amount('Перевод', DecimalMark.comma),
        _fault(CellFault.unreadableAmount),
      );
      expect(
        () => _amount('1,2,3', DecimalMark.comma),
        _fault(CellFault.unreadableAmount),
      );
    });

    test('takes a number of a workbook as it is, whatever the mark', () {
      expect(
        readAmount(const Cell.number('-2340.5'), DecimalMark.comma),
        Decimal.parse('-2340.5'),
      );
      expect(
        readAmount(const Cell.number('1.5E-2'), DecimalMark.comma),
        Decimal.parse('0.015'),
      );
    });
  });

  group('readDate', () {
    test('reads a day and a time', () {
      expect(
        readDate(const Cell.text('03.10.2026 14:22'), DateOrder.dayMonthYear),
        CellDate(
          CivilDate(2026, 10, 3),
          const Duration(hours: 14, minutes: 22),
        ),
      );
      expect(
        readDate(
          const Cell.text('2026-10-03 09:12:05'),
          DateOrder.monthDayYear,
        ),
        CellDate(
          CivilDate(2026, 10, 3),
          const Duration(hours: 9, minutes: 12, seconds: 5),
        ),
      );
      expect(
        readDate(
          const Cell.date('2026-10-03T14:22:00'),
          DateOrder.dayMonthYear,
        ),
        CellDate(
          CivilDate(2026, 10, 3),
          const Duration(hours: 14, minutes: 22),
        ),
      );
    });

    test('follows the order unless the year comes first', () {
      expect(
        readDate(const Cell.text('10/03/2026'), DateOrder.monthDayYear).day,
        CivilDate(2026, 10, 3),
      );
      expect(
        readDate(const Cell.text('10/03/2026'), DateOrder.dayMonthYear).day,
        CivilDate(2026, 3, 10),
      );
      expect(
        readDate(const Cell.text('03-10-26'), DateOrder.dayMonthYear).day,
        CivilDate(2026, 10, 3),
      );
    });

    test('tells a day that does not exist from no date', () {
      expect(
        () => readDate(const Cell.text('31.09.2026'), DateOrder.dayMonthYear),
        _fault(CellFault.noSuchDay),
      );
      expect(
        () => readDate(const Cell.text('вчера'), DateOrder.dayMonthYear),
        _fault(CellFault.unreadableDate),
      );
      expect(
        () => readDate(
          const Cell.text('03.10.2026 25:10'),
          DateOrder.dayMonthYear,
        ),
        _fault(CellFault.unreadableDate),
      );
    });

    test('knows what can be a date', () {
      expect(looksLikeDate(const Cell.text('31.09.2026')), isTrue);
      expect(looksLikeDate(const Cell.text('Итого')), isFalse);
      expect(looksLikeDate(const Cell.text('Итого за 01.10.2026')), isFalse);
      expect(looksLikeDate(const Cell.date('2026-10-03')), isTrue);
    });
  });

  test('guesses the decimal mark from the amounts that tell', () {
    List<Cell> cells(List<String> texts) => [
      for (final text in texts) Cell.text(text),
    ];
    expect(
      guessDecimalMark(cells(['−2 340,50', '420,00', '1 234'])),
      DecimalMark.comma,
    );
    expect(guessDecimalMark(cells(['2,340.50', '1.5'])), DecimalMark.dot);
    expect(guessDecimalMark(cells(['1 234', '1,234'])), isNull);
    expect(guessDecimalMark([const Cell.number('-2340.5')]), isNull);
  });

  test('guesses the order of a date from a part that is not a month', () {
    List<Cell> cells(List<String> texts) => [
      for (final text in texts) Cell.text(text),
    ];
    expect(
      guessDateOrder(cells(['03/10/2026', '31/10/2026'])),
      DateOrder.dayMonthYear,
    );
    expect(guessDateOrder(cells(['10/31/2026'])), DateOrder.monthDayYear);
    expect(guessDateOrder(cells(['03.10.2026', '2026-10-31'])), isNull);
  });

  test('guesses a plus for money received when nothing has a minus', () {
    List<Cell> cells(List<String> texts) => [
      for (final text in texts) Cell.text(text),
    ];
    expect(
      guessAmountSign(cells(['99,00', '+100,00', '25 000,00'])),
      AmountSign.incomePlus,
    );
    expect(guessAmountSign(cells(['-99,00', '+100,00'])), isNull);
    expect(guessAmountSign(cells(['99,00', '100,00'])), isNull);
    expect(guessAmountSign(cells(['+99,00'])), isNull);
  });

  test('turns the names of currencies into codes', () {
    expect(currencyCode('RUR'), 'RUB');
    expect(currencyCode(' ₽ '), 'RUB');
    expect(currencyCode('usd'), 'USD');
    expect(currencyCode('USDT'), 'USDT');
    expect(currencyCode(r'$'), 'USD');
    expect(currencyCode(''), isNull);
    expect(currencyCode('рубли'), isNull);
    expect(currencyCode(null), isNull);
  });
}
