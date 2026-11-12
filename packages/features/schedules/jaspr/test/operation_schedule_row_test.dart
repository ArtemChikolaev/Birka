import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_common/testing.dart';
import 'package:schedules_jaspr/schedules_jaspr.dart';

/// The subscription of the board, which the statement of the card brought on
/// 12 November and which no payment has yet.
Transaction plus({List<Allocation>? allocations}) => Transaction(
  id: 'plus',
  kind: TransactionKind.expense,
  occurredOn: CivilDate(2026, 11, 12),
  note: 'Яндекс Плюс',
  status: TransactionStatus.cleared,
  source: TransactionSource.import,
  entries: [Entry(accountId: 'card', amount: -rub(449))],
  allocations:
      allocations ?? [Allocation(categoryId: 'home', amount: rub(449))],
);

/// Where the link around [text] leads.
String? _hrefOf(String text) =>
    (find
                .ancestor(of: find.text(text), matching: find.tag('a'))
                .evaluate()
                .first
                .component
            as DomComponent)
        .attributes?['href'];

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  Future<FakeSchedulesRepository> pump(
    ComponentTester tester, {
    Transaction? operation,
  }) async {
    final repository = FakeSchedulesRepository()
      ..operations = [operation ?? plus()];
    tester.pumpComponent(
      BlocProvider(
        create: (_) => OperationScheduleCubit(repository, 'plus'),
        child: OperationScheduleRow(
          makeHref: 'schedules/#from-plus',
          hrefOf: (id) => 'schedules/#$id',
        ),
      ),
    );
    await tester.pump();
    return repository;
  }

  testComponents('offers to make the operation a payment on its day', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Сделать регулярным'), findsOneComponent);
    expect(find.text('Повторять каждый месяц 12-го'), findsOneComponent);
    expect(_hrefOf('Сделать регулярным'), 'schedules/#from-plus');
    expect(find.byType(GlyphBadge), findsOneComponent);
  });

  testComponents('leads to its payment once it is one', (tester) async {
    final repository = await pump(tester);

    await repository.add(
      ScheduleDraft(
        kind: TransactionKind.expense,
        name: 'Яндекс Плюс',
        accountId: 'card',
        amount: rub(449),
        every: ScheduleEvery.month,
        next: CivilDate(2026, 12, 12),
        madeFrom: 'plus',
      ),
    );
    await tester.pump();

    expect(find.text('Регулярный платёж'), findsOneComponent);
    expect(find.text('Яндекс Плюс · каждый месяц 12-го'), findsOneComponent);
    final id = repository.schedules
        .singleWhere((schedule) => schedule.madeFrom == 'plus')
        .id;
    expect(_hrefOf('Регулярный платёж'), 'schedules/#$id');
  });

  testComponents('stays away for a split', (tester) async {
    await pump(
      tester,
      operation: plus(
        allocations: [
          Allocation(categoryId: 'home', amount: rub(300)),
          Allocation(categoryId: 'fun', amount: rub(149)),
        ],
      ),
    );

    expect(find.text('Сделать регулярным'), findsNothing);
    expect(find.byType(GlassListRow), findsNothing);
  });
}
