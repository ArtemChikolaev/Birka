@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);
Money eur(int euros) => Money(euros * 100, Currency.eur);

void main() {
  final today = CivilDate(2026, 11, 17);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late RatesRepository rates;
  late LimitNotices notices;
  late Account card;
  var monthStart = 1;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    rates = RatesRepository(database);
    monthStart = 1;
    notices = LimitNotices(
      ledger,
      rates,
      monthStart: () => monthStart,
      now: () => DateTime(2026, 11, 17, 21, 40),
    );
    card = await ledger.addAccount(
      name: 'Карта',
      type: AccountType.debit,
      openingBalance: rub(100000),
    );
  });

  tearDown(() => database.close());

  Future<Category> limited(
    String name,
    Money limit, {
    bool early = true,
  }) async {
    final category = await ledger.addCategory(
      name: name,
      kind: CategoryKind.expense,
    );
    await ledger.setCategoryLimit(
      category.id,
      CategoryLimit(limit, warnEarly: early),
    );
    return category;
  }

  Future<String> spend(
    Category category,
    Money amount, {
    Account? from,
    CivilDate? on,
    String? importId,
    TransactionSource source = TransactionSource.manual,
  }) => ledger.record(
    TransactionDraft.expense(
      accountId: (from ?? card).id,
      allocations: [Allocation(categoryId: category.id, amount: amount)],
      occurredOn: on ?? today,
      source: source,
    ),
    importId: importId,
  );

  /// A statement of [operations] that goes in as an import would.
  Future<String> statement(
    List<(Category, Money)> operations, {
    CivilDate? on,
    Account? from,
  }) async {
    final id = await ledger.addImport(
      fileName: 'tbank.pdf',
      firstDay: CivilDate(2026, 10, 1),
      lastDay: today,
    );
    for (final (category, amount) in operations) {
      await spend(
        category,
        amount,
        from: from,
        on: on,
        importId: id,
        source: TransactionSource.import,
      );
    }
    return id;
  }

  Future<List<LimitNotice>> told() async =>
      (await ledger.watchNotices().first).whereType<LimitNotice>().toList();

  test('a statement that takes a limit over says how far', () async {
    final leisure = await limited('Досуг', rub(8000));
    await spend(leisure, rub(7000));
    final id = await statement([(leisure, rub(2300))]);
    await notices.afterImport(id);
    final notice = (await told()).single;
    expect(notice.categoryId, leisure.id);
    expect(notice.name, 'Досуг');
    expect(notice.month, CivilDate(2026, 11, 1));
    expect(notice.share, LimitNotice.overShare);
    expect(notice.amount, rub(1300));
    expect(notice.importId, id);
  });

  test('a statement that takes a limit past 80 % says what is left', () async {
    final cafe = await limited('Кафе', rub(12000));
    await spend(cafe, rub(8000));
    await notices.afterImport(await statement([(cafe, rub(1600))]));
    final notice = (await told()).single;
    expect(notice.share, LimitNotice.nearShare);
    expect(notice.amount, rub(2400));
  });

  test('a limit the person took past 80 % themselves tells nothing', () async {
    final cafe = await limited('Кафе', rub(12000));
    await spend(cafe, rub(10000));
    await notices.afterImport(await statement([(cafe, rub(500))]));
    expect(await told(), isEmpty);
  });

  test('a statement past both says only that it went over', () async {
    final cafe = await limited('Кафе', rub(12000));
    await spend(cafe, rub(6000));
    await notices.afterImport(await statement([(cafe, rub(7200))]));
    final notice = (await told()).single;
    expect(notice.share, LimitNotice.overShare);
    expect(notice.amount, rub(1200));
  });

  test('a limit that does not say so early tells only of going over', () async {
    final transport = await limited('Транспорт', rub(5000), early: false);
    await spend(transport, rub(3000));
    await notices.afterImport(await statement([(transport, rub(1200))]));
    expect(await told(), isEmpty);
    await notices.afterImport(await statement([(transport, rub(1000))]));
    expect((await told()).single.share, LimitNotice.overShare);
  });

  test('a limit gone over tells it once', () async {
    final leisure = await limited('Досуг', rub(8000));
    await notices.afterImport(await statement([(leisure, rub(9000))]));
    await notices.afterImport(await statement([(leisure, rub(500))]));
    expect(await told(), hasLength(1));
  });

  test('regular payments that posted themselves tell it too', () async {
    final home = await limited('Дом', rub(10000));
    await spend(home, rub(5000));
    final rent = await spend(
      home,
      rub(5500),
      source: TransactionSource.recurring,
    );
    await notices.afterPayments([rent]);
    final notice = (await told()).single;
    expect(notice.share, LimitNotice.overShare);
    expect(notice.amount, rub(500));
    expect(notice.importId, isNull);
  });

  test('a statement of an earlier month tells nothing', () async {
    final leisure = await limited('Досуг', rub(8000));
    final id = await statement([
      (leisure, rub(9000)),
    ], on: CivilDate(2026, 10, 20));
    await notices.afterImport(id);
    expect(await told(), isEmpty);
  });

  test('the month starts on the day of the settings', () async {
    monthStart = 10;
    final leisure = await limited('Досуг', rub(8000));
    // Spent on the 5th, in the month before the one that starts on the 10th.
    await spend(leisure, rub(7000), on: CivilDate(2026, 11, 5));
    await notices.afterImport(await statement([(leisure, rub(2300))]));
    expect(await told(), isEmpty);
    await spend(leisure, rub(5000), on: CivilDate(2026, 11, 12));
    await notices.afterImport(await statement([(leisure, rub(1000))]));
    final notice = (await told()).single;
    expect(notice.month, CivilDate(2026, 11, 10));
    expect(notice.amount, rub(300));
  });

  test('a limit in euros counts rubles at the rate of their day', () async {
    await rates.keep(DayRates(today, {'EUR': Decimal.parse('91.5')}));
    final euros = await ledger.addAccount(
      name: 'Евро',
      type: AccountType.debit,
      openingBalance: eur(1000),
    );
    final trips = await limited('Поездки', eur(400));
    await spend(trips, eur(214), from: euros);
    await notices.afterImport(await statement([(trips, rub(15000))]));
    final notice = (await told()).single;
    expect(notice.share, LimitNotice.nearShare);
    // 214 € and 15 000 ₽ at 91,50 come to 378 €.
    expect(notice.amount, eur(22));
  });

  test('categories without limits tell nothing', () async {
    final food = await ledger.addCategory(
      name: 'Продукты',
      kind: CategoryKind.expense,
    );
    await notices.afterImport(await statement([(food, rub(50000))]));
    await notices.afterPayments(const []);
    expect(await told(), isEmpty);
  });
}
