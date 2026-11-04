@TestOn('vm')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/import_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The window of files, which the tests never open.
final class _Files implements StatementFiles {
  @override
  Future<ChosenStatement?> choose() async => null;
}

/// A CSV of a card of Alfa-Bank in October.
final Uint8List _october = utf8.encode(
  [
    'Дата операции;Описание;Сумма;Валюта;Категория;Номер карты',
    '01.10.2026 10:00;TOPUP WISE;185 000,00;RUR;Переводы;*4821',
    '02.10.2026 18:40;PRODUKTY BEREZKA;−2 340,50;RUR;Продукты;*4821',
    '03.10.2026 09:12;ZERNO COFFEE;−420,00;RUR;Рестораны и кафе;*4821',
    '07.10.2026;ZHKU MOSKVA;−6 845,30;RUR;ЖКХ;*4821',
  ].join('\n'),
);

void main() {
  final now = DateTime(2026, 11, 4, 12);
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late ImportCubit cubit;

  Future<void> pump(
    ComponentTester tester, {
    VoidCallback? onStepChanged,
  }) async {
    tester.pumpComponent(
      BlocProvider.value(
        value: cubit,
        child: ImportPage(
          backHref: 'more/',
          operationsHref: 'operations/',
          onStepChanged: onStepChanged,
          clock: () => now,
        ),
      ),
    );
    await tester.pump();
  }

  /// Waits until [test] holds for the state, and draws the page again.
  Future<void> until(
    ComponentTester tester,
    bool Function(ImportState state) test,
  ) async {
    if (!test(cubit.state)) await cubit.stream.firstWhere(test);
    await tester.pump();
  }

  Future<void> clickText(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  /// Reads the file of October and waits for its plan.
  Future<void> read(ComponentTester tester) async {
    await cubit.read('alfa-2026-10.csv', _october);
    await until(tester, (state) => state.planned);
  }

  /// Takes the file of October through every step into the ledger.
  Future<void> imported(ComponentTester tester) async {
    await read(tester);
    await clickText(tester, 'Дальше: колонки');
    await clickText(tester, 'Дальше: счёт');
    await clickText(tester, 'Дальше: дубликаты');
    await clickText(tester, 'Импортировать 4 операции');
    await until(tester, (state) => state.importId != null);
  }

  setUp(() async {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database);
    await ledger.addAccount(
      name: 'Зарплатная карта',
      type: AccountType.debit,
      openingBalance: Money(0, Currency.rub),
      lastDigits: '4821',
    );
    await ledger.addCategory(kind: CategoryKind.expense, name: 'Продукты');
    await ledger.addCategory(kind: CategoryKind.expense, name: 'Дом');
    cubit = ImportCubit(
      LedgerImportRepository(ledger),
      const FileStatementReader(),
      _Files(),
      today: () => CivilDate(2026, 11, 4),
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('opens on the file, with where to get one', (tester) async {
    await pump(tester);

    expect(find.text('Импорт выписки'), findsOneComponent);
    expect(
      find.text('Шаг 1 из 6 · файл из банка или Дзен-мани'),
      findsOneComponent,
    );
    expect(find.text('Перетащите выписку сюда'), findsOneComponent);
    expect(find.text('Выбрать файл'), findsOneComponent);
    expect(find.text('Где взять выписку'), findsOneComponent);
    expect(find.text('Без паролей от банка'), findsOneComponent);
    expect(find.text('Прошлые импорты'), findsNothing);
  });

  testComponents('says why a file does not read', (tester) async {
    await pump(tester);

    await cubit.read('empty.csv', Uint8List(0));
    await tester.pump();

    expect(find.text('Файл не прочитался'), findsOneComponent);
    expect(find.text('В файле пусто.'), findsOneComponent);
  });

  testComponents('tells the bank by the columns of the file', (tester) async {
    var changes = 0;
    await pump(tester, onStepChanged: () => changes++);

    await read(tester);

    expect(changes, 1);
    expect(find.text('Похоже на выписку Альфа-Банка'), findsOneComponent);
    expect(find.text('Шаг 2 из 6 · чья это выписка'), findsOneComponent);
    expect(find.text('alfa-2026-10.csv'), findsOneComponent);
    expect(find.text('1–7 октября 2026'), findsOneComponent);
  });

  testComponents('shows the rows and the categories as they go in', (
    tester,
  ) async {
    await pump(tester);
    await read(tester);

    await clickText(tester, 'Дальше: колонки');

    expect(find.text('Колонки файла'), findsOneComponent);
    expect(find.text('PRODUKTY BEREZKA'), findsOneComponent);
    expect(
      find.text('−2 340,50 ₽'.replaceAll(' ', '\u00A0')),
      findsOneComponent,
    );
    expect(find.text('Категории банка → ваши'), findsOneComponent);
    expect(find.text('ЖКХ'), findsOneComponent);
  });

  testComponents('finds the account of the card', (tester) async {
    await pump(tester);
    await read(tester);

    await clickText(tester, 'Дальше: колонки');
    await clickText(tester, 'Дальше: счёт');

    expect(
      find.text('Куда записать операции карты ••4821'),
      findsOneComponent,
    );
    expect(find.text('совпал номер карты'), findsOneComponent);
    expect(find.text('Новый счёт'), findsOneComponent);
  });

  testComponents('puts the file in and takes it back out', (tester) async {
    await pump(tester);

    await imported(tester);

    expect(find.text('Добавили 4 операции'), findsOneComponent);
    expect(find.text('Шаг 6 из 6 · итог'), findsOneComponent);
    expect(find.text('Передумали?'), findsOneComponent);

    await clickText(tester, 'Отменить импорт');
    await until(tester, (state) => state.undone);

    expect(find.text('Импорт отменён'), findsOneComponent);
  });

  testComponents('takes a past import out after a yes', (tester) async {
    await pump(tester);
    await imported(tester);
    await clickText(tester, 'Загрузить ещё выписку');
    await until(tester, (state) => state.history.isNotEmpty);

    expect(find.text('Прошлые импорты'), findsOneComponent);
    expect(
      find.text('Альфа-Банк · 1–7 октября 2026'),
      findsOneComponent,
    );

    await clickText(tester, 'Отменить');

    expect(find.text('Убрать 4 операции этого файла?'), findsOneComponent);

    await clickText(tester, 'Убрать');
    await until(tester, (state) => state.history.isEmpty);

    expect(find.text('Прошлые импорты'), findsNothing);
    expect(
      find.text('Импорт «Альфа-Банк · 1–7 октября 2026» отменён'),
      findsOneComponent,
    );
  });
}
