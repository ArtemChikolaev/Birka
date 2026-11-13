import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';
import 'package:tags_common/testing.dart';
import 'package:tags_jaspr/tags_jaspr.dart';

/// Where the link around [text] leads.
String? hrefOf(String text) =>
    (find
                .ancestor(of: find.text(text), matching: find.tag('a'))
                .evaluate()
                .first
                .component
            as DomComponent)
        .attributes?['href'];

/// The text input under the label that says [label].
input<String> field(String label) =>
    find
            .descendant(
              of: find.ancestor(
                of: find.text(label),
                matching: find.tag('label'),
              ),
              matching: find.byType(input<String>),
            )
            .evaluate()
            .single
            .component
        as input<String>;

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

  group('the list', () {
    testComponents('puts the trip of today first and leads to its report', (
      tester,
    ) async {
      final cubit = TagsCubit(FakeTagsRepository());
      addTearDown(cubit.close);
      tester.pumpComponent(
        BlocProvider<TagsCubit>.value(
          value: cubit,
          child: TagsPage(
            addHref: 'tags/#new',
            hrefOf: (id) => 'tags/#$id',
            picked: 'tbilisi',
            side: const p([.text('beside')]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Сейчас'), findsOneComponent);
      expect(find.text('Поездки'), findsOneComponent);
      expect(find.text('Метки'), findsNComponents(2));
      expect(
        find.text('3–12 ноября · последний день · 4 операции'),
        findsOneComponent,
      );
      expect(find.text(nb('62 015 ₽')), findsOneComponent);
      expect(find.text('2–9 мая · 0 операций'), findsOneComponent);
      expect(hrefOf('Тбилиси'), 'tags/#tbilisi');
      expect(hrefOf('Ремонт кухни'), 'tags/#renovation');
      expect(find.text('beside'), findsOneComponent);
      final picked = find.byComponentPredicate(
        (it) => it is GlassListRow && it.picked,
      );
      expect(
        (picked.evaluate().single.component as GlassListRow).title,
        'Тбилиси',
      );
    });

    testComponents('offers the first метка when there is none', (
      tester,
    ) async {
      final cubit = TagsCubit(FakeTagsRepository(tags: [], operations: []));
      addTearDown(cubit.close);
      tester.pumpComponent(
        BlocProvider<TagsCubit>.value(
          value: cubit,
          child: TagsPage(addHref: 'tags/#new', hrefOf: (id) => 'tags/#$id'),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Меток пока нет'), findsOneComponent);
      expect(hrefOf('Новая метка'), 'tags/#new');
    });
  });

  testComponents('the report of a trip counts it in every currency', (
    tester,
  ) async {
    final cubit = TagReportCubit(FakeTagsRepository(), 'tbilisi');
    addTearDown(cubit.close);
    var back = 0;
    tester.pumpComponent(
      BlocProvider<TagReportCubit>.value(
        value: cubit,
        child: TagReportPage(
          onBack: () => back++,
          editHref: 'tags/#edit-tbilisi',
          closes: true,
          operations: const p([.text('the operations of the host')]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Поездка'), findsOneComponent);
    expect(find.text(nb('62 015 ₽')), findsOneComponent);
    expect(
      find.text('3–12 ноября · сегодня последний день'),
      findsOneComponent,
    );
    expect(find.text('На месте в день'), findsOneComponent);
    expect(find.text('≈ ${nb('13 GEL')}'), findsOneComponent);
    expect(find.text('2 там, 2 заранее'), findsOneComponent);
    expect(find.text('Доллары'), findsOneComponent);
    expect(find.text('2 операции на месте'), findsOneComponent);
    expect(find.text('Квартира в Сололаки, 20 октября'), findsOneComponent);
    expect(find.text('94%'), findsOneComponent);
    expect(find.text('6%'), findsOneComponent);
    expect(find.byType(ShareLine), findsNComponents(2));
    expect(find.text('the operations of the host'), findsOneComponent);
    expect(hrefOf('Изменить'), 'tags/#edit-tbilisi');

    await tester.click(find.byType(GlassIconButton));
    expect(back, 1);
  });

  group('the form', () {
    Future<List<(TagMarking, bool)>> pump(
      ComponentTester tester,
      TagFormCubit cubit,
    ) async {
      final done = <(TagMarking, bool)>[];
      tester.pumpComponent(
        BlocProvider<TagFormCubit>.value(
          value: cubit,
          child: TagFormPage(
            onClose: () {},
            onDone: (saved, {required isNew}) => done.add((saved, isNew)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return done;
    }

    testComponents('of a trip in the past says how many expenses it marks', (
      tester,
    ) async {
      final cubit = TagFormCubit(
        FakeTagsRepository()..toMark = 14,
        name: 'Казань',
      );
      addTearDown(cubit.close);
      final done = await pump(tester, cubit);

      expect(find.text('Новая метка'), findsOneComponent);
      expect(field('Название').value, 'Казань');
      expect(find.text('12 ноября'), findsOneComponent);
      expect(find.text('14 ноября'), findsOneComponent);
      expect(
        find.text(
          'За эти дни уже 14 расходов — отметим их сразу. Регулярные '
          'платежи не трогаем.',
        ),
        findsOneComponent,
      );

      await cubit.save();
      await tester.pump();

      expect(done.single.$1.marked, 14);
      expect(done.single.$2, isTrue);
    });

    testComponents('of a метка without days hides the dates', (
      tester,
    ) async {
      final cubit = TagFormCubit(FakeTagsRepository(), name: 'Новый год');
      addTearDown(cubit.close);
      final done = await pump(tester, cubit);

      await tester.click(buttonOf('Метка'));
      await tester.pump();

      final folds = find
          .byType(BirkaFold)
          .evaluate()
          .map(
            (element) => (element.component as BirkaFold).open,
          );
      expect(folds, [false, true]);
      expect(find.textContaining('Метку ставите сами'), findsOneComponent);

      await cubit.save();
      await tester.pump();
      expect(done.single.$1.tag.days, isNull);
    });

    testComponents('needs a name', (tester) async {
      final cubit = TagFormCubit(FakeTagsRepository());
      addTearDown(cubit.close);
      final done = await pump(tester, cubit);

      await cubit.save();
      await tester.pump();

      expect(find.text('Дайте метке название.'), findsOneComponent);
      expect(done, isEmpty);
    });

    testComponents('moves the last day with the first', (tester) async {
      final cubit = TagFormCubit(FakeTagsRepository(), name: 'Батуми');
      addTearDown(cubit.close);
      await pump(tester, cubit);

      final from =
          find
                  .byComponentPredicate(
                    (it) => it is BirkaDateField && it.label == 'С',
                  )
                  .evaluate()
                  .single
                  .component
              as BirkaDateField;
      from.onChanged('2026-11-20');
      await tester.pump();

      expect(
        cubit.state.days,
        TagDays(CivilDate(2026, 11, 20), CivilDate(2026, 11, 20)),
      );
      expect(find.text('20 ноября'), findsNComponents(2));
    });
  });
}
