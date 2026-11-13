import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:tags_common/tags_common.dart';
import 'package:tags_common/testing.dart';
import 'package:tags_jaspr/tags_jaspr.dart';

/// The chip that says [label].
BirkaChip chip(String label) =>
    find
            .byComponentPredicate((it) => it is BirkaChip && it.label == label)
            .evaluate()
            .single
            .component
        as BirkaChip;

/// The button that says [text].
Finder buttonOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.tag('button')).first;

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('the picker', () {
    Future<List<Set<String>>> pump(
      ComponentTester tester,
      TagPickerCubit cubit,
      Set<String> picked,
    ) async {
      final changes = <Set<String>>[];
      tester.pumpComponent(
        BlocProvider<TagPickerCubit>.value(
          value: cubit,
          child: TagPicker(picked: picked, onChanged: changes.add),
        ),
      );
      await tester.pump();
      await tester.pump();
      return changes;
    }

    testComponents('shows the метки as chips, the trips first', (
      tester,
    ) async {
      final cubit = TagPickerCubit(FakeTagsRepository());
      addTearDown(cubit.close);
      final changes = await pump(tester, cubit, {'tbilisi'});

      final labels = [
        for (final element in find.byType(BirkaChip).evaluate())
          (element.component as BirkaChip).label,
      ];
      expect(labels, ['Тбилиси', 'Стамбул', 'Ремонт кухни']);
      expect(chip('Тбилиси').selected, isTrue);
      expect(chip('Тбилиси').glyph, BirkaGlyph.plane);
      expect(chip('Ремонт кухни').glyph, BirkaGlyph.tag);
      expect(
        find.text(
          'Пока идёт поездка, её метка сама встаёт на расходы этих '
          'дней.',
        ),
        findsOneComponent,
      );

      await tester.click(buttonOf('Ремонт кухни'));
      await tester.click(buttonOf('Тбилиси'));

      expect(changes, [
        {'tbilisi', 'renovation'},
        <String>{},
      ]);
    });

    testComponents('makes a метка of the search', (tester) async {
      final repository = FakeTagsRepository();
      final cubit = TagPickerCubit(repository);
      addTearDown(cubit.close);
      final changes = await pump(tester, cubit, {'tbilisi'});

      cubit.queryChanged('Батуми');
      await tester.pump();

      expect(find.byType(BirkaChip), findsOneComponent);
      expect(chip('Новая метка «Батуми»').dashed, isTrue);

      await tester.click(buttonOf('Новая метка «Батуми»'));
      await tester.pump();

      final made = (await repository.watchTags().first).last;
      expect(made.name, 'Батуми');
      expect(changes, [
        {'tbilisi', made.id},
      ]);
    });
  });

  group('the card of an operation', () {
    Future<FakeTagsRepository> pump(
      ComponentTester tester, {
      required String operation,
    }) async {
      final repository = FakeTagsRepository(
        operations: [
          ...boardOperations(),
          expense(
            'bread',
            units(120, Currency.rub),
            boardToday.addDays(-30),
            note: 'Хлеб',
          ),
        ],
      );
      final tags = OperationTagsCubit(repository, operation);
      final picker = TagPickerCubit(repository);
      addTearDown(tags.close);
      addTearDown(picker.close);
      tester.pumpComponent(
        MultiBlocProvider(
          providers: [
            BlocProvider<OperationTagsCubit>.value(value: tags),
            BlocProvider<TagPickerCubit>.value(value: picker),
          ],
          child: OperationTagsRow(hrefOf: (id) => 'tags/#$id'),
        ),
      );
      await tester.pump();
      await tester.pump();
      return repository;
    }

    testComponents('leads from the метка it wears to its report', (
      tester,
    ) async {
      await pump(tester, operation: 'lunch');

      // The closed picker keeps its chips in the page.
      expect(find.text('Тбилиси'), findsNComponents(2));
      expect(
        find.text('Поездка · 3–12 ноября · по датам'),
        findsOneComponent,
      );
      final link =
          find
                  .ancestor(of: find.text('Тбилиси'), matching: find.tag('a'))
                  .evaluate()
                  .first
                  .component
              as DomComponent;
      expect(link.attributes?['href'], 'tags/#tbilisi');
      expect(
        (find.byType(BirkaFold).evaluate().single.component as BirkaFold).open,
        isFalse,
      );
    });

    testComponents('offers a метка and puts the one picked on at once', (
      tester,
    ) async {
      final repository = await pump(tester, operation: 'bread');

      expect(find.text('Добавить метку'), findsOneComponent);
      await tester.click(buttonOf('Добавить метку'));
      await tester.pump();
      expect(
        (find.byType(BirkaFold).evaluate().single.component as BirkaFold).open,
        isTrue,
      );

      await tester.click(buttonOf('Ремонт кухни'));
      await tester.pump();
      await tester.pump();

      expect(repository.picked['bread'], {'renovation'});
      expect(find.text('Добавить метку'), findsNothing);
      expect(find.text('Метка'), findsOneComponent);

      await tester.click(buttonOf('Готово'));
      await tester.pump();
      expect(
        (find.byType(BirkaFold).evaluate().single.component as BirkaFold).open,
        isFalse,
      );
    });
  });
}
