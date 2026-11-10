import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_common/testing.dart';
import 'package:schedules_jaspr/schedules_jaspr.dart';

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

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  /// The page on [repository] as the site has it.
  Future<void> pump(
    ComponentTester tester,
    FakeSchedulesRepository repository,
  ) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => SchedulesCubit(repository),
        child: SchedulesPage(
          backHref: 'overview/',
          addHref: 'schedules/#new',
          paydayHref: 'payday/',
          hrefOf: (id) => 'schedules/#$id',
          findHref: (id) => 'schedules/#from-$id',
        ),
      ),
    );
    await tester.pump();
  }

  testComponents('lists the next 30 days and every payment', (tester) async {
    await pump(tester, FakeSchedulesRepository());

    expect(find.text('Регулярные платежи'), findsOneComponent);
    expect(find.text('Ближайший 25 ноября · 6 платежей'), findsOneComponent);
    expect(find.text('Ближайшие 30 дней'), findsOneComponent);
    expect(find.text('до 5 декабря ${nb('−49 949 ₽')}'), findsOneComponent);
    expect(find.text('Все регулярные · 6'), findsOneComponent);
    expect(
      find.text(
        'К зарплате 5 декабря на счетах останется ≈ ${nb('39 651 ₽')}, если '
        'не считать ежедневных трат.',
      ),
      findsOneComponent,
    );
    expect(find.text('25'), findsOneComponent);
    expect(find.text('ноя · ср'), findsOneComponent);
    expect(_hrefOf('Аренда'), 'schedules/#rent');
    // A narrow page adds with a round button, a wide one with a word.
    expect(
      find.descendant(
        of: _withClasses('schedules__add--wide'),
        matching: find.text('Новый платёж'),
      ),
      findsOneComponent,
    );
  });

  testComponents('beside the list says what a day may spend, and how', (
    tester,
  ) async {
    await pump(tester, FakeSchedulesRepository());

    expect(
      _withClasses('birka-split birka-split--wide-aside'),
      findsOneComponent,
    );
    expect(find.text('Можно тратить в день'), findsOneComponent);
    expect(find.text(nb('1 744 ₽')), findsOneComponent);
    expect(find.text('до зарплаты 5 декабря · 17 дней'), findsOneComponent);
    expect(
      find.text('Платежи до зарплаты уже вычтены: ${nb('−49 949 ₽')}.'),
      findsOneComponent,
    );
    expect(_hrefOf('Можно тратить в день'), 'payday/');
    expect(find.text('Как это устроено'), findsOneComponent);
    expect(find.tag('li'), findsNComponents(4));
  });

  testComponents('a payment that waits today goes with a word', (
    tester,
  ) async {
    final repository = FakeSchedulesRepository(
      schedules: [schedule('rent', 'Аренда', 45000, boardToday)],
    );
    await pump(tester, repository);

    expect(find.text('Ждёт подтверждения'), findsOneComponent);
    expect(find.text('Аренда · сегодня'), findsOneComponent);
    expect(
      find.text('Сегодня 18 ноября · 1 ждёт подтверждения'),
      findsOneComponent,
    );

    await tester.click(
      find.ancestor(of: find.text('Провести'), matching: find.tag('button')),
    );
    await tester.pump();

    expect(repository.posted, ['rent']);
    expect(
      find.text('Провели «Аренда» · ${nb('−45 000 ₽')}'),
      findsOneComponent,
    );
  });

  testComponents('what came every month opens a form of its latest', (
    tester,
  ) async {
    await pump(tester, FakeSchedulesRepository()..history = boardFinds());

    expect(find.text('Похоже на регулярные · 3'), findsOneComponent);
    expect(find.text('около 10-го · 3 раза'), findsOneComponent);
    expect(find.text(nb('≈ −6 800 ₽')), findsOneComponent);
    expect(_hrefOf('ЖКУ Москва'), 'schedules/#from-zhku-11');
  });

  testComponents('✕ keeps a find away until «Вернуть» brings it back', (
    tester,
  ) async {
    final repository = FakeSchedulesRepository()..history = boardFinds();
    await pump(tester, repository);

    await tester.click(
      find.byComponentPredicate(
        (component) =>
            component is DomComponent &&
            component.attributes?['aria-label'] ==
                'Не регулярный: Облако Mail.ru',
      ),
    );
    await tester.pump();

    expect(find.text('Облако Mail.ru'), findsNothing);
    expect(find.text('Похоже на регулярные · 2'), findsOneComponent);
    expect(
      find.text('Не будем предлагать «Облако Mail.ru»'),
      findsOneComponent,
    );

    await tester.click(
      find.ancestor(of: find.text('Вернуть'), matching: find.tag('button')),
    );
    await tester.pump();

    expect(find.text('Облако Mail.ru'), findsOneComponent);
    expect(find.text('Похоже на регулярные · 3'), findsOneComponent);
  });

  testComponents('with no payment yet offers to add one', (tester) async {
    await pump(tester, FakeSchedulesRepository(schedules: const []));

    expect(find.text('Регулярных платежей пока нет'), findsOneComponent);
    expect(find.text('Пока ни одного'), findsOneComponent);
    expect(_hrefOf('Добавить платёж'), 'schedules/#new');
    expect(find.byType(GlassSteps), findsOneComponent);
  });
}
