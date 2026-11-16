import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

void main() {
  Money rub(int rubles) => Money(rubles * 100, Currency.rub);
  final now = DateTime(2026, 11, 18, 13);
  final card = testAccount('Карта');
  final cafe = Category(
    id: 'cafe',
    kind: CategoryKind.expense,
    name: 'Кафе',
    archived: false,
    sortOrder: 0,
    limit: CategoryLimit(rub(12000)),
  );
  final coffee = Category(
    id: 'coffee',
    kind: CategoryKind.expense,
    name: 'Кофе',
    archived: false,
    sortOrder: 1,
    parentId: cafe.id,
  );
  final gifts = testCategory('Подарки');

  late FakeTransactionsRepository repository;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    repository =
        FakeTransactionsRepository(
            accountList: [card],
            expenses: [cafe, coffee, gifts],
            income: [testCategory('Зарплата', kind: CategoryKind.income)],
          )
          ..spending = MonthSpending(
            month: CivilDate(2026, 11, 1),
            rows: [
              CategoryDayTotal(cafe, CivilDate(2026, 11, 3), rub(4150)),
              CategoryDayTotal(cafe, CivilDate(2026, 11, 12), rub(6000)),
            ],
          );
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  String plain(String text) => text.replaceAll(' ', ' ');

  Future<QuickAddCubit> open() async {
    final cubit = QuickAddCubit(repository, now: () => now);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  void type(QuickAddCubit cubit, int amount) {
    for (final digit in '$amount'.split('')) {
      cubit.digitTyped(int.parse(digit));
    }
  }

  test('says what the expense leaves of the limit', () async {
    final cubit = await open();
    cubit.categoryChanged(cafe.id);
    type(cubit, 1250);
    final line = cubit.state.limitLine!;
    expect(line.left, rub(600));
    expect(line.state, LimitState.near);
    expect(plain(limitLineLabel(line)), 'Кафе: останется 600 ₽ из 12 000 ₽');
  });

  test('says how far over the limit it goes', () async {
    final cubit = await open();
    cubit.categoryChanged(cafe.id);
    type(cubit, 2300);
    final line = cubit.state.limitLine!;
    expect(line.state, LimitState.over);
    expect(plain(limitLineLabel(line)), 'Кафе: больше лимита на 450 ₽');
  });

  test('a subcategory counts against the limit above it', () async {
    final cubit = await open();
    cubit.categoryChanged(coffee.id);
    type(cubit, 300);
    expect(cubit.state.limitLine?.category.id, cafe.id);
    expect(cubit.state.limitLine?.left, rub(1550));
  });

  test('a category without a limit and an income say nothing', () async {
    final cubit = await open();
    cubit.categoryChanged(gifts.id);
    type(cubit, 1250);
    expect(cubit.state.limitLine, isNull);
    cubit.kindChanged(TransactionKind.income);
    expect(cubit.state.limitLine, isNull);
  });

  test('no sum yet, no line', () async {
    final cubit = await open();
    cubit.categoryChanged(cafe.id);
    expect(cubit.state.limitLine, isNull);
  });

  test(
    'a day of another month leaves the line until that month comes',
    () async {
      final cubit = await open();
      cubit.categoryChanged(cafe.id);
      type(cubit, 1250);
      cubit.dayChanged(CivilDate(2026, 10, 31));
      expect(cubit.state.limitLine, isNull);
    },
  );
}
