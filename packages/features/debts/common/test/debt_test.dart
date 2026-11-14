import 'package:debts_common/debts_common.dart';
import 'package:debts_common/testing.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:test/test.dart';

void main() {
  CivilDate nov(int day) => CivilDate(2026, 11, day);
  final accounts = {
    for (final account in [...boardAccounts(), ...boardDebts()])
      account.id: account,
  };
  Debt debtOf(String id, [List<Transaction>? transfers]) => Debt.of(
    accounts[id]!,
    transfers ?? boardTransfers(),
    accounts: accounts,
  );

  test('a debt with part of it back says what is left of what', () {
    final masha = debtOf('masha');

    expect(masha.left, rub(3000));
    expect(masha.total, rub(5000));
    expect(masha.settled, rub(2000));
    expect(masha.share, closeTo(0.4, 1e-9));
    expect(masha.since, nov(3));
    expect(masha.closed, isFalse);
    expect(masha.closedOn, isNull);
    expect(masha.steps.map((step) => step.move), [
      DebtMove.returned,
      DebtMove.lent,
    ]);
    final back = masha.steps.first;
    expect(back.amount, rub(2000));
    expect(back.onAccount, rub(2000));
    expect(back.account?.name, 'Зарплатная карта');
    final lent = masha.steps.last;
    expect(lent.onAccount, -rub(5000));
    expect(lent.note, 'на билеты');
  });

  test('a debt that came back in full is settled on its last day', () {
    final ira = debtOf('ira');

    expect(ira.closed, isTrue);
    expect(ira.left.isZero, isTrue);
    expect(ira.closedOn, nov(2));
    expect(ira.share, 1);
  });

  test('money lent again after a debt was settled starts a new round', () {
    final transfers = [
      ...boardTransfers(),
      transfer('ira-again', 'cash', 'ira', rub(700), nov(12)),
    ];
    final ira = debtOf('ira', transfers);

    expect(ira.closed, isFalse);
    expect(ira.left, rub(700));
    expect(ira.total, rub(700));
    expect(ira.settled.isZero, isTrue);
    expect(ira.since, nov(12));
    expect(ira.steps, hasLength(3));
  });

  test('a return dated before the money it returns counts in its round', () {
    final masha = debtOf('masha', [
      transfer('early', 'masha', 'card', rub(2000), nov(5)),
      transfer('lent', 'cash', 'masha', rub(5000), nov(10)),
    ]);

    expect(masha.left, rub(3000));
    expect(masha.total, rub(5000));
    expect(masha.settled, rub(2000));
    expect(masha.share, closeTo(0.4, 1e-9));
    expect(masha.since, nov(10));
    expect(masha.closed, isFalse);
  });

  test('money that came back beyond a debt counts in the next round', () {
    final masha = debtOf('masha', [
      transfer('lent', 'cash', 'masha', rub(1000), nov(3)),
      transfer('back', 'masha', 'card', rub(1500), nov(5)),
      transfer('again', 'cash', 'masha', rub(2000), nov(10)),
    ]);

    expect(masha.left, rub(1500));
    expect(masha.total, rub(2000));
    expect(masha.settled, rub(500));
    expect(masha.since, nov(10));
  });

  test('a debt of the person reads the other way round', () {
    final sasha = debtOf('sasha');

    expect(sasha.side, DebtSide.borrowed);
    expect(sasha.left, rub(4000));
    expect(sasha.steps.single.move, DebtMove.borrowed);
    expect(sasha.steps.single.onAccount, rub(4000));

    final repaid = debtOf('sasha', [
      ...boardTransfers(),
      transfer('sasha-repaid', 'card', 'sasha', rub(1000), nov(14)),
    ]);
    expect(repaid.left, rub(3000));
    expect(repaid.settled, rub(1000));
    expect(repaid.steps.first.move, DebtMove.repaid);
    expect(repaid.steps.first.onAccount, -rub(1000));
  });

  test('a planned transfer moves nothing yet', () {
    final planned = Transaction(
      id: 'planned',
      kind: TransactionKind.transfer,
      occurredOn: nov(20),
      note: '',
      status: TransactionStatus.planned,
      source: TransactionSource.recurring,
      entries: [
        Entry(accountId: 'masha', amount: -rub(3000)),
        Entry(accountId: 'card', amount: rub(3000)),
      ],
      allocations: const [],
    );
    final masha = debtOf('masha', [...boardTransfers(), planned]);

    expect(masha.left, rub(3000));
    expect(masha.steps, hasLength(2));
  });

  test('a debt without steps is no longer there', () {
    final debts = debtsOf(
      [...boardDebts(), debtAccount('lena', 'Лена', DebtSide.lent)],
      boardTransfers(),
      accounts: accounts,
    );

    expect(debts.map((debt) => debt.name), [
      'Дима',
      'Маша',
      'Саша',
      'Ира',
      'Папа',
    ]);
  });

  test('a debt is due on its day and after it while something is owed', () {
    expect(debtOf('dima').isDue(boardToday), isTrue);
    expect(debtOf('masha').isDue(boardToday), isFalse);
    expect(debtOf('masha').isDue(CivilDate(2026, 12, 2)), isTrue);
    expect(debtOf('ira').isDue(boardToday), isFalse);
  });

  test('a reminder says what is left and the day', () {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    final debts = debtsOf(
      boardDebts(),
      boardTransfers(),
      accounts: {
        for (final it in [...boardAccounts(), ...boardDebts()]) it.id: it,
      },
    );
    final masha = debts.firstWhere((debt) => debt.id == 'masha');
    final ira = debts.firstWhere((debt) => debt.id == 'ira');
    expect(
      debtRemindText(masha, today: boardToday),
      'Привет! Напоминаю про ${nb('3 000 ₽')} — договаривались вернуть до '
      '1 декабря.',
    );
    expect(
      debtRemindText(ira, today: boardToday),
      'Привет! Напоминаю про ${nb('0 ₽')}.',
    );
  });
}
