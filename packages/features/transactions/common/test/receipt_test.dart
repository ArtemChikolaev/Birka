import 'dart:async';

import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show TransactionSource;
import 'package:money/money.dart';
import 'package:test/test.dart';
import 'package:transactions_common/transactions_common.dart';

import 'fake_transactions_repository.dart';

const code =
    't=20261118T0912&s=620.00&fn=7380440700076541&i=24611&fp=2531297412&n=1';

const groceries = Receipt(
  drive: '7380440700076541',
  document: '24611',
  sign: '2531297412',
  kind: ReceiptKind.sale,
);

void main() {
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

  group('the QR code of a receipt', () {
    test('gives the moment, the sum and the receipt', () {
      expect(
        ReceiptQr.parse(code),
        ReceiptQr(
          at: DateTime(2026, 11, 18, 9, 12),
          sum: rub(62000),
          receipt: groceries,
        ),
      );
    });

    test('reads seconds, kopecks, any order and a link of a check', () {
      final read = ReceiptQr.parse(
        'https://check.example/?n=2&fp=2531297412&i=24611&FN=7380440700076541'
        '&s=1286.4&t=20261118T091205',
      );
      expect(read?.at, DateTime(2026, 11, 18, 9, 12, 5));
      expect(read?.sum, rub(128640));
      expect(read?.receipt.kind, ReceiptKind.saleReturn);
    });

    test('a code without the kind is a sale', () {
      final read = ReceiptQr.parse(code.replaceFirst('&n=1', ''));
      expect(read?.receipt.kind, ReceiptKind.sale);
    });

    test('is not anything else', () {
      for (final text in [
        'WIFI:S:Кофейня;T:nopass;;',
        'https://example.com/menu',
        code.replaceFirst('20261118', '20261131'),
        code.replaceFirst('T0912', 'T2460'),
        code.replaceFirst('620.00', '0.00'),
        code.replaceFirst('620.00', '620.005'),
        code.replaceFirst('7380440700076541', '73804407ABCD'),
        code.replaceFirst('&n=1', '&n=5'),
        code.replaceFirst('&s=620.00', ''),
        '',
      ]) {
        expect(ReceiptQr.parse(text), isNull, reason: text);
      }
    });

    test('a refund and a payout bring money, the others spend it', () {
      expect(ReceiptKind.sale.spends, isTrue);
      expect(ReceiptKind.saleReturn.spends, isFalse);
    });
  });

  late FakeTransactionsRepository repository;

  setUp(() {
    repository = FakeTransactionsRepository(
      accountList: [
        testAccount('lari', currency: Currency.custom('GEL', decimalDigits: 2)),
        testAccount('card'),
      ],
      expenses: [testCategory('cafe'), testCategory('food')],
      income: [testCategory('salary', kind: CategoryKind.income)],
      last: 'lari',
    );
  });

  group('the scanner', () {
    late ReceiptScanCubit scanner;

    setUp(() {
      scanner = ReceiptScanCubit(repository);
      addTearDown(scanner.close);
    });

    test('keeps looking past a code that is not a receipt', () async {
      final states = <ReceiptScanStatus>[];
      final subscription = scanner.stream.listen(
        (state) => states.add(state.status),
      );
      addTearDown(subscription.cancel);
      await scanner.codeSeen('WIFI:S:Кофейня;T:nopass;;');
      await scanner.codeSeen('WIFI:S:Кофейня;T:nopass;;');
      await Future<void>.delayed(Duration.zero);
      expect(states, [ReceiptScanStatus.notReceipt]);
      await scanner.codeSeen(code);
      expect(scanner.state.status, ReceiptScanStatus.read);
      expect(scanner.state.read?.receipt, groceries);
    });

    test('stops at the first receipt it reads', () async {
      await scanner.codeSeen(code);
      await scanner.codeSeen('WIFI:S:Кофейня;T:nopass;;');
      expect(scanner.state.status, ReceiptScanStatus.read);
    });

    test('finds a receipt the ledger already has, and looks again', () async {
      final recorded = testOperation(
        'groceries',
        amount: rub(-62000),
        source: TransactionSource.receipt,
        receipt: groceries,
      );
      repository.receiptOperations['7380440700076541/24611/2531297412'] =
          recorded;
      await scanner.codeSeen(code);
      expect(scanner.state.status, ReceiptScanStatus.twice);
      expect(scanner.state.recorded?.id, 'groceries');
      scanner.lookAgain();
      expect(scanner.state.status, ReceiptScanStatus.looking);
      await scanner.codeSeen(code);
      expect(scanner.state.status, ReceiptScanStatus.twice);
    });

    test('lets a receipt through when the ledger cannot answer', () async {
      repository.receiptFailure = Exception('closed');
      await scanner.codeSeen(code);
      expect(scanner.state.status, ReceiptScanStatus.read);
    });
  });

  group('quick add from a receipt', () {
    final now = DateTime(2026, 11, 18, 9, 30);

    setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

    Future<QuickAddCubit> open({QuickAddSource? source}) async {
      final cubit = QuickAddCubit(repository, now: () => now, source: source);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      return cubit;
    }

    test(
      'takes the sum, the moment and a ruble account of a new till',
      () async {
        final cubit = await open();
        await cubit.receiptRead(ReceiptQr.parse(code)!);
        final state = cubit.state;
        expect(state.kind, TransactionKind.expense);
        expect(state.amount, rub(62000));
        expect(state.day, CivilDate(2026, 11, 18));
        expect(state.accountId, 'card');
        expect(state.receipt, groceries);
        expect(state.receiptAt, DateTime(2026, 11, 18, 9, 12));
        expect(state.knownTill, isFalse);
        expect(state.categoryId, isNull);
        expect(state.canSave, isFalse);
        expect(
          receiptLine(state.receiptAt!, knownTill: state.knownTill),
          'Из чека, 09:12',
        );
      },
    );

    test('saves the receipt with its moment and learns the till', () async {
      final cubit = await open();
      await cubit.receiptRead(ReceiptQr.parse(code)!);
      cubit.categoryChanged('food');
      await cubit.save();
      final draft = repository.recorded.single;
      expect(draft.receipt, groceries);
      expect(draft.source, TransactionSource.receipt);
      expect(draft.occurredOn, CivilDate(2026, 11, 18));
      expect(draft.occurredAt, DateTime(2026, 11, 18, 9, 12));
      expect(cubit.state.status, QuickAddStatus.saved);
      expect(cubit.state.taughtTill, isTrue);
      expect(
        tillTaughtToast('Продукты'),
        'Записали. Чеки этой кассы сразу пойдут в «Продукты»',
      );
    });

    test(
      'a known till gives the category and the note of its last receipt',
      () async {
        repository.tills['7380440700076541'] = testOperation(
          'yesterday',
          amount: rub(-41000),
          category: testCategory('food'),
          note: 'Продукты у дома',
          source: TransactionSource.receipt,
          receipt: groceries,
        ).transaction;
        final cubit = await open();
        await cubit.receiptRead(ReceiptQr.parse(code)!);
        expect(cubit.state.categoryId, 'food');
        expect(cubit.state.note, 'Продукты у дома');
        expect(cubit.state.knownTill, isTrue);
        expect(
          receiptLine(cubit.state.receiptAt!, knownTill: true),
          'Из чека, 09:12 · знакомая касса',
        );
        await cubit.save();
        expect(repository.recorded.single.note, 'Продукты у дома');
        expect(cubit.state.taughtTill, isFalse);
      },
    );

    test('a refund comes in as an income', () async {
      final cubit = await open();
      await cubit.receiptRead(
        ReceiptQr.parse(code.replaceFirst('n=1', 'n=2'))!,
      );
      expect(cubit.state.kind, TransactionKind.income);
      cubit.categoryChanged('salary');
      await cubit.save();
      expect(repository.recorded.single.kind, TransactionKind.income);
      expect(repository.recorded.single.receipt?.kind, ReceiptKind.saleReturn);
    });

    test('another day keeps the receipt but not its moment', () async {
      final cubit = await open();
      await cubit.receiptRead(ReceiptQr.parse(code)!);
      cubit
        ..categoryChanged('food')
        ..dayChanged(CivilDate(2026, 11, 17));
      await cubit.save();
      final draft = repository.recorded.single;
      expect(draft.receipt, groceries);
      expect(draft.occurredAt, isNull);
    });

    test('a change of an operation from a receipt keeps the receipt', () async {
      final operation = testOperation(
        'groceries',
        amount: rub(-62000),
        account: testAccount('card'),
        category: testCategory('food'),
        day: CivilDate(2026, 11, 18),
        at: DateTime(2026, 11, 18, 9, 12),
        source: TransactionSource.receipt,
        receipt: groceries,
      );
      repository.operations = [operation];
      final cubit = await open(source: QuickAddSource.edit(operation.id));
      cubit.noteChanged('Продукты у дома');
      await cubit.save();
      final draft = repository.amended['groceries']!;
      expect(draft.receipt, groceries);
      expect(draft.source, TransactionSource.receipt);
      expect(cubit.state.taughtTill, isFalse);
    });

    test('the drive of a till reads in fours', () {
      expect(fiscalDriveLabel('7380440700076541'), '7380 4407 0007 6541');
      expect(fiscalDriveLabel('12345'), '1234 5');
    });
  });
}
