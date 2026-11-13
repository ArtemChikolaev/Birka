import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show CivilDate, TagMark;
import 'package:money/money.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

import 'fake_repository.dart';

void main() {
  final card = testAccount('Карта');
  final cafe = testCategory('Кафе');

  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('lists the latest days of a метка and then every day', (
    tester,
  ) async {
    final repository = FakeRepository(
      accountList: [card],
      expenses: [cafe],
      operations: [
        for (var day = 12; day >= 7; day--)
          testOperation(
            'lunch-$day',
            amount: Money(-50000, Currency.rub),
            account: card,
            category: cafe,
            day: CivilDate(2026, 11, day),
            note: 'Обед $day',
            tags: {'tbilisi': TagMark.days},
          ),
        testOperation(
          'bread',
          amount: Money(-12000, Currency.rub),
          account: card,
          day: CivilDate(2026, 11, 12),
        ),
      ],
    );
    final cubit = TagOperationsCubit(
      repository,
      'tbilisi',
      now: () => DateTime(2026, 11, 12, 18),
    );
    addTearDown(cubit.close);
    tester.pumpComponent(
      BlocProvider<TagOperationsCubit>.value(
        value: cubit,
        child: TagOperations(hrefOf: (id) => 'operations/#$id'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Обед 12'), findsOneComponent);
    expect(find.text('Обед 10'), findsOneComponent);
    expect(find.text('Обед 9'), findsNothing);
    expect(find.text('Хлеб'), findsNothing);
    final link =
        find
                .ancestor(of: find.text('Обед 12'), matching: find.tag('a'))
                .evaluate()
                .first
                .component
            as DomComponent;
    expect(link.attributes?['href'], 'operations/#lunch-12');

    await tester.click(
      find
          .ancestor(
            of: find.text('Все 6 операций'),
            matching: find.tag('button'),
          )
          .first,
    );
    await tester.pump();

    expect(find.text('Обед 7'), findsOneComponent);
    expect(find.byType(BirkaChip), findsNothing);
  });
}
