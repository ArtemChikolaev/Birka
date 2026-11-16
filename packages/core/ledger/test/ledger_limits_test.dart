@TestOn('vm')
library;

import 'dart:convert';

import 'package:database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Category cafe;

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(
      database,
      now: () => DateTime.utc(2026, 11, 18, 7),
    );
    cafe = await ledger.addCategory(
      name: 'Кафе',
      kind: CategoryKind.expense,
      icon: 'cup',
      color: '#fbbf24',
    );
  });

  tearDown(() => database.close());

  Future<Category> reread(String id) async => (await ledger.category(id))!;

  test('a category has no limit until one is set', () async {
    expect((await reread(cafe.id)).limit, isNull);
  });

  test('a limit keeps its amount, its currency and the early word', () async {
    await ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(1200000)));
    expect((await reread(cafe.id)).limit, CategoryLimit(rub(1200000)));

    final euros = CategoryLimit(Money(40000, Currency.eur), warnEarly: false);
    await ledger.setCategoryLimit(cafe.id, euros);
    expect((await reread(cafe.id)).limit, euros);
  });

  test('null takes the limit away', () async {
    await ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(1200000)));
    await ledger.setCategoryLimit(cafe.id, null);
    expect((await reread(cafe.id)).limit, isNull);
  });

  test('the categories that come from the ledger carry their limits', () async {
    await ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(1200000)));
    final listed = await ledger.watchCategories(CategoryKind.expense).first;
    expect(listed.single.limit, CategoryLimit(rub(1200000)));
  });

  test('income, a subcategory and zero take no limit', () async {
    final salary = await ledger.addCategory(
      name: 'Зарплата',
      kind: CategoryKind.income,
    );
    final coffee = await ledger.addCategory(
      name: 'Кофе',
      kind: CategoryKind.expense,
      parentId: cafe.id,
    );
    expect(
      () => ledger.setCategoryLimit(salary.id, CategoryLimit(rub(100))),
      throwsA(isA<LedgerException>()),
    );
    expect(
      () => ledger.setCategoryLimit(coffee.id, CategoryLimit(rub(100))),
      throwsA(isA<LedgerException>()),
    );
    expect(
      () => ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(0))),
      throwsA(isA<LedgerException>()),
    );
  });

  test('a category that becomes a subcategory leaves its limit', () async {
    final food = await ledger.addCategory(
      name: 'Еда',
      kind: CategoryKind.expense,
    );
    await ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(1200000)));
    await ledger.updateCategory(cafe.id, parentId: Value(food.id));
    expect((await reread(cafe.id)).limit, isNull);
  });

  test('a change of the name keeps the limit', () async {
    await ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(1200000)));
    await ledger.updateCategory(cafe.id, name: 'Кафе и бары');
    expect((await reread(cafe.id)).limit, CategoryLimit(rub(1200000)));
  });

  test('a copy carries the limit there and back', () async {
    final euros = CategoryLimit(Money(40000, Currency.eur), warnEarly: false);
    await ledger.setCategoryLimit(cafe.id, euros);
    final copy = LedgerCopy.parse((await ledger.copy()).encode());
    final restoredDatabase = BirkaDatabase(NativeDatabase.memory());
    addTearDown(restoredDatabase.close);
    final restored = LedgerRepository(restoredDatabase);
    await restored.restore(copy);
    expect((await restored.category(cafe.id))!.limit, euros);
  });

  test('a copy of an older version restores without limits', () async {
    await ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(1200000)));
    final json =
        jsonDecode((await ledger.copy()).encode()) as Map<String, Object?>;
    json['version'] = 11;
    for (final category in json['categories']! as List<Object?>) {
      (category! as Map<String, Object?>).remove('limit');
    }
    final restoredDatabase = BirkaDatabase(NativeDatabase.memory());
    addTearDown(restoredDatabase.close);
    final restored = LedgerRepository(restoredDatabase);
    await restored.restore(LedgerCopy.parse(jsonEncode(json)));
    expect((await restored.category(cafe.id))!.limit, isNull);
  });

  test('a limit of zero damages the copy', () async {
    await ledger.setCategoryLimit(cafe.id, CategoryLimit(rub(1200000)));
    final json =
        jsonDecode((await ledger.copy()).encode()) as Map<String, Object?>;
    final category =
        (json['categories']! as List<Object?>).single! as Map<String, Object?>;
    (category['limit']! as Map<String, Object?>)['minor'] = 0;
    expect(
      () => LedgerCopy.parse(jsonEncode(json)),
      throwsA(isA<LedgerCopyException>()),
    );
  });
}
