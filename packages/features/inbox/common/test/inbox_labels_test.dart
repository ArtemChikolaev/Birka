import 'package:decimal/decimal.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

Transaction _operation(
  String id,
  TransactionKind kind,
  String account,
  Money amount,
  CivilDate day,
) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: '',
  status: TransactionStatus.cleared,
  source: TransactionSource.import,
  entries: [
    Entry(
      accountId: account,
      amount: kind == TransactionKind.expense ? -amount : amount,
    ),
  ],
  allocations: [Allocation(categoryId: null, amount: amount)],
);

LedgerImport _import({String? format = 'alfa'}) => LedgerImport(
  id: 'october',
  fileName: 'alfa-2026-10.xlsx',
  firstDay: CivilDate(2026, 10, 1),
  lastDay: CivilDate(2026, 10, 31),
  importedAt: DateTime(2026, 11, 2),
  transactions: 212,
  accountIds: const {'card'},
  format: format,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('a hint says why', () {
    test('of a name given several times in one month or since one', () {
      expect(
        hintLabel(
          CategoryHint(
            categoryId: 'cafe',
            reason: HintReason.sameName,
            count: 3,
            first: CivilDate(2026, 9, 3),
            last: CivilDate(2026, 9, 25),
          ),
          thisYear: 2026,
        ),
        'так вы отметили его 3 раза в сентябре',
      );
      expect(
        hintLabel(
          CategoryHint(
            categoryId: 'cafe',
            reason: HintReason.sameName,
            count: 5,
            first: CivilDate(2025, 6, 3),
            last: CivilDate(2026, 9, 25),
          ),
          thisYear: 2026,
        ),
        'так вы отметили его 5 раз с июня 2025',
      );
    });

    test('of an amount month after month', () {
      expect(
        hintLabel(
          CategoryHint(
            categoryId: 'music',
            reason: HintReason.everyMonth,
            count: 3,
            first: CivilDate(2026, 6, 16),
            last: CivilDate(2026, 9, 16),
          ),
          thisYear: 2026,
        ),
        'та же сумма каждый месяц с июня',
      );
    });

    test('of a similar name, in this statement or in a month', () {
      expect(
        hintLabel(
          CategoryHint(
            categoryId: 'shop',
            reason: HintReason.sameImport,
            first: CivilDate(2026, 10, 12),
            last: CivilDate(2026, 10, 12),
            like: 'Маркетплейс',
          ),
          thisYear: 2026,
        ),
        'как «Маркетплейс» в этой выписке',
      );
      expect(
        hintLabel(
          CategoryHint(
            categoryId: 'beauty',
            reason: HintReason.similarName,
            first: CivilDate(2026, 8, 14),
            last: CivilDate(2026, 8, 14),
            like: 'Барбершоп',
          ),
          thisYear: 2026,
        ),
        'как «Барбершоп» в августе',
      );
    });
  });

  test('the line under the title counts what waits after which import', () {
    expect(waitingLabel(const InboxState()), '0 ждут решения');
    expect(
      waitingLabel(InboxState(latestImport: _import())),
      '0 ждут решения · после импорта Альфа-Банка',
    );
    expect(
      waitingLabel(InboxState(latestImport: _import(format: null))),
      '0 ждут решения · после импорта «alfa-2026-10.xlsx»',
    );
  });

  group('the way to the inbox on the overview says what waits', () {
    final pair = TransferPair(
      out: _operation(
        'top-up',
        TransactionKind.expense,
        'wise',
        Money(231000, Currency.usd),
        CivilDate(2026, 9, 30),
      ),
      into: _operation(
        'arrived',
        TransactionKind.income,
        'card',
        Money(18500000, Currency.rub),
        CivilDate(2026, 10, 1),
      ),
    );
    final items = [
      for (final id in ['cafe', 'shop'])
        InboxItem(
          _operation(
            id,
            TransactionKind.expense,
            'card',
            Money(45000, Currency.rub),
            CivilDate(2026, 10, 4),
          ),
        ),
    ];
    final wise = Account(
      id: 'wise',
      name: 'Wise',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.usd),
      includeInTotals: true,
      archived: false,
      sortOrder: 1,
    );

    test('the operations and the transfer with its account', () {
      expect(
        entryLine(
          InboxState(
            items: items,
            pairs: [pair],
            accounts: [wise],
            latestImport: _import(),
          ),
        ),
        '2 без категории и перевод со счёта «Wise» · после импорта '
        'Альфа-Банка',
      );
      expect(
        t.inbox.entryTitle(n: 3, count: formatCount(3)),
        '3 ждут решения во «Входящих»',
      );
      expect(
        t.inbox.entryTitle(n: 1, count: formatCount(1)),
        '1 ждёт решения во «Входящих»',
      );
    });

    test('the operations alone, before any import', () {
      expect(entryLine(InboxState(items: items)), '2 без категории');
    });

    test('several transfers, or one whose account is gone, by their count', () {
      expect(
        entryLine(InboxState(pairs: [pair, pair, pair])),
        '3 перевода между счетами',
      );
      expect(entryLine(InboxState(pairs: [pair])), '1 перевод между счетами');
    });
  });

  test('a pair of two currencies says its rate and that of the bank', () {
    final pair = TransferPair(
      out: _operation(
        'wise',
        TransactionKind.expense,
        'wise',
        Money(231000, Currency.usd),
        CivilDate(2026, 9, 30),
      ),
      into: _operation(
        'card',
        TransactionKind.income,
        'card',
        Money(18500000, Currency.rub),
        CivilDate(2026, 10, 1),
      ),
    );
    final rates = RateBook([
      DayRates(CivilDate(2026, 9, 30), {'USD': Decimal.parse('81.20')}),
    ]);

    expect(
      rateLabel(pair, rates),
      'Курс обмена ${formatMoney(Money(8009, Currency.rub))} за '
      '${formatMoney(Money(100, Currency.usd))} · ЦБ в тот день '
      '${formatMoney(Money(8120, Currency.rub))}',
    );
    expect(rateLabel(pair, const RateBook.empty()), isNot(contains('ЦБ')));
  });

  test('the import that the inbox follows is that of its bank or file', () {
    expect(afterLabel(const InboxState()), isNull);
    expect(
      afterLabel(InboxState(latestImport: _import())),
      'после импорта Альфа-Банка',
    );
    expect(
      afterLabel(InboxState(latestImport: _import(format: null))),
      'после импорта «alfa-2026-10.xlsx»',
    );
  });

  test('an operation says its money, its day and its account', () {
    final coffee = _operation(
      'coffee',
      TransactionKind.expense,
      'card',
      Money(145000, Currency.rub),
      CivilDate(2026, 10, 4),
    );
    final salary = _operation(
      'salary',
      TransactionKind.income,
      'card',
      Money(9650000, Currency.rub),
      CivilDate(2025, 12, 30),
    );
    final state = InboxState(
      accounts: [
        Account(
          id: 'card',
          name: 'Зарплатная карта',
          type: AccountType.debit,
          openingBalance: Money(0, Currency.rub),
          includeInTotals: true,
          archived: false,
          sortOrder: 0,
        ),
      ],
    );

    expect(amountLabel(coffee), formatMoney(Money(-145000, Currency.rub)));
    expect(
      amountLabel(salary),
      '+${formatMoney(Money(9650000, Currency.rub))}',
    );
    expect(placeLabel(coffee, state, 2026), '4 октября · Зарплатная карта');
    expect(placeLabel(salary, state, 2026), startsWith('30 декабря 2025'));
    expect(kindOf(coffee), CategoryKind.expense);
    expect(kindOf(salary), CategoryKind.income);
  });
}
