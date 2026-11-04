import 'package:decimal/decimal.dart';
import 'package:import_common/import_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

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
  });
}
