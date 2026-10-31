import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show TransactionSource;
import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  final today = CivilDate(2026, 10, 31);
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a day reads in the language of the user', () {
    expect(dayLabel(CivilDate(2026, 10, 3), today: today), 'October 3');

    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(dayLabel(CivilDate(2026, 3, 8), today: today), '8 марта');
  });

  test('a day of another year says so', () {
    expect(
      dayLabel(CivilDate(2025, 12, 31), today: today),
      'December 31 2025',
    );
  });

  test('a kind has a name', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(transactionKindLabel(TransactionKind.transfer), 'Перевод');
  });

  test('a filter has a name', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(filterLabel(OperationsFilter.all), 'Все');
    expect(filterLabel(OperationsFilter.expenses), 'Расходы');
    expect(filterLabel(OperationsFilter.income), 'Доходы');
    expect(filterLabel(OperationsFilter.transfers), 'Переводы');
  });

  test('a month reads as a name, with its year when it is another', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(monthLabel(CivilDate(2026, 10, 1), today: today), 'Октябрь');
    expect(monthLabel(CivilDate(2025, 3, 1), today: today), 'Март 2025');
  });

  test('a heading says today and yesterday', () {
    expect(dayHeading(today, today: today), 'Today');
    expect(dayHeading(CivilDate(2026, 10, 30), today: today), 'Yesterday');
    expect(dayHeading(CivilDate(2026, 10, 29), today: today), 'October 29');
  });

  test('yesterday crosses a month and a year', () {
    expect(
      dayHeading(CivilDate(2026, 12, 31), today: CivilDate(2027, 1, 1)),
      'Yesterday',
    );
  });

  test('a time has two digits on each side', () {
    expect(timeLabel(DateTime(2026, 10, 31, 8, 5)), '08:05');
    expect(timeLabel(DateTime(2026, 10, 31, 23, 42)), '23:42');
  });

  test('a time follows the clock of the device', () {
    final moment = DateTime(2026, 10, 31, 8, 5);
    expect(timeLabel(moment.toUtc()), '08:05');
  });

  test('every source has a name', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    expect(sourceLabel(TransactionSource.manual), 'Вручную');
    expect(sourceLabel(TransactionSource.import), 'Из выписки');
    expect(sourceLabel(TransactionSource.notification), 'Из уведомления');
    expect(sourceLabel(TransactionSource.recurring), 'Регулярная');
    expect(sourceLabel(TransactionSource.bank), 'Из банка');
  });

  group('amounts in a line', () {
    test('carry their signs and stay apart', () {
      expect(
        amountsLabel([rub(-25000), Money(100, Currency.usd)]),
        [
          '−₽250',
          r'+$1',
        ].join(' · '),
      );
    });
  });

  group('an operation', () {
    final card = testAccount('Card');
    final cash = testAccount('Cash');
    final cafe = testCategory('Cafe');

    test('of money spent shows a minus', () {
      expect(operationAmount(testOperation('a', amount: rub(-100))), '−₽1');
    });

    test('of money earned shows a plus', () {
      expect(operationAmount(testOperation('a', amount: rub(100))), '+₽1');
    });

    test('of a transfer shows no sign', () {
      final transfer = testOperation(
        'a',
        amount: rub(-100),
        account: card,
        toAccount: cash,
        kind: TransactionKind.transfer,
      );
      expect(operationAmount(transfer), '₽1');
    });

    test('is called by its note, with its category below', () {
      final operation = testOperation(
        'a',
        amount: rub(-100),
        account: card,
        category: cafe,
        note: 'Lunch',
      );

      expect(operationTitle(operation), 'Lunch');
      expect(operationSubtitle(operation), 'Cafe · Card');
    });

    test('without a note is called by its category', () {
      final operation = testOperation(
        'a',
        amount: rub(-100),
        account: card,
        category: cafe,
      );

      expect(operationTitle(operation), 'Cafe');
      expect(operationSubtitle(operation), 'Card');
    });

    test('of a transfer shows where the money went', () {
      final transfer = testOperation(
        'a',
        amount: rub(-100),
        account: card,
        toAccount: cash,
        kind: TransactionKind.transfer,
      );

      expect(operationTitle(transfer), 'Transfer');
      expect(operationSubtitle(transfer), 'Card → Cash');
    });

    test('of a transfer with a note keeps its kind below', () {
      final transfer = testOperation(
        'a',
        amount: rub(-100),
        account: card,
        toAccount: cash,
        kind: TransactionKind.transfer,
        note: 'Savings',
      );

      expect(operationTitle(transfer), 'Savings');
      expect(operationSubtitle(transfer), 'Transfer · Card → Cash');
    });

    test('without a category is called by its kind', () {
      final fix = testOperation(
        'a',
        amount: rub(100),
        account: card,
        kind: TransactionKind.adjustment,
      );

      expect(operationTitle(fix), 'Correction');
      expect(operationSubtitle(fix), 'Card');
    });
  });

  group('the amount', () {
    const typed = AmountExpression();
    final five = typed.digit(5, decimalDigits: 2);

    String label(TransactionKind kind, AmountExpression expression) =>
        amountLabel(kind, expression, Currency.usd);

    test('shows zero before anything is typed', () {
      expect(label(TransactionKind.expense, typed), r'$0');
    });

    test('carries the sign of its kind', () {
      expect(label(TransactionKind.expense, five), r'−$5');
      expect(label(TransactionKind.income, five), r'+$5');
      expect(label(TransactionKind.transfer, five), r'$5');
    });

    test('below zero it shows as it is, whatever the kind', () {
      final below = five
          .operator_(AmountOperator.subtract)
          .digit(9, decimalDigits: 2);
      expect(label(TransactionKind.expense, below), r'−$4');
      expect(label(TransactionKind.income, below), r'−$4');
    });

    test('a dash stands for what comes to nothing', () {
      final broken = five
          .operator_(AmountOperator.divide)
          .digit(0, decimalDigits: 2);
      expect(label(TransactionKind.expense, broken), '—');
    });
  });
}
