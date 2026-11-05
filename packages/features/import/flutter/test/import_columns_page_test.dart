import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:import_common/import_common.dart';
import 'package:import_flutter/src/presentation/import_columns_page.dart';
import 'package:l10n/l10n.dart';

import 'fakes.dart';

void main() {
  late ImportCubit cubit;
  bool? closedWith;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    closedWith = null;
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final window = FakeStatementFiles([]);
    cubit = ImportCubit(
      FakeImportRepository([card]),
      const FileStatementReader(),
      window,
    );
    addTearDown(cubit.close);
    await cubit.start();
    final file = unknown();
    await cubit.read(file.name, file.bytes);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: BirkaButton(
              label: 'Колонки',
              onPressed: () async {
                closedWith = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const ImportColumnsPage(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Колонки'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  testWidgets('shows each column with its sample and what it holds', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('statement_oct_2026.csv'), findsOneWidget);
    expect(find.text('Назначение платежа'), findsOneWidget);
    expect(find.text('Зарплата'), findsWidgets);
    expect(find.text('Сумма в валюте счёта'), findsOneWidget);
    expect(find.text('96500,00'), findsOneWidget);
  });

  testWidgets('asks for the column of the amount until it has one', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.textContaining('Отметьте колонку даты и колонку суммы'),
      findsWidgets,
    );
    final done = tester.widget<BirkaButton>(find.byType(BirkaButton).last);
    expect(done.onPressed, isNull);

    await tapText(tester, 'Сумма в валюте счёта');
    await tapText(tester, 'Сумма');

    expect(find.text('ТАК СТРОКИ ПОПАДУТ В УЧЁТ'), findsOneWidget);
    expect(find.text('Кофейня Зерно'), findsOneWidget);
    await tapText(tester, 'ГОТОВО · 2 ОПЕРАЦИИ');
    expect(closedWith, isTrue);
  });

  testWidgets('reads the amounts again by another mark', (tester) async {
    await pump(tester);
    await tapText(tester, 'Сумма в валюте счёта');
    await tapText(tester, 'Сумма');

    await tester.tap(find.bySemanticsLabel('точкой'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ни одна сумма не прочиталась. '
        'Проверьте, чем в файле отделены копейки.',
      ),
      findsOneWidget,
    );
    final done = tester.widget<BirkaButton>(find.byType(BirkaButton).last);
    expect(done.onPressed, isNull);
  });

  testWidgets('goes back without the columns', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();

    expect(closedWith, isFalse);
  });
}
