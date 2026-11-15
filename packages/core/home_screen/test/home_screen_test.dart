import 'dart:async';
import 'dart:convert';

import 'package:home_screen/home_screen.dart';
import 'package:test/test.dart';

/// A home screen that keeps what it was shown.
final class _Screen implements HomeScreen {
  final shown = <WidgetSnapshot>[];

  @override
  Future<void> show(WidgetSnapshot snapshot) async => shown.add(snapshot);

  @override
  Future<bool> canPin() async => false;

  @override
  Future<bool> pin() async => false;

  @override
  Stream<HomeAction> get actions => const Stream.empty();

  @override
  Stream<void> get pinned => const Stream.empty();
}

WidgetDay day(String figure, {String date = '2026-11-18'}) => WidgetDay(
  day: date,
  kind: WidgetDayKind.plan,
  label: 'Можно тратить сегодня',
  labelShort: 'Можно сегодня',
  figure: figure,
  value: 1124,
  of: 'из 1 744 ₽ на день',
  ofShort: 'из 1 744 ₽',
  spent: 'Потратили 620 ₽',
  spentShort: 'потратили 620 ₽',
  share: 0.36,
);

void main() {
  test('an action comes by its name, and an unknown one is left', () {
    expect(HomeAction.named('income'), HomeAction.income);
    expect(HomeAction.named('ask'), HomeAction.ask);
    expect(HomeAction.named('lunch'), isNull);
    expect(HomeAction.named(null), isNull);
  });

  test('the widgets read the figures as version 1', () {
    final snapshot = WidgetSnapshot(days: [day('1 124 ₽')], sums: true);

    final read = jsonDecode(snapshot.encode()) as Map<String, Object?>;

    expect(read['v'], 1);
    expect(read['sums'], isTrue);
    expect(read['days'], [
      {
        'day': '2026-11-18',
        'kind': 'plan',
        'label': 'Можно тратить сегодня',
        'labelShort': 'Можно сегодня',
        'figure': '1 124 ₽',
        'value': 1124,
        'of': 'из 1 744 ₽ на день',
        'ofShort': 'из 1 744 ₽',
        'spent': 'Потратили 620 ₽',
        'spentShort': 'потратили 620 ₽',
        'share': 0.36,
      },
    ]);
  });

  test('figures are equal when they say the same', () {
    expect(
      WidgetSnapshot(days: [day('1 124 ₽')], sums: true),
      WidgetSnapshot(days: [day('1 124 ₽')], sums: true),
    );
    expect(
      WidgetSnapshot(days: [day('1 124 ₽')], sums: true),
      isNot(WidgetSnapshot(days: [day('754 ₽')], sums: true)),
    );
  });

  test('hidden amounts keep the sign and the currency', () {
    expect(maskAmounts('1 124 ₽'), '••• ₽');
    expect(maskAmounts('−356 ₽'), '−••• ₽');
    expect(maskAmounts('из 1 744 ₽ на день'), 'из ••• ₽ на день');
    expect(maskAmounts(r'$1,234.50'), r'$•••');
    expect(maskAmounts('Можно сегодня'), 'Можно сегодня');
  });

  test('new figures reach the widgets once, and the page sees them', () async {
    final screen = _Screen();
    final widgets = HomeWidgets(screen);
    addTearDown(widgets.close);
    final seen = <WidgetSnapshot>[];
    final watching = widgets.watch().listen(seen.add);
    addTearDown(watching.cancel);

    await widgets.show(WidgetSnapshot(days: [day('1 124 ₽')], sums: true));
    await widgets.show(WidgetSnapshot(days: [day('1 124 ₽')], sums: true));
    await widgets.show(WidgetSnapshot(days: [day('754 ₽')], sums: true));
    await pumpEventQueue();

    expect(screen.shown.map((it) => it.days.single.figure), [
      '1 124 ₽',
      '754 ₽',
    ]);
    expect(seen.map((it) => it.days.single.figure), ['1 124 ₽', '754 ₽']);
    expect(widgets.last?.days.single.figure, '754 ₽');
    // A page that opens later starts from the figures of now.
    expect((await widgets.watch().first).days.single.figure, '754 ₽');
  });

  test('a demo keeps its figures off the home screen', () async {
    final screen = _Screen();
    final widgets = HomeWidgets(screen, forwards: false);
    addTearDown(widgets.close);

    await widgets.show(WidgetSnapshot(days: [day('1 124 ₽')], sums: true));

    expect(screen.shown, isEmpty);
    expect(widgets.last?.days.single.figure, '1 124 ₽');
  });
}
