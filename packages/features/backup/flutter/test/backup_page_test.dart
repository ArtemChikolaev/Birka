import 'package:backup_common/backup_common.dart';
import 'package:backup_flutter/backup_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'fakes.dart';

void main() {
  final now = DateTime(2026, 11, 2, 21, 40);
  late FakeBackupRepository repository;
  late FakeBackupFiles files;
  late FakeSettingsStore store;
  var left = 0;

  Future<BackupCubit> pump(
    WidgetTester tester, {
    bool demo = false,
    ValueChanged<bool>? onDemoChanged,
  }) async {
    tester.view.physicalSize = const Size(780, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cubit = BackupCubit(repository, files, store, now: () => now);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider.value(
          value: cubit,
          child: BackupPage(
            onBack: () => left++,
            demo: demo,
            onDemoChanged: onDemoChanged,
            clock: () => now,
          ),
        ),
      ),
    );
    repository.counts.add(
      const LedgerCounts(accounts: 6, categories: 24, transactions: 1248),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  BirkaGlyph toastGlyph(WidgetTester tester) => tester
      .widget<BirkaIcon>(
        find.descendant(
          of: find.byType(GlassToast),
          matching: find.byType(BirkaIcon),
        ),
      )
      .glyph;

  setUp(() {
    repository = FakeBackupRepository()
      ..copyText = sampleCopy(madeAt: DateTime(2026, 11, 2, 18, 40));
    files = FakeBackupFiles();
    store = FakeSettingsStore();
    left = 0;
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('says where the records live and how many there are', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Учёт хранится здесь'), findsOneWidget);
    expect(find.text('Копии ещё не было'), findsOneWidget);
    expect(find.text('1\u00A0248'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('the arrow goes back', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Назад'));

    expect(left, 1);
  });

  testWidgets('a saved copy says so and when it was made', (tester) async {
    await pump(tester);

    await tapText(tester, 'СОХРАНИТЬ КОПИЮ');

    expect(files.saved.single.name, 'birka-2026-11-02.birka');
    expect(find.text('Копия готова: birka-2026-11-02.birka'), findsOneWidget);
    expect(toastGlyph(tester), BirkaGlyph.check);
    expect(find.text('Последняя копия: сегодня, 18:40'), findsOneWidget);
  });

  testWidgets('a copy waits for a yes and then replaces the records', (
    tester,
  ) async {
    files.chosen = FakeFile(
      'birka-2026-10-28.birka',
      sampleCopy(madeAt: DateTime(2026, 10, 28, 21, 40), operations: 1190),
    );
    await pump(tester);

    await tapText(tester, 'ВОССТАНОВИТЬ ИЗ КОПИИ');

    expect(find.text('Восстановить из копии?'), findsOneWidget);
    expect(find.text('birka-2026-10-28.birka'), findsOneWidget);
    expect(
      find.text('28\u00A0октября, 21:40 · 1\u00A0190 операций · 1 счёт'),
      findsOneWidget,
    );
    expect(repository.restored, isEmpty);

    await tapText(tester, 'ЗАМЕНИТЬ ЗАПИСИ');

    expect(repository.restored.single.counts.transactions, 1190);
    expect(find.text('Восстановить из копии?'), findsNothing);
    expect(
      find.text('Записи восстановлены из копии от 28\u00A0октября'),
      findsOneWidget,
    );
  });

  testWidgets('a copy that was let go stays out', (tester) async {
    files.chosen = FakeFile('birka-2026-10-28.birka', sampleCopy());
    final cubit = await pump(tester);

    await tapText(tester, 'ВОССТАНОВИТЬ ИЗ КОПИИ');
    await tapText(tester, 'ОТМЕНА');

    expect(repository.restored, isEmpty);
    expect(cubit.state.offer, isNull);
  });

  testWidgets('a file that is not a copy is turned away', (tester) async {
    files.chosen = FakeFile('photo.txt', 'not a copy');
    await pump(tester);

    await tapText(tester, 'ВОССТАНОВИТЬ ИЗ КОПИИ');

    expect(find.text('Восстановить из копии?'), findsNothing);
    expect(find.text('Это не копия Birka.'), findsOneWidget);
    expect(toastGlyph(tester), BirkaGlyph.close);
  });

  testWidgets('the operations go to a table', (tester) async {
    await pump(tester);

    await tapText(tester, 'Операции в CSV');

    expect(files.saved.single.name, 'birka-operations-2026-11-02.csv');
    expect(
      find.text('Файл готов: birka-operations-2026-11-02.csv'),
      findsOneWidget,
    );
  });

  testWidgets('everything goes only after a yes', (tester) async {
    await pump(tester);

    await tapText(tester, 'Удалить все данные');
    expect(find.text('Удалить все данные?'), findsOneWidget);
    await tapText(tester, 'ОТМЕНА');
    expect(repository.wipes, 0);

    await tapText(tester, 'Удалить все данные');
    await tapText(tester, 'УДАЛИТЬ ВСЁ');

    expect(repository.wipes, 1);
    expect(find.text('Все данные удалены с этого устройства'), findsOneWidget);
  });

  testWidgets('a copy can come first instead of the wipe', (tester) async {
    await pump(tester);

    await tapText(tester, 'Удалить все данные');
    await tapText(tester, 'СНАЧАЛА СОХРАНИТЬ КОПИЮ');

    expect(files.saved, hasLength(1));
    expect(repository.wipes, 0);
  });

  testWidgets('the buttons wait while a file is saved', (tester) async {
    files.waiting = true;
    await pump(tester);

    await tester.tap(find.text('СОХРАНИТЬ КОПИЮ'));
    await tester.pump();
    await tapText(tester, 'Операции в CSV');

    files.release();
    await tester.pumpAndSettle();
    expect(files.saved.map((file) => file.name), ['birka-2026-11-02.birka']);
  });

  testWidgets('offers the demo, which the host turns on', (tester) async {
    final turns = <bool>[];
    await pump(tester, onDemoChanged: turns.add);

    await tester.ensureVisible(find.text('Демо-данные'));
    expect(
      find.text('Пример счетов и операций, чтобы осмотреться'),
      findsOneWidget,
    );
    await tester.tap(find.byType(Switch));

    expect(turns, [true]);
  });

  testWidgets('shows the demo that is on, and turns it off', (tester) async {
    final turns = <bool>[];
    await pump(tester, demo: true, onDemoChanged: turns.add);

    await tester.ensureVisible(find.byType(Switch));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byType(Switch));

    expect(turns, [false]);
  });

  testWidgets('offers no demo without a host that can turn it', (tester) async {
    await pump(tester);

    expect(find.text('Демо-данные'), findsNothing);
  });
}
