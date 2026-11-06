import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:import_common/import_common.dart';
import 'package:import_flutter/import_flutter.dart';
import 'package:import_flutter/src/presentation/import_columns_page.dart';
import 'package:l10n/l10n.dart';

import 'fakes.dart';

void main() {
  late FakeImportRepository repository;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    repository = FakeImportRepository([card]);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  /// Pumps until the file is read and planned, then lets the sheet settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byType(ImportSheet).evaluate().isNotEmpty &&
          find.byType(LinearProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    List<ChosenStatement?> files, {
    VoidCallback? onInbox,
    ImportMemory? remembered,
  }) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final window = FakeStatementFiles(files);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => BirkaButton(
              label: 'Импорт',
              onPressed: () => showImportSheet(
                context,
                cubit: () => ImportCubit(
                  repository,
                  const FileStatementReader(),
                  window,
                  remembered: remembered,
                ),
                files: window,
                onInbox: onInbox,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Импорт'));
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await settle(tester);
  }

  testWidgets('shows what Birka knew in the file and where it goes', (
    tester,
  ) async {
    await open(tester, [october()]);

    expect(find.text('Импорт выписки'), findsOneWidget);
    expect(find.text('alfa-2026-10.csv'), findsOneWidget);
    expect(find.text('Альфа-Банк · узнали по колонкам'), findsOneWidget);
    expect(find.text('Зарплатная карта'), findsOneWidget);
    expect(find.text('••4821 · совпал номер карты'), findsOneWidget);
    expect(find.text('Операций за 1–7 октября 2026'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Разобрать потом'), findsOneWidget);
    expect(find.text('4 во «Входящих»'), findsOneWidget);
    expect(find.text('Остаток после'), findsOneWidget);
    expect(find.text('Уже есть в учёте'), findsNothing);
    expect(find.text('Категории банка'), findsOneWidget);
    expect(find.text('Birka их пока не знает'), findsOneWidget);
    expect(find.text('ИМПОРТИРОВАТЬ 4 ОПЕРАЦИИ'), findsOneWidget);
  });

  testWidgets('leads to the categories of the bank and back', (tester) async {
    repository = FakeImportRepository([
      card,
    ], ledgerCategories: ledgerCategories);
    await open(tester, [october()]);

    expect(find.text('3 из 4 узнали сами'), findsOneWidget);
    expect(find.text('1 во «Входящих»'), findsOneWidget);

    await tapText(tester, 'Категории банка');
    await tapText(tester, 'Переводы');
    await tapText(tester, 'Новая: Переводы');
    await tapText(tester, 'ГОТОВО');

    expect(find.text('Импорт выписки'), findsOneWidget);
    expect(find.text('3 из 4 узнали сами'), findsOneWidget);
    expect(find.text('Разобрать потом'), findsNothing);
  });

  testWidgets('imports the operations and takes them back out', (
    tester,
  ) async {
    await open(tester, [october()]);

    await tapText(tester, 'ИМПОРТИРОВАТЬ 4 ОПЕРАЦИИ');

    expect(repository.written, hasLength(1));
    expect(find.text('Добавили 4 операции'), findsOneWidget);
    expect(
      find.text('Альфа-Банк, 1–7 октября 2026 → Зарплатная карта'),
      findsOneWidget,
    );
    expect(find.text('4 ждут вашего решения во «Входящих»'), findsOneWidget);

    await tapText(tester, 'ОТМЕНИТЬ ИМПОРТ');

    expect(repository.undone, ['import-1']);
    expect(find.text('Импорт отменён'), findsOneWidget);

    await tapText(tester, 'ГОТОВО');

    expect(find.byType(ImportSheet), findsNothing);
  });

  testWidgets('leads from what waits to the inbox of the host', (
    tester,
  ) async {
    var opened = 0;
    await open(tester, [october()], onInbox: () => opened++);
    await tapText(tester, 'ИМПОРТИРОВАТЬ 4 ОПЕРАЦИИ');

    await tapText(tester, '4 ждут вашего решения во «Входящих»');

    expect(opened, 1);
    expect(find.byType(ImportSheet), findsNothing);
  });

  testWidgets('sends the operations into a new account when asked', (
    tester,
  ) async {
    await open(tester, [october()]);

    await tapText(tester, 'Зарплатная карта');
    expect(find.text('Куда записать операции карты ••4821'), findsOneWidget);
    await tapText(tester, 'Новый счёт');

    expect(find.text('Новый счёт'), findsOneWidget);
    await tapText(tester, 'ИМПОРТИРОВАТЬ 4 ОПЕРАЦИИ');
    expect(
      repository.written.single.choices.accounts.values.single,
      isA<NewAccount>(),
    );
  });

  testWidgets('says which rows stay out and why', (tester) async {
    await open(tester, [octoberWithGaps()]);

    expect(find.text('2 строки не попадут в учёт'), findsOneWidget);
    expect(find.text('2 не прочитались'), findsOneWidget);
    expect(find.text('ИМПОРТИРОВАТЬ 4 ОПЕРАЦИИ'), findsOneWidget);

    await tapText(tester, '2 строки не попадут в учёт');

    expect(
      find.text('alfa-2026-10.csv · остальные 4 в порядке'),
      findsOneWidget,
    );
    expect(find.text('НЕ ПРОЧИТАЛИ'), findsOneWidget);
    expect(find.text('Перевод по номеру телефона'), findsOneWidget);
    expect(find.text('Строка 6 · нет суммы'), findsOneWidget);
    expect(find.text('Аптека №12'), findsOneWidget);
    expect(
      find.text('Строка 7 · 31.09.2026, такого дня нет'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Непрочитанные запишите вручную'),
      findsOneWidget,
    );

    await tapText(tester, 'ПОНЯТНО');

    expect(find.text('НЕ ПРОЧИТАЛИ'), findsNothing);
    expect(find.text('ИМПОРТИРОВАТЬ 4 ОПЕРАЦИИ'), findsOneWidget);
  });

  testWidgets('keeps apart what the bank did not carry out', (tester) async {
    await open(tester, [tbankDeclined()]);

    expect(find.text('1 строка не попадёт в учёт'), findsOneWidget);
    expect(find.text('1 не прошла в банке'), findsOneWidget);

    await tapText(tester, '1 строка не попадёт в учёт');

    expect(find.text('НЕ ПРОШЛИ В БАНКЕ'), findsOneWidget);
    expect(find.text('Магнит'), findsOneWidget);
    expect(find.text('Строка 3 · операция не прошла'), findsOneWidget);
    expect(find.text('НЕ ПРОЧИТАЛИ'), findsNothing);
    expect(find.textContaining('Непрочитанные запишите вручную'), findsNothing);
  });

  testWidgets('leads a statement that mostly does not read to its columns', (
    tester,
  ) async {
    await open(tester, [octoberGarbled()]);

    expect(find.text('Импорт выписки'), findsOneWidget);
    expect(find.text('3 строки из 3 не прочитались'), findsOneWidget);
    expect(find.textContaining('проверьте, где в ней дата'), findsOneWidget);
    expect(find.textContaining('ИМПОРТИРОВАТЬ'), findsNothing);

    await tapText(tester, 'ПРОВЕРИТЬ КОЛОНКИ');

    expect(find.byType(ImportColumnsPage), findsOneWidget);
  });

  testWidgets('leads a format it does not know to its columns', (
    tester,
  ) async {
    await open(tester, [unknown()]);

    expect(find.text('Формат не узнали'), findsOneWidget);
    expect(find.text('statement_oct_2026.csv'), findsOneWidget);
    expect(find.text('4 колонки · 3 строки'), findsOneWidget);

    await tapText(tester, 'НАЗНАЧИТЬ КОЛОНКИ');

    expect(find.byType(ImportColumnsPage), findsOneWidget);
    expect(find.text('КОЛОНКИ ВЫПИСКИ'), findsOneWidget);
  });

  testWidgets('imports a format of its own once its columns are set', (
    tester,
  ) async {
    await open(tester, [unknown()]);
    await tapText(tester, 'НАЗНАЧИТЬ КОЛОНКИ');

    await tapText(tester, 'Сумма в валюте счёта');
    expect(find.text('Что в колонке «Сумма в валюте счёта»'), findsOneWidget);
    expect(
      find.text('расход и поступление в одной колонке'),
      findsOneWidget,
    );
    await tapText(tester, 'Сумма');
    await tapText(tester, 'ГОТОВО · 2 ОПЕРАЦИИ');

    expect(find.byType(ImportColumnsPage), findsNothing);
    expect(find.text('Свой формат · колонки назначили вы'), findsOneWidget);
    await tapText(tester, 'ИМПОРТИРОВАТЬ 2 ОПЕРАЦИИ');

    expect(repository.written.single.added, hasLength(2));
  });

  testWidgets('says what the bank holds when the balance will differ', (
    tester,
  ) async {
    await open(tester, [unknown()]);
    await tapText(tester, 'НАЗНАЧИТЬ КОЛОНКИ');
    await tapText(tester, 'Сумма в валюте счёта');
    await tapText(tester, 'Сумма');
    await tapText(tester, 'ГОТОВО · 2 ОПЕРАЦИИ');

    expect(find.textContaining('В банке'), findsNothing);
    // Into the card of the ledger, which does not hold what the file began
    // with.
    await tapText(tester, 'Новый счёт');
    await tapText(tester, 'Зарплатная карта');

    expect(find.textContaining('В банке 142'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is BirkaIcon && widget.glyph == BirkaGlyph.alert,
      ),
      findsOneWidget,
    );
  });

  testWidgets("goes on at once with a format of the person's own", (
    tester,
  ) async {
    final store = FakeSettingsStore();
    final file = unknown();
    final table = (await tester.runAsync(
      () => const FileStatementReader().read(file.name, file.bytes),
    ))!;
    await ImportMemory(store).remember(
      ownFormatOf(table, guessLayout(table).withRole(2, ColumnRole.amount))!,
      const RememberedChoices(),
    );

    await open(tester, [unknown()], remembered: ImportMemory(store));

    expect(find.text('Свой формат · узнали по колонкам'), findsOneWidget);
    expect(find.text('ИМПОРТИРОВАТЬ 2 ОПЕРАЦИИ'), findsOneWidget);
  });

  testWidgets('keeps a format of its own unknown until the person is done', (
    tester,
  ) async {
    await open(tester, [unknown()]);
    await tapText(tester, 'НАЗНАЧИТЬ КОЛОНКИ');

    await tester.tap(find.bySemanticsLabel('Назад'));
    await settle(tester);

    expect(find.text('Формат не узнали'), findsOneWidget);
  });

  testWidgets('says when a file holds no table', (tester) async {
    await open(tester, [picture()]);

    expect(find.text('Файл не прочитался'), findsOneWidget);

    await tapText(tester, 'ОТМЕНА');

    expect(find.byType(ImportSheet), findsNothing);
  });

  testWidgets('opens nothing when no file was chosen', (tester) async {
    await open(tester, [null]);

    expect(find.byType(ImportSheet), findsNothing);
  });
}
