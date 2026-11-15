import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' hide Category;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

import 'fake_repository.dart';

const code =
    't=20261031T0912&s=620.00&fn=7380440700076541&i=24611&fp=2531297412&n=1';

const groceries = Receipt(
  drive: '7380440700076541',
  document: '24611',
  sign: '2531297412',
  kind: ReceiptKind.sale,
);

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final now = DateTime(2026, 10, 31, 9, 30);
  final card = testAccount('Карта');
  final food = testCategory('Продукты');

  late FakeRepository repository;

  /// Everything the system asks for less motion for, so that the scanner
  /// stops breathing and settles.
  Widget calm(Widget child) => MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  );

  Future<void> sized(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = FakeRepository(
      accountList: [card],
      expenses: [testCategory('Кафе'), food],
      income: [testCategory('Зарплата', kind: CategoryKind.income)],
    );
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('quick add', () {
    var closed = 0;
    var scans = 0;

    Future<void> pump(WidgetTester tester, {QuickAddSource? source}) => sized(
      tester,
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) =>
              QuickAddCubit(repository, now: () => now, source: source),
          child: QuickAddPage(
            onClose: () => closed++,
            onAddAccount: () async {},
            onAddCategories: () async {},
            onScanReceipt: (context) async {
              scans++;
              return ReceiptQr.parse(code);
            },
          ),
        ),
      ),
    );

    setUp(() {
      closed = 0;
      scans = 0;
    });

    testWidgets('«Чек» fills the sum and the moment of the receipt', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Чек'));
      await tester.pumpAndSettle();
      expect(scans, 1);
      expect(find.text('Из чека, 09:12'), findsOneWidget);
      await tester.tap(find.text('Продукты'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('СОХРАНИТЬ · ПРОДУКТЫ'));
      await tester.pumpAndSettle();
      final draft = repository.recorded.single;
      expect(draft.receipt, groceries);
      expect(draft.entries.single.amount, rub(-62000));
      expect(draft.occurredAt, DateTime(2026, 10, 31, 9, 12));
    });

    testWidgets('the first receipt of a till says where the next ones go', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Чек'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Продукты'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('СОХРАНИТЬ · ПРОДУКТЫ'));
      await tester.pumpAndSettle();
      expect(
        find.text('Записали. Чеки этой кассы сразу пойдут в «Продукты»'),
        findsOneWidget,
      );
      expect(closed, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('a change of an operation offers no scanner', (tester) async {
      repository.operations = [
        testOperation('coffee', amount: rub(-25000), account: card),
      ];
      await pump(tester, source: const QuickAddSource.edit('coffee'));
      expect(find.text('Чек'), findsNothing);
    });
  });

  group('the scanner', () {
    final closedWith = <ReceiptQr?>[];
    final opened = <String>[];

    Future<void> pump(WidgetTester tester) => sized(
      tester,
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: calm(
          BlocProvider(
            create: (_) => ReceiptScanCubit(repository),
            child: ReceiptScannerPage(
              onClose: closedWith.add,
              onOpenOperation: opened.add,
              onOpenSettings: () {},
              preview: (context, onCode) => Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => onCode('WIFI:S:Кофейня;T:nopass;;'),
                        child: const Text('wifi'),
                      ),
                      TextButton(
                        onPressed: () => onCode(code),
                        child: const Text('receipt'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    setUp(() {
      closedWith.clear();
      opened.clear();
    });

    testWidgets('keeps looking past a code that is not a receipt', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Наведите камеру на QR-код чека'), findsOneWidget);
      await tester.tap(find.text('wifi'));
      await tester.pumpAndSettle();
      expect(find.text('Это не QR-код чека'), findsOneWidget);
      expect(closedWith, isEmpty);
    });

    testWidgets('closes with the receipt it reads', (tester) async {
      await pump(tester);
      await tester.tap(find.text('receipt'));
      await tester.pump();
      expect(find.text('Чек прочитан'), findsOneWidget);
      expect(closedWith, isEmpty);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(closedWith.single?.receipt, groceries);
      expect(closedWith.single?.sum, rub(62000));
    });

    testWidgets('opens the operation of a receipt the ledger has', (
      tester,
    ) async {
      repository.receiptOperations['7380440700076541/24611/2531297412'] =
          testOperation(
            'groceries',
            amount: rub(-62000),
            account: card,
            category: food,
            source: TransactionSource.receipt,
            receipt: groceries,
          );
      await pump(tester);
      await tester.tap(find.text('receipt'));
      await tester.pumpAndSettle();
      expect(find.text('Этот чек уже в Birka'), findsOneWidget);
      await tester.tap(find.text('ОТКРЫТЬ ОПЕРАЦИЮ'));
      await tester.pumpAndSettle();
      expect(opened, ['groceries']);
      expect(closedWith, isEmpty);
    });

    testWidgets('looks for another receipt after one the ledger has', (
      tester,
    ) async {
      repository.receiptOperations['7380440700076541/24611/2531297412'] =
          testOperation(
            'groceries',
            amount: rub(-62000),
            account: card,
            category: food,
            receipt: groceries,
          );
      await pump(tester);
      await tester.tap(find.text('receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('СКАНИРОВАТЬ ДРУГОЙ'));
      await tester.pumpAndSettle();
      expect(find.text('Этот чек уже в Birka'), findsNothing);
      expect(find.text('Наведите камеру на QR-код чека'), findsOneWidget);
    });
  });

  testWidgets('the operation shows the receipt it was made from', (
    tester,
  ) async {
    repository.operations = [
      testOperation(
        'groceries',
        amount: rub(-62000),
        account: card,
        category: food,
        at: DateTime(2026, 10, 31, 9, 12),
        note: 'Продукты у дома',
        source: TransactionSource.receipt,
        receipt: groceries,
      ),
    ];
    await sized(
      tester,
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider(
          create: (_) =>
              OperationCubit(repository, 'groceries', now: () => now),
          child: OperationPage(
            onClose: () {},
            onEdit: () {},
            onRepeat: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('Из чека'), findsOneWidget);
    expect(find.text('24611'), findsOneWidget);
    expect(find.text('7380 4407 0007 6541'), findsOneWidget);
    expect(find.text('2531297412'), findsOneWidget);
    expect(find.text('Приход'), findsOneWidget);
    expect(find.textContaining('В QR-коде нет позиций'), findsOneWidget);
  });
}
