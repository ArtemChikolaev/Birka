import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_common/testing.dart';
import 'package:limits_jaspr/limits_jaspr.dart';
import 'package:money/money.dart';

/// [text] with the no-break spaces that formatted amounts keep: between the
/// groups of digits and before the sign of the currency.
String _nb(String text) {
  final space = String.fromCharCode(0xA0);
  return text
      .replaceAllMapped(
        RegExp(r'(\d) (?=\d)'),
        (match) => '${match[1]}$space',
      )
      .replaceAllMapped(
        RegExp(r'(\d) (?=[₽€$])'),
        (match) => '${match[1]}$space',
      );
}

/// The one element with exactly [classes].
Finder _withClasses(String classes) => find.byComponentPredicate(
  (component) => component is DomComponent && component.classes == classes,
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

/// The button around [text].
Finder _button(String text) =>
    find.ancestor(of: find.text(text), matching: find.tag('button')).first;

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late MemoryLimitsRepository repository;

  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
    repository = MemoryLimitsRepository();
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('the page', () {
    Future<void> pump(ComponentTester tester) async {
      tester.pumpComponent(
        BlocProvider(
          create: (_) => LimitsCubit(repository),
          child: LimitsPage(
            backHref: 'overview/',
            addHref: 'limits/#new',
            suggestHref: 'limits/#suggest',
            hrefOf: (id) => 'limits/#$id',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testComponents('shows what is left of each limit and the pace', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Лимиты'), findsOneComponent);
      expect(find.text('ноябрь'), findsOneComponent);
      // How many are within stands at the side and, narrow, on top.
      expect(find.text('4 из 5'), findsNComponents(2));
      expect(find.text('1 превышен'), findsNComponents(2));
      expect(find.text('13 дней'), findsNComponents(2));
      expect(find.text('с 1 декабря заново'), findsNComponents(2));
      expect(find.text(_nb('больше лимита на 1 300 ₽')), findsOneComponent);
      expect(find.text(_nb('осталось 1 850 ₽')), findsOneComponent);
      expect(find.text('В таком темпе хватит до 21 ноября'), findsOneComponent);
      expect(find.text(_nb('из 12 000 ₽')), findsOneComponent);
      expect(_hrefOf('Кафе'), 'limits/#cafe');
      expect(_hrefOf('Новый лимит'), 'limits/#new');
    });

    testComponents('offers a limit to the categories that spent without one', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Без лимита'), findsOneComponent);
      expect(find.text(_nb('6 400 ₽ в ноябре')), findsOneComponent);
      expect(
        find.text(_nb('1 997 ₽ · регулярные платежи')),
        findsOneComponent,
      );
      expect(_hrefOf('Дом'), 'limits/#home');
      expect(find.text('Поставить'), findsNComponents(3));
      expect(_hrefOf('Предложить по средним'), 'limits/#suggest');
    });

    testComponents('without limits shows both ways to set one', (
      tester,
    ) async {
      repository.categories = [
        for (final category in boardCategories) withLimit(category, null),
      ];
      await pump(tester);

      expect(find.text('Лимитов пока нет'), findsOneComponent);
      expect(_hrefOf('Предложить по средним'), 'limits/#suggest');
      expect(_hrefOf('Поставить вручную'), 'limits/#new');
    });
  });

  group('the part of the overview', () {
    void pump(ComponentTester tester) => tester.pumpComponent(
      BlocProvider(
        create: (_) => LimitsCubit(repository),
        child: const LimitsOverviewPart(
          href: 'limits/',
          suggestHref: 'limits/#suggest',
        ),
      ),
    );

    testComponents('shows the three limits that need the person most', (
      tester,
    ) async {
      pump(tester);
      // While the limits are counted the card ends with its spending.
      expect(_withClasses('birka-rule'), findsNothing);
      await tester.pump();
      await tester.pump();

      expect(_withClasses('birka-rule'), findsOneComponent);
      expect(find.text('Лимиты на ноябрь'), findsOneComponent);
      expect(find.text('превышен 1 · 13 дней'), findsOneComponent);
      expect(find.text('Досуг'), findsOneComponent);
      expect(find.text('Кафе'), findsOneComponent);
      expect(find.text('Поездки'), findsOneComponent);
      expect(find.text('Продукты'), findsNothing);
      expect(
        find.text(_nb('осталось 1 850 ₽ · хватит примерно до 21 ноября')),
        findsOneComponent,
      );
      expect(_hrefOf('Все лимиты · 5'), 'limits/');
    });

    testComponents('invites to set limits while there are none', (
      tester,
    ) async {
      repository.categories = [
        for (final category in boardCategories) withLimit(category, null),
      ];
      pump(tester);
      await tester.pump();
      await tester.pump();

      expect(find.text('Лимиты'), findsOneComponent);
      expect(_hrefOf('Предложить по средним тратам'), 'limits/#suggest');
    });
  });

  group('the form', () {
    Future<List<String>> pump(ComponentTester tester, String? id) async {
      final done = <String>[];
      tester.pumpComponent(
        BlocProvider(
          create: (_) => LimitFormCubit(repository, categoryId: id),
          child: LimitFormPage(onClose: () {}, onDone: done.add),
        ),
      );
      await tester.pump();
      await tester.pump();
      return done;
    }

    testComponents('takes the sum the average offers and sets the limit', (
      tester,
    ) async {
      final done = await pump(tester, 'home');

      expect(find.text('Новый лимит'), findsOneComponent);
      expect(find.text('Категория'), findsOneComponent);
      expect(find.text('Рубли'), findsOneComponent);
      expect(find.text('Евро'), findsOneComponent);
      // The average stands at the side and, narrow, under the fields.
      expect(find.text(_nb('6 210 ₽')), findsNComponents(2));

      await tester.click(_button(_nb('Взять 6 500 ₽')));
      await tester.pump();
      expect(find.text('округлили вверх'), findsNComponents(2));

      (find.byType(BirkaForm).evaluate().single.component as BirkaForm)
          .onSubmit!();
      await tester.pump();
      await tester.pump();

      expect(repository.setLimits.single, ('home', CategoryLimit(_rub(6500))));
      expect(done, [_nb('Лимит на «Дом» — 6 500 ₽ в месяц')]);
    });

    testComponents('a limit that is set shows its month and goes away', (
      tester,
    ) async {
      final done = await pump(tester, 'cafe');

      expect(find.text('Лимит на «Кафе»'), findsOneComponent);
      expect(find.text('Категория'), findsNothing);
      expect(
        find.text(_nb('В ноябре — 10 150 ₽ из 12 000 ₽')),
        findsNComponents(2),
      );

      await tester.click(_button('Убрать лимит'));
      await tester.pump();
      await tester.pump();

      expect(repository.setLimits.single, ('cafe', null));
      expect(done, ['Лимит на «Кафе» убрали']);
    });
  });

  group('the averages', () {
    Future<List<String>> pump(ComponentTester tester) async {
      final done = <String>[];
      tester.pumpComponent(
        BlocProvider(
          create: (_) => LimitSuggestCubit(repository),
          child: LimitSuggestPage(
            onClose: () {},
            manualHref: 'limits/#new',
            onDone: done.add,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return done;
    }

    testComponents('offers the steady categories checked and sets them', (
      tester,
    ) async {
      // The trips keep their limit in euros, as on the boards.
      repository.categories = [
        for (final category in boardCategories)
          category.id == travel.id ? category : withLimit(category, null),
      ];
      final done = await pump(tester);

      expect(find.text('Лимиты по средним'), findsOneComponent);
      expect(
        find.text('Берём три полных месяца: август, сентябрь и октябрь.'),
        findsOneComponent,
      );
      expect(
        find.text(_nb('Среднее округляем вверх до 500 ₽.')),
        findsOneComponent,
      );
      expect(find.text('Поставить 4 лимита'), findsOneComponent);

      (find
                  .byComponentPredicate(
                    (it) => it is BirkaCheckbox && it.label == 'Дом',
                  )
                  .evaluate()
                  .single
                  .component
              as BirkaCheckbox)
          .onChanged(true);
      await tester.pump();
      expect(find.text('Поставить 5 лимитов'), findsOneComponent);

      (find.byType(BirkaForm).evaluate().single.component as BirkaForm)
          .onSubmit!();
      await tester.pump();
      await tester.pump();

      expect(repository.setLimits, hasLength(5));
      expect(done, ['Поставили 5 лимитов на ноябрь']);
    });

    testComponents('without a full month says when the averages come', (
      tester,
    ) async {
      repository
        ..categories = [
          for (final category in boardCategories) withLimit(category, null),
        ]
        ..spending = [
          for (final row in boardSpending)
            if (row.day.month == 11) row,
        ];
      await pump(tester);

      expect(find.text('Пока мало истории'), findsOneComponent);
      expect(_hrefOf('Поставить вручную'), 'limits/#new');
      expect(find.text('Поставить 4 лимита'), findsNothing);
    });
  });
}
