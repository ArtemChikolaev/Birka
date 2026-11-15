import 'dart:async';

import 'package:device_settings/device_settings.dart';
import 'package:home_screen/home_screen.dart';
import 'package:test/test.dart';
import 'package:widgets_common/widgets_common.dart';

/// Keeps settings in memory.
final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// A home screen whose launcher can add widgets, and says when it did.
final class _Screen implements HomeScreen {
  _Screen({this.pins = true});

  final bool pins;
  final shown = <WidgetSnapshot>[];
  int asked = 0;
  final added = StreamController<void>.broadcast();

  @override
  Future<void> show(WidgetSnapshot snapshot) async => shown.add(snapshot);

  @override
  Future<bool> canPin() async => pins;

  @override
  Future<bool> pin() async {
    asked++;
    return pins;
  }

  @override
  Stream<HomeAction> get actions => const Stream.empty();

  @override
  Stream<void> get pinned => added.stream;
}

WidgetSnapshot snapshotOf(String figure) => WidgetSnapshot(
  sums: true,
  days: [
    WidgetDay(
      day: '2026-11-18',
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
    ),
  ],
);

void main() {
  late _Store store;
  late WidgetSums sums;
  late _Screen screen;
  late HomeWidgets widgets;

  WidgetsCubit open() {
    final cubit = WidgetsCubit(store, sums, widgets, screen);
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() async {
    store = _Store();
    sums = WidgetSums(shown: true);
    screen = _Screen();
    widgets = HomeWidgets(screen, sums);
    await widgets.show(snapshotOf('1 124 ₽'));
  });

  tearDown(() => widgets.close());

  test('opens on the figures of now, and follows them', () async {
    final cubit = open();
    await pumpEventQueue();

    expect(cubit.state.today?.figure, '1 124 ₽');
    expect(cubit.state.sums, isTrue);
    expect(cubit.state.canPin, isTrue);

    await widgets.show(snapshotOf('754 ₽'));
    await pumpEventQueue();
    expect(cubit.state.today?.figure, '754 ₽');
  });

  test('the switch hides the amounts at once and is kept', () async {
    final cubit = open();
    await pumpEventQueue();

    await cubit.sumsChanged(shown: false);
    await pumpEventQueue();

    expect(cubit.state.sums, isFalse);
    expect(sums.shown, isFalse);
    expect(Settings.readFrom(store).widgetSums, isFalse);
    // The page keeps the figures to blur; the home screen gets dots.
    expect(cubit.state.today?.figure, '1 124 ₽');
    expect(screen.shown.last.days.single.figure, '••• ₽');
  });

  test('asks the launcher, and counts what it added', () async {
    final cubit = open();
    await pumpEventQueue();

    await cubit.pin();
    screen.added.add(null);
    await pumpEventQueue();

    expect(screen.asked, 1);
    expect(cubit.state.pinned, 1);
  });

  test('a launcher that cannot add says so', () async {
    screen = _Screen(pins: false);
    widgets = HomeWidgets(screen, sums);
    final cubit = open();
    await pumpEventQueue();

    expect(cubit.state.canPin, isFalse);
  });
}
