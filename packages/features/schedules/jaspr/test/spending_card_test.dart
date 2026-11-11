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
        child: const SpendingCard(
          paydayHref: 'payday/',
          listHref: 'schedules/',
        ),
      ),
    );
    await tester.pump();
  }

  testComponents('says what today may take and the nearest payments', (
    tester,
  ) async {
    await pump(tester, FakeSchedulesRepository()..history = usualDays(2100));

    expect(find.text('Можно тратить сегодня'), findsOneComponent);
    expect(find.text(nb('1 124 ₽')), findsOneComponent);
    expect(find.text('из ${nb('1 744 ₽')} на день'), findsOneComponent);
    expect(
      find.text('Потратили ${nb('620 ₽')} · до зарплаты 17 дней'),
      findsOneComponent,
    );
    expect(
      find.text('Как обычно — деньги кончатся 2 декабря'),
      findsOneComponent,
    );
    expect(find.text('Аренда'), findsOneComponent);
    expect(find.text('Интернет'), findsOneComponent);
    expect(find.text('Netflix'), findsOneComponent);
    expect(find.text('Спортзал'), findsNothing);
    expect(_hrefOf('Можно тратить сегодня'), 'payday/');
    expect(_hrefOf('Все регулярные · 6'), 'schedules/');
  });

  testComponents('asks for a payday when no income sets one', (tester) async {
    final repository = FakeSchedulesRepository(
      schedules: [
        for (final it in boardSchedules())
          if (it.id != 'pay') it,
      ],
    )..settings = const PaydaySettings();
    await pump(tester, repository);

    expect(find.text('Сколько можно тратить в день?'), findsComponents);
  });

  testComponents('stays away with no money to count', (tester) async {
    await pump(tester, FakeSchedulesRepository()..accounts = const []);

    expect(find.text('Можно тратить сегодня'), findsNothing);
  });
}
