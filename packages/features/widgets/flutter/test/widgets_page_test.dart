import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:device_settings/device_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_screen/home_screen.dart';
import 'package:l10n/l10n.dart';
import 'package:widgets_common/widgets_common.dart';
import 'package:widgets_flutter/widgets_flutter.dart';

/// Keeps settings in memory.
final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// A home screen whose launcher adds widgets when [pins], and says so.
final class _Screen implements HomeScreen {
  _Screen({required this.pins});

  final bool pins;
  int asked = 0;
  final added = StreamController<void>.broadcast();

  @override
  Future<void> show(WidgetSnapshot snapshot) async {}

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

const today = WidgetDay(
  day: '2026-11-18',
  kind: WidgetDayKind.plan,
  label: 'Можно тратить сегодня',
  labelShort: 'Можно сегодня',
  figure: '1 124 ₽',
  minor: 112400,
  of: 'из 1 744 ₽ на день',
  ofShort: 'из 1 744 ₽',
  spent: 'Потратили 620 ₽',
  spentShort: 'потратили 620 ₽',
  share: 0.36,
);

void main() {
  late _Store store;
  late _Screen screen;
  late WidgetSums sums;
  late HomeWidgets widgets;

  Future<void> pump(WidgetTester tester, {bool pins = false}) async {
    tester.view.physicalSize = const Size(780, 3800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    store = _Store();
    screen = _Screen(pins: pins);
    sums = WidgetSums(shown: true);
    widgets = HomeWidgets(screen, sums);
    addTearDown(widgets.close);
    await widgets.show(const WidgetSnapshot(days: [today], sums: true));
    final cubit = WidgetsCubit(store, sums, widgets, screen);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider.value(
          value: cubit,
          child: WidgetsPage(onBack: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('on iPhone', () {
    testWidgets(
      'shows «Сегодня» as it is, the steps and the other ways',
      (
        tester,
      ) async {
        await pump(tester);

        expect(find.text('ВИДЖЕТЫ'), findsOneWidget);
        expect(find.text('МОЖНО ТРАТИТЬ СЕГОДНЯ'), findsOneWidget);
        expect(find.text('1 124 ₽'), findsOneWidget);
        expect(find.text('из 1 744 ₽ на день'), findsOneWidget);
        expect(find.text('Потратили 620 ₽'), findsOneWidget);
        expect(find.text('Расход'), findsOneWidget);
        expect(
          find.text('Удерживайте пустое место на экране «Домой»'),
          findsOne,
        );
        expect(find.text('Найдите Birka и выберите размер'), findsOneWidget);
        expect(find.text('Siri и Команды'), findsOneWidget);
        expect(find.text('ДОБАВИТЬ НА ГЛАВНЫЙ ЭКРАН'), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'the switch hides the amounts and says what stays',
      (
        tester,
      ) async {
        await pump(tester);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(sums.shown, isFalse);
        expect(Settings.readFrom(store).widgetSums, isFalse);
        expect(
          find.text('Вместо сумм точки, кнопки работают как раньше.'),
          findsOneWidget,
        );
        expect(find.text('из ••• ₽ на день'), findsOneWidget);
        expect(find.text('из 1 744 ₽ на день'), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'the row of «Ещё» opens the page',
      (tester) async {
        var opened = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: BirkaTheme.dark(),
            home: Scaffold(
              body: GlassListGroup(
                children: [WidgetsMoreRow(onOpen: () => opened++)],
              ),
            ),
          ),
        );

        expect(find.text('Виджеты'), findsOneWidget);
        expect(find.text('На экране «Домой» и блокировки'), findsOneWidget);
        await tester.tap(find.text('Виджеты'));
        expect(opened, 1);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  group('on Android', () {
    testWidgets(
      'adds the widget and says when the launcher did',
      (
        tester,
      ) async {
        await pump(tester, pins: true);

        expect(
          find.text('«Сегодня» — 4 × 2, «Запись» — 2 × 1'),
          findsOneWidget,
        );
        expect(find.text('Ярлык на главный экран'), findsOneWidget);
        await tester.ensureVisible(find.text('ДОБАВИТЬ НА ГЛАВНЫЙ ЭКРАН'));
        await tester.tap(find.text('ДОБАВИТЬ НА ГЛАВНЫЙ ЭКРАН'));
        await tester.pump();
        expect(screen.asked, 1);

        screen.added.add(null);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Виджет на главном экране'), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'a launcher that cannot add gets the steps',
      (tester) async {
        await pump(tester);

        expect(find.text('ДОБАВИТЬ НА ГЛАВНЫЙ ЭКРАН'), findsNothing);
        expect(find.text('Нажмите «Виджеты»'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });
}
