import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

void main() {
  final today = CivilDate(2026, 10, 31);

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
