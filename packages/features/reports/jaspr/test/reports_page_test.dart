import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';
import 'package:reports_jaspr/reports_jaspr.dart';

final class _FakeRepository implements ReportsRepository {
  Currency? main = Currency.rub;
  final rows = <(CategoryKind, CivilDate), List<CategoryTotal>>{};
  final totals = <CategoryKind, List<MonthTotal>>{};
  List<CivilDate> monthList = const [];
  Exception? readFailure;

  Stream<T> _read<T>(T value) => Stream.multi((controller) {
    if (readFailure case final failure?) {
      controller.addError(failure);
    } else {
      controller.add(value);
    }
  });

  @override
  Stream<Currency?> watchMainCurrency() => _read(main);

  @override
  Stream<List<CategoryTotal>> watchTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _read(rows[(kind, from)] ?? const []);

  @override
  Stream<List<MonthTotal>> watchMonthTotals(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _read(totals[kind] ?? const []);

  @override
  Future<List<CivilDate>> months() async => monthList;
}

CategoryTotal _total(
  String name,
  Money total, {
  CategoryKind kind = CategoryKind.expense,
  String? color = '#4ade80',
}) => CategoryTotal(
  Category(
    id: name,
    kind: kind,
    name: name,
    archived: false,
    sortOrder: 0,
    color: color,
  ),
  total,
);

/// Holds whether the amounts are hidden, as the host does.
class _Host extends StatefulComponent {
  const _Host({required this.child});

  final Component child;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  var _hidden = false;

  void toggle() => setState(() => _hidden = !_hidden);

