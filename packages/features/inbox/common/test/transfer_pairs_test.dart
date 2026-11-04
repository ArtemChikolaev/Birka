import 'package:decimal/decimal.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

const Currency _usd = Currency.usd;

Transaction _operation(
  String id,
  TransactionKind kind,
  String account,
  Money amount,
  CivilDate day, {
  String? category,
  String note = '',
}) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: TransactionSource.import,
  entries: [
    Entry(
      accountId: account,
      amount: kind == TransactionKind.expense ? -amount : amount,
    ),
  ],
  allocations: [Allocation(categoryId: category, amount: amount)],
);

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

/// The rate of the dollar on the boards: 81,20 ₽ on 30 September.
final _rates = RateBook([
  DayRates(CivilDate(2026, 9, 30), {'USD': Decimal.parse('81.20')}),
]);

void main() {
  test('pairs what left one account with what reached another', () {
    final out = _operation(
      'sber',
      TransactionKind.expense,
      'sber',
      _rub(5000),
      CivilDate(2026, 10, 19),
      note: 'Перевод СБП',
    );
    final into = _operation(
      'tbank',
      TransactionKind.income,
      'tbank',
      _rub(5000),
      CivilDate(2026, 10, 20),
    );

    final [pair] = transferPairs([out, into], rates: _rates);

    expect(pair.out.id, 'sber');
    expect(pair.into.id, 'tbank');
    expect(pair.sent, _rub(5000));
    expect(pair.fromAccountId, 'sber');
    expect(pair.toAccountId, 'tbank');
    expect(pair.key, 'sber>tbank');
  });

  test('between currencies keeps to the rate of the day', () {
    final out = _operation(
      'wise',
      TransactionKind.expense,
      'wise',
      Money(231000, _usd),
      CivilDate(2026, 9, 30),
    );
    // 185 000 ₽ for 2 310 $ is 80,09 ₽ per dollar against 81,20.
    final into = _operation(
      'card',
      TransactionKind.income,
      'card',
      _rub(185000),
      CivilDate(2026, 10, 1),
    );
    final far = _operation(
      'far',
      TransactionKind.income,
      'cash',
      _rub(150000),
      CivilDate(2026, 10, 1),
    );

    expect(transferPairs([out, into], rates: _rates), hasLength(1));
    expect(transferPairs([out, far], rates: _rates), isEmpty);
    expect(
      transferPairs([out, into], rates: const RateBook.empty()),
      isEmpty,
    );
  });

  test('between currencies keeps within a tenth of the rate', () {
    final out = _operation(
      'wise',
      TransactionKind.expense,
      'wise',
      Money(231000, _usd),
      CivilDate(2026, 9, 30),
    );
    // 2 310 $ at 81,20 ₽ are 187 572 ₽, and a tenth of it 18 757,20 ₽.
    List<TransferPair> pairs(int kopecks) => transferPairs([
      out,
      _operation(
        'card',
        TransactionKind.income,
        'card',
        Money(kopecks, Currency.rub),
        CivilDate(2026, 9, 30),
      ),
    ], rates: _rates);

    expect(pairs(16881500), hasLength(1));
    expect(pairs(16881400), isEmpty);
    expect(pairs(20632900), hasLength(1));
    expect(pairs(20633000), isEmpty);
  });

  test('never pairs other amounts, days apart, one account or a category', () {
    final out = _operation(
      'out',
      TransactionKind.expense,
      'sber',
      _rub(5000),
      CivilDate(2026, 10, 1),
    );
    List<TransferPair> pairs(Transaction into) =>
        transferPairs([out, into], rates: _rates);

    expect(
      pairs(
        _operation(
          'a',
          TransactionKind.income,
          'tbank',
          _rub(4999),
          CivilDate(2026, 10, 1),
        ),
      ),
      isEmpty,
    );
    expect(
      pairs(
        _operation(
          'b',
          TransactionKind.income,
          'tbank',
          _rub(5000),
          CivilDate(2026, 10, 5),
        ),
      ),
      isEmpty,
    );
    expect(
      pairs(
        _operation(
          'c',
          TransactionKind.income,
          'sber',
          _rub(5000),
          CivilDate(2026, 10, 1),
        ),
      ),
      isEmpty,
    );
    expect(
      pairs(
        _operation(
          'd',
          TransactionKind.income,
          'tbank',
          _rub(5000),
          CivilDate(2026, 10, 1),
          category: 'salary',
        ),
      ),
      isEmpty,
    );
  });

  test('takes the closest pair, each operation once', () {
    final early = _operation(
      'early',
      TransactionKind.expense,
      'sber',
      _rub(5000),
      CivilDate(2026, 10, 1),
    );
    final late = _operation(
      'late',
      TransactionKind.expense,
      'alfa',
      _rub(5000),
      CivilDate(2026, 10, 3),
    );
    final into = _operation(
      'into',
      TransactionKind.income,
      'tbank',
      _rub(5000),
      CivilDate(2026, 10, 3),
    );

    final [pair] = transferPairs([early, late, into], rates: _rates);

    expect(pair.out.id, 'late');
  });

  test('leaves out the pairs that the person kept apart', () {
    final out = _operation(
      'out',
      TransactionKind.expense,
      'sber',
      _rub(5000),
      CivilDate(2026, 10, 1),
    );
    final into = _operation(
      'into',
      TransactionKind.income,
      'tbank',
      _rub(5000),
      CivilDate(2026, 10, 1),
    );

    expect(
      transferPairs([out, into], rates: _rates, dismissed: {'out>into'}),
      isEmpty,
    );
  });
}
