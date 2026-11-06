import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:import_common/import_common.dart';
import 'package:import_flutter/src/presentation/import_categories_page.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

import 'fakes.dart';

const BankCategory _transfers = (kind: CategoryKind.income, name: 'Переводы');
const BankCategory _food = (kind: CategoryKind.expense, name: 'Продукты');

void main() {
  late ImportCubit cubit;
  var closed = false;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    closed = false;
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<void> pump(
    WidgetTester tester, {
    ChosenStatement Function() file = october,
    ImportMemory? remembered,
  }) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    cubit = ImportCubit(
      FakeImportRepository([card], ledgerCategories: ledgerCategories),
      const FileStatementReader(),
      FakeStatementFiles([]),
      remembered: remembered,
    );
    addTearDown(cubit.close);
    await cubit.start();
    final chosen = file();
    await cubit.read(chosen.name, chosen.bytes);
    if (!cubit.state.planned) {
      await cubit.stream.firstWhere((state) => state.planned);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: BirkaButton(
              label: 'Категории',
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const ImportCategoriesPage(),
                    ),
                  ),
                );
                closed = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Категории'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows each category of the bank, its operations and place', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('alfa-2026-10.csv'), findsOneWidget);
    expect(find.text('Альфа-Банк · 4 категории в выписке'), findsOneWidget);
    expect(find.textContaining('3 из 4 узнали по названиям.'), findsOneWidget);
    expect(find.text('РАСХОДЫ'), findsOneWidget);
    expect(find.text('3 операции'), findsOneWidget);
    expect(find.text('ПОСТУПЛЕНИЯ'), findsOneWidget);
    expect(find.text('Продукты'), findsNWidgets(2));
    expect(find.text('Рестораны и кафе'), findsOneWidget);
    expect(find.text('Кафе'), findsOneWidget);
    expect(find.text('ЖКХ'), findsOneWidget);
    expect(find.text('Дом'), findsOneWidget);
    expect(find.text('Переводы'), findsOneWidget);
    expect(find.text('Решу во «Входящих»'), findsOneWidget);
    expect(find.text('ГОТОВО · 1 ВО «ВХОДЯЩИХ»'), findsOneWidget);
    expect(
      find.text('Выбор запомним для выписок Альфа-Банка'),
      findsOneWidget,
    );
  });

  testWidgets('puts a category of the bank into one of the ledger', (
    tester,
  ) async {
    await pump(tester);

    await tap(tester, find.text('Переводы'));

    expect(find.text('Категория для «Переводы»'), findsOneWidget);
    expect(find.text('1 операция · поступление'), findsOneWidget);
    expect(find.text('операции подождут без категории'), findsOneWidget);
    expect(find.text('Новая: Переводы'), findsOneWidget);
    expect(find.text('появится при импорте'), findsOneWidget);
    expect(find.text('Продукты'), findsNWidgets(2));

    await tap(tester, find.text('Зарплата'));

    expect(find.text('Категория для «Переводы»'), findsNothing);
    expect(find.text('Зарплата'), findsOneWidget);
    expect(find.text('ГОТОВО'), findsOneWidget);
    expect(
      cubit.state.choices!.categories[_transfers],
      isA<IntoCategory>().having((it) => it.categoryId, 'id', 'salary'),
    );
    expect(cubit.state.chosen, {_transfers});
  });

  testWidgets('makes a new category of the name of the bank', (tester) async {
    await pump(tester);

    await tap(tester, find.text('Переводы'));
    await tap(tester, find.text('Новая: Переводы'));

    expect(find.text('1 операция · новая категория'), findsOneWidget);
    expect(find.text('Переводы'), findsNWidgets(2));
    expect(
      cubit.state.choices!.categories[_transfers],
      isA<NewCategory>().having((it) => it.name, 'name', 'Переводы'),
    );
  });

  testWidgets('sends a category of the bank to the inbox', (tester) async {
    await pump(tester);

    await tap(tester, find.text('Продукты').first);

    expect(find.text('Новая: Продукты'), findsNothing);
    await tap(tester, find.text('Решу во «Входящих»').last);

    expect(cubit.state.choices!.categories[_food], isA<Unsorted>());
    expect(find.text('ГОТОВО · 2 ВО «ВХОДЯЩИХ»'), findsOneWidget);
  });

  testWidgets('says when the places are those of the last statement', (
    tester,
  ) async {
    final store = FakeSettingsStore();
    await ImportMemory(store).remember(
      alfa,
      const RememberedChoices(categories: {_transfers: 'salary'}),
    );

    await pump(tester, remembered: ImportMemory(store));

    expect(
      find.textContaining('Взяли ваш выбор с прошлой выписки Альфа-Банка.'),
      findsOneWidget,
    );
    expect(find.text('Зарплата'), findsOneWidget);
    expect(find.text('ГОТОВО'), findsOneWidget);
  });

  testWidgets('puts the fees of the bank among the expenses', (tester) async {
    await pump(tester, file: revolutOctober);

    // One among the expenses and one among the income.
    expect(find.text('Без категории банка'), findsNWidgets(2));
    expect(find.text('Комиссии банка'), findsOneWidget);

    await tap(tester, find.text('Комиссии банка'));
    await tap(tester, find.text('Новая: Комиссии банка'));

    expect(
      cubit.state.choices!.fees,
      isA<NewCategory>().having((it) => it.name, 'name', 'Комиссии банка'),
    );
  });

  testWidgets('goes back to the sheet', (tester) async {
    await pump(tester);

    await tap(tester, find.text('ГОТОВО · 1 ВО «ВХОДЯЩИХ»'));

    expect(closed, isTrue);
  });
}