  @override
  Component build(BuildContext context) => HiddenAmounts(
    hidden: _hidden,
    onToggle: toggle,
    child: component.child,
  );
}

void main() {
  const space = ' ';
  Money rub(int minorUnits) => Money(minorUnits, Currency.rub);
  final october = CivilDate(2026, 10, 1);
  final september = CivilDate(2026, 9, 1);

  late _FakeRepository repository;
  late DateTime now;

  Future<void> pump(ComponentTester tester, {String? note}) async {
    tester.pumpComponent(
      _Host(
        child: BlocProvider(
          create: (_) => ReportsCubit(repository, now: () => now),
          child: ReportsPage(note: note),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  Future<void> hideAmounts(ComponentTester tester) async {
    final host = find.byType(_Host).evaluate().single as StatefulElement;
    (host.state as _HostState).toggle();
    await tester.pump();
  }

  String classesOf(String text) {
    final element = find.ancestor(
      of: find.text(text),
      matching: find.tag('span'),
    );
    return (element.evaluate().first.component as DomComponent).classes ?? '';
  }

  List<Map<String, String>> stylesOf(String classes) => [
    for (final element
        in find
            .byComponentPredicate(
              (component) =>
                  component is DomComponent && component.classes == classes,
            )
            .evaluate())
      (element.component as DomComponent).styles?.properties ?? const {},
  ];

  setUp(() {
    now = DateTime(2026, 10, 31, 9, 30);
    repository = _FakeRepository();
    repository.rows[(CategoryKind.expense, october)] = [
      _total('Продукты', rub(2430000)),
      _total('Кафе', rub(1285000), color: '#fbbf24'),
    ];
    repository.rows[(CategoryKind.expense, september)] = [
      _total('Продукты', rub(2531250)),
      _total('Кафе', rub(951900)),
    ];
    repository.rows[(CategoryKind.income, october)] = [
      _total('Зарплата', rub(21000000), kind: CategoryKind.income),
    ];
    repository.rows[(CategoryKind.income, september)] = [
      _total('Зарплата', rub(20000000), kind: CategoryKind.income),
    ];
    repository.totals[CategoryKind.expense] = [
      MonthTotal(september, rub(3483150)),
      MonthTotal(october, rub(3715000)),
    ];
    repository.monthList = [october, september];
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('shows the month with the change against the last one', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Отчёты'), findsOneComponent);
    expect(find.text('Октябрь'), findsOneComponent);
    expect(find.byType(BirkaRing), findsOneComponent);
    expect(find.text('37${space}150$space₽'), findsOneComponent);
    expect(find.text('+7% к сентябрю'), findsOneComponent);
  });

  testComponents('the ring takes the colors of the categories', (tester) async {
    await pump(tester);

    final ring =
        find.byType(BirkaRing).evaluate().single.component as BirkaRing;
    expect(ring.slices.map((slice) => slice.color), ['#4ade80', '#fbbf24']);
    expect(ring.slices.map((slice) => slice.value), [2430000, 1285000]);
  });

  testComponents('a category without a color stays quiet', (tester) async {
    repository.rows[(CategoryKind.expense, october)] = [
      _total('Продукты', rub(100), color: null),
    ];
    await pump(tester);

    final ring =
        find.byType(BirkaRing).evaluate().single.component as BirkaRing;
    expect(ring.slices.single.color, 'var(--color-text-subtle)');
  });

  testComponents('shows each category with its change and its bar', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Продукты'), findsOneComponent);
    expect(find.text('24${space}300$space₽'), findsOneComponent);
    expect(find.text('−4%'), findsOneComponent);
    expect(find.text('Кафе'), findsOneComponent);
    expect(find.text('+35%'), findsOneComponent);
    final widths = stylesOf('reports__fill').map((styles) => styles['width']);
    expect(widths.first, '100.0%');
    expect(double.parse(widths.last!.replaceAll('%', '')), closeTo(52.9, 0.1));
  });

  testComponents('more expenses read as bad news', (tester) async {
    await pump(tester);

    expect(classesOf('+35%'), contains('amount--negative'));
    expect(classesOf('−4%'), contains('amount--positive'));
    expect(classesOf('+7% к сентябрю'), contains('amount--negative'));
  });

  testComponents('more income reads as good news', (tester) async {
    await pump(tester);

    await tap(tester, 'Доходы');

    expect(find.text('Зарплата'), findsOneComponent);
    expect(classesOf('+5%'), contains('amount--positive'));
  });

  testComponents('no change reads as neither', (tester) async {
    repository.rows[(CategoryKind.expense, september)] = [
      _total('Продукты', rub(2430000)),
      _total('Кафе', rub(1285000)),
    ];
    await pump(tester);

    expect(classesOf('0% к сентябрю'), contains('amount--muted'));
  });

  testComponents('shows the last months with their average', (tester) async {
    await pump(tester);

    expect(find.text('По месяцам'), findsOneComponent);
    expect(find.text('в среднем 36$spaceтыс.$space₽'), findsOneComponent);
    expect(find.text('Май'), findsOneComponent);
    expect(find.text('Окт'), findsOneComponent);
    expect(find.text('37k'), findsOneComponent);
    final bars =
        (find.byType(BirkaBars).evaluate().single.component as BirkaBars).bars;
    expect(bars, hasLength(6));
    expect(bars.last.highlighted, isTrue);
    expect(bars.first.highlighted, isFalse);
  });

  testComponents('another month can be picked', (tester) async {
    await pump(tester);

    await tap(tester, 'Октябрь');
    await tap(tester, 'Сентябрь');

    expect(find.text('34${space}831,50$space₽'), findsOneComponent);
    expect(find.text('Октябрь'), findsNothing);
  });

  testComponents('the chip closes the choice of a month too', (tester) async {
    await pump(tester);

    await tap(tester, 'Октябрь');
    expect(find.text('Сентябрь'), findsOneComponent);

    await tap(tester, 'Октябрь');
    expect(find.text('Сентябрь'), findsNothing);
  });

  testComponents('a month of another year says which', (tester) async {
    repository.monthList = [CivilDate(2025, 12, 1)];
    await pump(tester);

    await tap(tester, 'Октябрь');

    expect(find.text('Декабрь 2025'), findsOneComponent);
  });

  testComponents('a month with nothing says so and keeps the bars', (
    tester,
  ) async {
    now = DateTime(2026, 11, 15);
    await pump(tester);

    expect(find.text('В этом месяце расходов нет.'), findsOneComponent);
    expect(find.byType(BirkaRing), findsNothing);
    expect(find.byType(BirkaBars), findsOneComponent);
  });

  testComponents('without any operations there are no bars', (tester) async {
    repository
      ..rows.clear()
      ..totals.clear();
    await pump(tester);

    await tap(tester, 'Доходы');

    expect(find.text('В этом месяце доходов нет.'), findsOneComponent);
    expect(find.byType(BirkaBars), findsNothing);
  });

  testComponents('other currencies stand apart', (tester) async {
    repository.rows[(CategoryKind.expense, october)] = [
      _total('Продукты', rub(100)),
      _total('Кафе', Money(500, Currency.eur)),
    ];
    await pump(tester);

    expect(find.text('5$space€'), findsOneComponent);
  });

  testComponents('hidden amounts hide the figures and the average', (
    tester,
  ) async {
    await pump(tester);

    await hideAmounts(tester);

    expect(find.text('37${space}150$space₽'), findsNothing);
    expect(find.text('37k'), findsNothing);
    expect(find.text('в среднем •••$space₽'), findsOneComponent);
    expect(find.text('+35%'), findsOneComponent);
    expect(find.text('+7% к сентябрю'), findsOneComponent);
  });

  testComponents('a long total takes smaller type, unless it is hidden', (
    tester,
  ) async {
    repository.rows[(CategoryKind.expense, october)] = [
      _total('Продукты', rub(123456789)),
    ];
    await pump(tester);

    const total = '1${space}234${space}567,89$space₽';
    expect(classesOf(total), contains('text-body-strong'));

    await hideAmounts(tester);

    expect(
      find.descendant(
        of: find.byType(BirkaRing),
        matching: find.text('•••$space₽'),
      ),
      findsOneComponent,
    );
    expect(classesOf('•••$space₽'), contains('text-heading'));
  });

  testComponents('a failure offers another try', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester);

    expect(find.text('Не удалось прочитать отчёт.'), findsOneComponent);

    repository.readFailure = null;
    await tap(tester, 'Повторить');

    expect(find.byType(BirkaRing), findsOneComponent);
  });

  testComponents('says where the data lives, once it is read', (tester) async {
    repository.readFailure = Exception('disk');
    await pump(tester, note: 'Только в этом браузере');

    expect(find.text('Только в этом браузере'), findsNothing);

    repository.readFailure = null;
    await tap(tester, 'Повторить');

    expect(find.text('Только в этом браузере'), findsOneComponent);
  });

  testComponents('coming back in a new month follows the calendar', (
    tester,
  ) async {
    await pump(tester);

    now = DateTime(2026, 11, 1, 8);
    final page = find.byType(ReportsPage).evaluate().single;
    await page.read<ReportsCubit>().calendarChecked();
    await tester.pump();

    expect(find.text('Ноябрь'), findsOneComponent);
  });
}
