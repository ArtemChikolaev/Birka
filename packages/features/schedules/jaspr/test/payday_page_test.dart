import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_common/testing.dart';
import 'package:schedules_jaspr/schedules_jaspr.dart';

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

  Future<void> pump(
    ComponentTester tester,
    FakeSchedulesRepository repository,
  ) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => SchedulesCubit(repository),
        child: PaydayPage(
          backHref: 'overview/',
          salaryHref: (id) => 'schedules/#$id',
          addSalaryHref: 'schedules/#salary',
        ),
      ),
    );
    await tester.pump();
  }

  testComponents('shows the sum in the open', (tester) async {
    await pump(tester, FakeSchedulesRepository());

    expect(find.text('Деньги до зарплаты'), findsOneComponent);
    expect(find.text('${nb('1 744 ₽')} в день'), findsOneComponent);
    expect(find.text('до зарплаты 5 декабря · 17 дней'), findsOneComponent);
    expect(find.text(nb('89 600 ₽')), findsOneComponent);
    expect(find.text('4 платежа до зарплаты'), findsOneComponent);
    expect(find.text(nb('−49 949 ₽')), findsOneComponent);
    expect(find.text(nb('−10 000 ₽')), findsOneComponent);
    expect(find.text('Остаётся на 17 дней'), findsOneComponent);
    expect(find.text(nb('29 651 ₽')), findsOneComponent);
    expect(find.text('из платежа «Зарплата»'), findsOneComponent);
    expect(_hrefOf('5-е число'), 'schedules/#pay');
  });

  testComponents('says what becomes of the money at the usual pace', (
    tester,
  ) async {
    await pump(tester, FakeSchedulesRepository()..history = usualDays(2100));

    expect(find.text('Если тратить как обычно'), findsOneComponent);
    expect(find.text('Деньги кончатся 2 декабря'), findsOneComponent);
    expect(
      find.text(
        'Обычно вы тратите ≈ ${nb('2 100 ₽')} в день, а можно '
        '${nb('1 744 ₽')}. К 5 декабря не хватит ≈ ${nb('6 000 ₽')}.',
      ),
      findsOneComponent,
    );
    expect(find.text('5 дек · зарплата'), findsOneComponent);
    expect(find.text('по плану: ${nb('1 744 ₽')} в день'), findsOneComponent);
  });

  testComponents('keeps what is typed aside', (tester) async {
    final repository = FakeSchedulesRepository();
    await pump(tester, repository);

    final field =
        find
                .descendant(
                  of: find.ancestor(
                    of: find.text('Отложить до зарплаты'),
                    matching: find.tag('label'),
                  ),
                  matching: find.byType(input<String>),
                )
                .evaluate()
                .single
                .component
            as input<String>;
    expect(field.value, '10000');
    field.onInput!('5000');
    await tester.pump();

    expect(repository.settings.asideMinor, 500000);
  });

  testComponents('with no account yet says what it will count', (
    tester,
  ) async {
    await pump(tester, FakeSchedulesRepository()..accounts = const []);

    expect(find.text('Сколько можно тратить в день?'), findsOneComponent);
  });
}
