@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:test/test.dart';

import 'fakes.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late LedgerSchedulesRepository repository;
  late Account card;
  late Category home;
  late Category fun;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    repository = LedgerSchedulesRepository(
      ledger,
      BaseCurrency(null),
      MonthStart(1),
      MemorySettingsStore(),
      now: () => DateTime(2026, 11, 18, 12),
    );
    card = await ledger.addAccount(
      name: 'Карта',
      type: AccountType.debit,
      openingBalance: rub(100000),
    );
    home = await ledger.addCategory(kind: CategoryKind.expense, name: 'Дом');
    fun = await ledger.addCategory(kind: CategoryKind.expense, name: 'Кино');
  });

  tearDown(() => database.close());

  Future<String> expense({
    String note = 'Яндекс Плюс',
    TransactionSource source = TransactionSource.import,
    List<Allocation>? allocations,
  }) => ledger.record(
    TransactionDraft.expense(
      accountId: card.id,
      allocations:
          allocations ?? [Allocation(categoryId: home.id, amount: rub(449))],
      occurredOn: CivilDate(2026, 11, 12),
      note: note,
      source: source,
    ),
  );

  /// The state of the card of operation [id] once both the operation and the
  /// payments have come.
  Future<OperationScheduleState> card0(String id, {int skip = 0}) async {
    final cubit = OperationScheduleCubit(repository, id);
    addTearDown(cubit.close);
    return cubit.stream.skip(skip).first;
  }

  test('an operation can become a payment on its day', () async {
    final made = await expense();

    final state = await card0(made);

    expect(state.offers, isTrue);
    expect(state.day, 12);
  });

  test('the payment made from it is its payment', () async {
    final made = await expense();
    final plus = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'Яндекс Плюс',
      accountId: card.id,
      categoryId: home.id,
      amount: rub(449),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 12, 12),
      madeFrom: made,
    );

    final state = await card0(made);

    expect(state.offers, isFalse);
    expect(state.schedule?.id, plus.id);
  });

  test('one that a payment posted leads to it by its name', () async {
    final rent = await ledger.addSchedule(
      kind: TransactionKind.expense,
      name: 'Аренда',
      accountId: card.id,
      categoryId: home.id,
      amount: rub(45000),
      every: ScheduleEvery.month,
      next: CivilDate(2026, 10, 25),
    );
    final posted = await ledger.postSchedule(rent.id);
    // A later post leaves the older one without the last time of its payment.
    await ledger.postSchedule(rent.id);
    final renamed = await expense(
      note: 'Квартплата',
      source: TransactionSource.recurring,
    );

    expect((await card0(posted)).schedule?.id, rent.id);
    // A post whose payment is not to be found offers no second one.
    final state = await card0(renamed);
    expect(state.schedule, isNull);
    expect(state.offers, isFalse);
  });

  test('a split, a correction and what is gone offer nothing', () async {
    final split = await expense(
      allocations: [
        Allocation(categoryId: home.id, amount: rub(300)),
        Allocation(categoryId: fun.id, amount: rub(149)),
      ],
    );
    final correction = await ledger.record(
      TransactionDraft.adjustment(
        accountId: card.id,
        change: rub(10),
        occurredOn: CivilDate(2026, 11, 12),
      ),
    );

    expect((await card0(split)).offers, isFalse);
    expect((await card0(correction)).offers, isFalse);
    expect((await card0('none')).offers, isFalse);
  });

  test('scheduleOf and canRepeat read the operation', () {
    final made = Transaction(
      id: 'op',
      kind: TransactionKind.transfer,
      occurredOn: CivilDate(2026, 11, 12),
      note: '',
      status: TransactionStatus.cleared,
      source: TransactionSource.manual,
      entries: [
        Entry(accountId: card.id, amount: -rub(1000)),
        Entry(accountId: 'savings', amount: rub(1000)),
      ],
      allocations: const [],
    );

    expect(canRepeat(made), isTrue);
    expect(scheduleOf(made, const []), isNull);
  });
}
