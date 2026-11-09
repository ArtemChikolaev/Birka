import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:test/test.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// An operation of [rubles] on the card on [day], named [note].
Transaction op(
  String id,
  CivilDate day,
  String note,
  int rubles, {
  TransactionKind kind = TransactionKind.expense,
  String account = 'card',
  TransactionSource source = TransactionSource.import,
}) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: source,
  entries: [
    Entry(
      accountId: account,
      amount: kind == TransactionKind.expense ? -rub(rubles) : rub(rubles),
    ),
  ],
  allocations: [Allocation(categoryId: 'subs', amount: rub(rubles))],
);

void main() {
  // Wednesday, 18 November 2026, as on the boards.
  final today = CivilDate(2026, 11, 18);
  List<Transaction> plus({List<int> months = const [8, 9, 10, 11]}) => [
    for (final month in months)
      op('plus-$month', CivilDate(2026, month, 12), 'YANDEX*PLUS', 449),
  ];
  final bills = [
    op('zhku-9', CivilDate(2026, 9, 10), 'ЖКУ Москва', 6410),
    op('zhku-10', CivilDate(2026, 10, 9), 'ЖКУ МОСКВА 0427', 6845),
    op('zhku-11', CivilDate(2026, 11, 10), 'ЖКУ Москва', 7120),
  ];

  List<RepeatFind> find(
    List<Transaction> history, {
    List<Schedule> schedules = const [],
    Set<String> dismissed = const {},
  }) => findRepeats(
    history,
    today: today,
    schedules: schedules,
    dismissed: dismissed,
  );

  test('finds a subscription that came every month on its day', () {
    final [found] = find(plus());

    expect(found.times.map((it) => it.id), [
      'plus-8',
      'plus-9',
      'plus-10',
      'plus-11',
    ]);
    expect(found.latest.id, 'plus-11');
    expect(found.name, 'YANDEX*PLUS');
    expect(found.kind, TransactionKind.expense);
    expect(found.accountId, 'card');
    expect(found.day, 12);
    expect(found.varies, isFalse);
    expect(found.amount, rub(449));
    expect(found.key, findKey(TransactionKind.expense, 'card', 'yandex plus'));
  });

  test('finds a bill whose amount changes, at about what it costs', () {
    final [found] = find(bills);

    expect(found.varies, isTrue);
    expect(found.day, 10);
    expect(found.amount, rub(6800));
    expect(found.range, (min: rub(6410), max: rub(7120)));
    // The notes differ in digits and case and still make one name.
    expect(found.name, 'ЖКУ Москва');
  });

  test('wants three months in a row, the last of them recent', () {
    expect(find(plus(months: [10, 11])), isEmpty);
    // A month went without it: only October and November are in a row.
    expect(find(plus(months: [8, 10, 11])), isEmpty);
    expect(find(plus(months: [6, 7, 8, 9])), isEmpty);
  });

  test('leaves out shops, scattered days and amounts and income alike', () {
    final shop = [
      for (final month in [8, 9, 10, 11]) ...[
        op('shop-$month-a', CivilDate(2026, month, 3), 'ПЯТЕРОЧКА 1234', 640),
        op('shop-$month-b', CivilDate(2026, month, 17), 'Пятёрочка 77', 910),
      ],
    ];
    final scattered = [
      op('taxi-9', CivilDate(2026, 9, 5), 'Такси', 450),
      op('taxi-10', CivilDate(2026, 10, 15), 'Такси', 450),
      op('taxi-11', CivilDate(2026, 11, 25), 'Такси', 450),
    ];
    final swinging = [
      op('gift-9', CivilDate(2026, 9, 1), 'Подарки', 100),
      op('gift-10', CivilDate(2026, 10, 1), 'Подарки', 500),
      op('gift-11', CivilDate(2026, 11, 1), 'Подарки', 300),
    ];

    expect(find(shop), isEmpty);
    expect(find(scattered), isEmpty);
    expect(find(swinging), isEmpty);
  });

  test('keeps out what a regular payment already stands for', () {
    Schedule payment({
      String name = 'Плюс',
      String? madeFrom,
      ScheduleLast? last,
    }) => Schedule(
      id: 'p',
      kind: TransactionKind.expense,
      name: name,
      accountId: 'card',
      amount: rub(449),
      every: ScheduleEvery.month,
      day: 12,
      next: CivilDate(2026, 12, 12),
      onDay: ScheduleOnDay.post,
      reminder: ScheduleReminder.none,
      madeFrom: madeFrom,
      last: last,
    );

    expect(find(plus(), schedules: [payment(name: 'Yandex Plus')]), isEmpty);
    expect(find(plus(), schedules: [payment(madeFrom: 'plus-9')]), isEmpty);
    expect(
      find(
        plus(),
        schedules: [
          payment(
            last: ScheduleLast(
              done: ScheduleDone.found,
              from: CivilDate(2026, 11, 12),
              on: CivilDate(2026, 11, 12),
              at: DateTime.utc(2026, 11, 12),
              transactionId: 'plus-11',
            ),
          ),
        ],
      ),
      isEmpty,
    );
    // Another name on the account is another payment.
    expect(find(plus(), schedules: [payment()]), hasLength(1));
    // What a payment posted is its own already.
    final posted = [
      for (final it in plus())
        op(
          it.id,
          it.occurredOn,
          it.note,
          449,
          source: TransactionSource.recurring,
        ),
    ];
    expect(find(posted), isEmpty);
  });

  test('stays away once dismissed, and comes most months first', () {
    final both = [...bills, ...plus()];

    expect(find(both).map((it) => it.name), ['YANDEX*PLUS', 'ЖКУ Москва']);
    expect(
      find(both, dismissed: {find(both).first.key}).map((it) => it.name),
      ['ЖКУ Москва'],
    );
  });
}
