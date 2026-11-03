import 'package:backup_common/backup_common.dart';
import 'package:backup_jaspr/backup_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';

import 'fakes.dart';

void main() {
  final now = DateTime(2026, 11, 2, 21, 40);
  late FakeBackupRepository repository;
  late FakeBackupFiles files;
  late FakeSettingsStore store;

  Future<void> pump(ComponentTester tester, {String? note}) async {
    final cubit = BackupCubit(repository, files, store, now: () => now);
    addTearDown(cubit.close);
    tester.pumpComponent(
      BlocProvider.value(
        value: cubit,
        child: BackupPage(note: note, clock: () => now),
      ),
    );
    repository.counts.add(
      const LedgerCounts(accounts: 6, categories: 24, transactions: 1248),
    );
    await tester.pump();
  }

  Future<void> clickText(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  GlassToast toast() =>
      find.byType(GlassToast).evaluate().single.component as GlassToast;

  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
    repository = FakeBackupRepository()
      ..copyText = sampleCopy(madeAt: DateTime(2026, 11, 2, 18, 40));
    files = FakeBackupFiles();
    store = FakeSettingsStore();
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('shows where the data lives and how much it holds', (
    tester,
  ) async {
    await pump(tester, note: 'Данные хранятся только в этом браузере.');

    expect(find.text('Учёт хранится здесь'), findsOneComponent);
    expect(
      find.text('Данные хранятся только в этом браузере.'),
      findsOneComponent,
    );
    expect(find.text('Копии ещё не было'), findsOneComponent);
    expect(find.text('1 248'), findsOneComponent);
    expect(find.text('24'), findsOneComponent);
    expect(
      find.text('Файлы сохраняются туда же, куда браузер кладёт загрузки.'),
      findsOneComponent,
    );
  });

  testComponents('a copy goes to the downloads and says so', (tester) async {
    await pump(tester);

    await clickText(tester, 'Сохранить копию');

    expect(files.saved.single.name, 'birka-2026-11-02.birka');
    expect(toast().text, 'Копия готова: birka-2026-11-02.birka');
    expect(toast().trouble, isFalse);
    expect(find.text('Копии ещё не было'), findsNothing);
  });

  testComponents('a restore asks first and then replaces the records', (
    tester,
  ) async {
    files.chosen = FakeFile('birka-2026-11-02.birka', sampleCopy());
    await pump(tester);

    await clickText(tester, 'Восстановить из копии');

    expect(find.text('Восстановить из копии?'), findsOneComponent);
    expect(find.text('birka-2026-11-02.birka'), findsOneComponent);
    expect(find.text('Сохранить копию'), findsNothing);

    await clickText(tester, 'Заменить записи');

    expect(repository.restored, hasLength(1));
    expect(find.text('Восстановить из копии?'), findsNothing);
    expect(toast().text, startsWith('Записи восстановлены из копии от'));
  });

  testComponents('a restore can be let go', (tester) async {
    files.chosen = FakeFile('birka-2026-11-02.birka', sampleCopy());
    await pump(tester);

    await clickText(tester, 'Восстановить из копии');
    await clickText(tester, 'Отмена');

    expect(repository.restored, isEmpty);
    expect(find.text('Сохранить копию'), findsOneComponent);
  });

  testComponents('a file that is not a copy says so', (tester) async {
    files.chosen = FakeFile('photo.jpg', 'not a copy');
    await pump(tester);

    await clickText(tester, 'Восстановить из копии');

    expect(find.text('Восстановить из копии?'), findsNothing);
    expect(toast().text, 'Это не копия Birka.');
    expect(toast().trouble, isTrue);
  });

  testComponents('a wipe asks first and can take a copy before', (
    tester,
  ) async {
    await pump(tester);

    await clickText(tester, 'Удалить все данные');
    expect(find.text('Удалить все данные?'), findsOneComponent);

    await clickText(tester, 'Сначала сохранить копию');
    expect(files.saved, hasLength(1));
    expect(repository.wipes, 0);

    await clickText(tester, 'Удалить все данные');
    await clickText(tester, 'Удалить всё');

    expect(repository.wipes, 1);
    expect(toast().text, 'Все данные удалены с этого устройства');
  });

  testComponents('the operations go to a table for a spreadsheet', (
    tester,
  ) async {
    await pump(tester);

    await tester.click(
      find
          .ancestor(
            of: find.text('Операции в CSV'),
            matching: find.tag('button'),
          )
          .first,
    );
    await tester.pump();

    expect(files.saved.single.name, 'birka-operations-2026-11-02.csv');
    expect(toast().text, 'Файл готов: birka-operations-2026-11-02.csv');
  });
}
