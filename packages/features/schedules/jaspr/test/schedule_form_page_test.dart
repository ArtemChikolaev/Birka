import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_common/testing.dart';
import 'package:schedules_jaspr/schedules_jaspr.dart';

/// The text input under the label that says [label].
input<String> _field(String label) =>
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

/// The one element with exactly [classes].
Finder _withClasses(String classes) => find.byComponentPredicate(
  (component) => component is DomComponent && component.classes == classes,
);

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  /// The form of [cubit], and what it said once it was done.
  Future<List<String?>> pump(
    ComponentTester tester,
    ScheduleFormCubit cubit, {
    void Function()? onClose,
  }) async {
    final done = <String?>[];
    tester.pumpComponent(
      BlocProvider<ScheduleFormCubit>.value(
        value: cubit,
        child: ScheduleFormPage(onClose: onClose ?? () {}, onDone: done.add),
      ),
    );
    await tester.pump();
    await tester.pump();
    return done;
  }

  testComponents('a new payment takes a name and an amount and saves', (
    tester,
  ) async {
    final repository = FakeSchedulesRepository();
    final cubit = ScheduleFormCubit(repository);
    final done = await pump(tester, cubit);

    expect(find.text('Новый платёж'), findsOneComponent);
    expect(_field('Название').attributes?['placeholder'], 'Например, Аренда');
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('Сумма'), matching: find.tag('label')),
        matching: find.text('₽'),
      ),
      findsOneComponent,
    );
    expect(
      find.text('Появится в «Ближайших платежах» и в «Можно тратить сегодня»'),
      findsOneComponent,
    );

    _field('Название').onInput!('Аренда');
    _field('Сумма').onInput!('45 000');
    await tester.pump();
    expect(cubit.state.valid, isTrue);

    await cubit.save();
    await tester.pump();

    final draft = repository.added.single;
    expect(draft.name, 'Аренда');
    expect(draft.amount, rub(45000));
    expect(draft.kind, TransactionKind.expense);
    expect(draft.next, boardToday);
    expect(done, [null]);
  });

  testComponents('a day the month lacks stays the day of the payment', (
    tester,
  ) async {
    final cubit = ScheduleFormCubit(FakeSchedulesRepository());
    await pump(tester, cubit);
    BirkaSelect<int> day() =>
        find
                .byComponentPredicate(
                  (it) => it is BirkaSelect<int> && it.label == 'Какого числа',
                )
                .evaluate()
                .single
                .component
            as BirkaSelect<int>;

    // November has no 31st: the payment comes on the 30th and stays the 31st.
    day().onChanged(31);
    await tester.pump();

    expect(day().selected, 31);
    expect(cubit.state.next, CivilDate(2026, 11, 30));
  });

  testComponents('a wide page shows the payment as the list will', (
    tester,
  ) async {
    final cubit = ScheduleFormCubit(FakeSchedulesRepository(), id: 'rent');
    await pump(tester, cubit);

    expect(find.text('В списке платежей'), findsOneComponent);
    expect(find.text('каждый месяц 25-го · спросить'), findsOneComponent);
    expect(find.text('Следующие разы'), findsOneComponent);
    expect(
      find.text('25 ноября · 25 декабря · 25 января 2027'),
      findsOneComponent,
    );
    expect(
      find.text('Изменится со следующего раза: 25 ноября'),
      findsOneComponent,
    );
    expect(
      find.descendant(
        of: _withClasses('birka-split__aside'),
        matching: find.text('В списке платежей'),
      ),
      findsOneComponent,
    );
  });

  testComponents('what came every month opens with its days and its range', (
    tester,
  ) async {
    final repository = FakeSchedulesRepository()..operations = boardFinds();
    final cubit = ScheduleFormCubit(repository, from: 'zhku-11');
    final done = await pump(tester, cubit);
    if (cubit.state.found == null) {
      await cubit.stream.firstWhere((state) => state.found != null);
      await tester.pump();
    }

    // The same card stands at the side of a wide page and on top of a
    // narrow one.
    expect(find.text('Нашли в операциях · 3 раза'), findsNComponents(2));
    expect(_withClasses('birka-wide-only'), findsNComponents(2));
    expect(_withClasses('birka-narrow-only'), findsOneComponent);
    expect(
      find.text(
        'последняя сумма · бывало от ${nb('6 410 ₽')} до ${nb('7 120 ₽')}',
      ),
      findsOneComponent,
    );

    await cubit.save();
    await tester.pump();
    expect(done, ['Добавили в регулярные: «ЖКУ Москва»']);
  });

  testComponents('a salary in halves shows its month and its two days', (
    tester,
  ) async {
    final cubit = ScheduleFormCubit(halvesRepository(), id: 'pay');
    await pump(tester, cubit);

    expect(find.text('Сумма в месяц'), findsOneComponent);
    expect(
      find.text('по ${nb('60 000 ₽')} авансом и зарплатой'),
      findsOneComponent,
    );
    expect(find.text('Аванс'), findsComponents);
    expect(find.text('аванс, 20 ноября, пт'), findsOneComponent);
    expect(
      _withClasses('birka-fold birka-fold--open'),
      findsNComponents(2),
    );
  });

  testComponents('a changed payment can be deleted after a question', (
    tester,
  ) async {
    final repository = FakeSchedulesRepository();
    final cubit = ScheduleFormCubit(repository, id: 'gym');
    final done = await pump(tester, cubit);

    await tester.click(
      find.ancestor(
        of: find.text('Удалить платёж'),
        matching: find.tag('button'),
      ),
    );
    await tester.pump();
    expect(find.text('Удалить «Спортзал»?'), findsOneComponent);

    await tester.click(
      find
          .ancestor(
            of: find.text('Удалить платёж'),
            matching: find.tag('button'),
          )
          .first,
    );
    await tester.pump();
    await tester.pump();

    expect(repository.deleted, ['gym']);
    expect(done, ['Удалили «Спортзал»']);
  });

  testComponents('the cross closes the form', (tester) async {
    var closed = 0;
    await pump(
      tester,
      ScheduleFormCubit(FakeSchedulesRepository()),
      onClose: () => closed++,
    );

    await tester.click(
      find.byComponentPredicate(
        (component) =>
            component is DomComponent &&
            component.attributes?['aria-label'] == 'Закрыть',
      ),
    );
    expect(closed, 1);
  });
}
