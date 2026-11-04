@TestOn('vm')
library;

import 'package:database/database.dart';
import 'package:decimal/decimal.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_jaspr/inbox_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The settings in memory.
final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late InboxCubit cubit;
  late Account card;
  late Category shop;

  Future<String> spend(
    Account account,
    Money amount,
    CivilDate day,
    String note, {
    Category? category,
    String? importId,
  }) => ledger.record(
    TransactionDraft.expense(
      accountId: account.id,
      allocations: [Allocation(categoryId: category?.id, amount: amount)],
      occurredOn: day,
      note: note,
    ),
    importId: importId,
  );

  Future<void> until(
    ComponentTester tester,
    bool Function(InboxState state) test,
  ) async {
    if (!test(cubit.state)) await cubit.stream.firstWhere(test);
    await tester.pump();
  }

  Future<void> pump(ComponentTester tester) async {
    tester.pumpComponent(
      BlocProvider.value(
        value: cubit,
        child: InboxPage(
          backHref: 'more/',
          clock: () => DateTime(2026, 11, 4),
        ),
      ),
    );
    await until(tester, (state) => !state.loading);
  }

  Future<void> clickText(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  setUp(() async {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    await RatesRepository(database).keep(
      DayRates(CivilDate(2026, 9, 30), {'USD': Decimal.parse('81.20')}),
    );
    card = await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: _rub(0),
    );
    final wise = await ledger.addAccount(
      name: 'Wise USD',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.usd),
    );
    final cafe = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Кафе',
    );
    shop = await ledger.addCategory(
      kind: CategoryKind.expense,
      name: 'Покупки',
    );
    for (final day in [3, 12, 25]) {
      await spend(
        card,
        _rub(1450),
        CivilDate(2026, 9, day),
        'ИП Соколов А. В.',
        category: cafe,
      );
    }
    await spend(
      wise,
      Money(231000, Currency.usd),
      CivilDate(2026, 9, 30),
      'Card top-up',
    );
    final october = await ledger.addImport(
      fileName: 'alfa-2026-10.xlsx',
      format: 'alfa',
      firstDay: CivilDate(2026, 10, 1),
      lastDay: CivilDate(2026, 10, 21),
    );
    await ledger.record(
      TransactionDraft.income(
        accountId: card.id,
        allocations: [Allocation(categoryId: null, amount: _rub(185000))],
        occurredOn: CivilDate(2026, 10, 1),
        note: 'Пополнение с Wise',
      ),
      importId: october,
    );
    await spend(
      card,
      _rub(1450),
      CivilDate(2026, 10, 4),
      'ИП Соколов А. В.',
      importId: october,
    );
    await spend(
      card,
      _rub(3000),
      CivilDate(2026, 10, 9),
      'Перевод Ивану К.',
      importId: october,
    );
    cubit = InboxCubit(
      LedgerInboxRepository(ledger, RatesRepository(database)),
      _Store(),
    );
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('shows what waits after which import, with hints', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Входящие'), findsOneComponent);
    expect(
      find.text('3 ждут решения · после импорта Альфа-Банка'),
      findsOneComponent,
    );
    expect(
      find.text('Похоже на перевод между вашими счетами'),
      findsOneComponent,
    );
    expect(find.text('Card top-up'), findsOneComponent);
    expect(find.text('Пополнение с Wise · из выписки'), findsOneComponent);
    expect(find.text('Без категории · 2'), findsOneComponent);
    expect(find.text('ИП Соколов А. В.'), findsOneComponent);
    expect(find.text('Кафе ?'), findsOneComponent);
    expect(
      find.text('так вы отметили его 3 раза в сентябре'),
      findsOneComponent,
    );
    expect(find.text('Откуда подсказки'), findsOneComponent);
  });

  testComponents('a yes sorts the operation', (tester) async {
    await pump(tester);

    await clickText(tester, 'Да');
    await until(tester, (state) => state.items.length == 1);

    expect(find.text('ИП Соколов А. В.'), findsNothing);
    expect(find.text('Без категории · 1'), findsOneComponent);
  });

  testComponents('the picked get one category together', (tester) async {
    await pump(tester);

    await tester.click(
      find.byComponentPredicate(
        (component) =>
            component is DomComponent &&
            component.attributes?['aria-label'] == 'Выбрать «Перевод Ивану К.»',
      ),
    );
    await tester.pump();

    expect(find.text('Выбрана 1 операция'), findsOneComponent);

    final field = find.byType(select).evaluate().last.component as select;
    final options = [
      for (final element
          in find
              .descendant(
                of: find.byComponent(field),
                matching: find.byType(option),
              )
              .evaluate())
        element.component as option,
    ];
    final index = options.indexWhere(
      (it) => find
          .descendant(of: find.byComponent(it), matching: find.text('Покупки'))
          .evaluate()
          .isNotEmpty,
    );
    field.onChange!(['$index']);
    await until(tester, (state) => state.items.length == 1);

    expect(find.text('Перевод Ивану К.'), findsNothing);
    expect(find.text('Выбрана 1 операция'), findsNothing);
    final transactions = await ledger.watchTransactions(limit: null).first;
    expect(
      transactions
          .where((it) => it.note == 'Перевод Ивану К.')
          .single
          .allocations
          .single
          .categoryId,
      shop.id,
    );
  });

  testComponents('a pair becomes a transfer with a word', (tester) async {
    await pump(tester);

    await clickText(tester, 'Сделать переводом');
    await until(tester, (state) => state.pairs.isEmpty && state.busy.isEmpty);

    expect(find.text('Похоже на перевод между вашими счетами'), findsNothing);
    expect(find.text('Сделали перевод'), findsOneComponent);
  });

  testComponents('shows the transfers alone', (tester) async {
    await pump(tester);

    await clickText(tester, 'Переводы');

    expect(find.text('ИП Соколов А. В.'), findsNothing);
    expect(
      find.text('Похоже на перевод между вашими счетами'),
      findsOneComponent,
    );
  });

  testComponents('says when everything is sorted', (tester) async {
    await cubit.close();
    await database.close();
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    cubit = InboxCubit(
      LedgerInboxRepository(ledger, RatesRepository(database)),
      _Store(),
    );

    await pump(tester);

    expect(find.text('Всё разобрано'), findsOneComponent);
    expect(find.text('0 ждут решения'), findsNothing);
  });
}
