import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/schedules_flutter.dart';

import 'fakes.dart';

/// Notifications that answer as told.
final class FakeChannel implements ReminderChannel {
  ReminderAccess answer = ReminderAccess.granted;
  ReminderAccess current = ReminderAccess.unknown;

  @override
  Future<ReminderAccess> access() async => current;

  @override
  Future<ReminderAccess> requestAccess() async => current = answer;

  @override
  Future<void> show(List<ReminderNote> notes) async {}

  @override
  Stream<ReminderTap> get opened => const Stream.empty();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  group('the reminders of «Ещё»', () {
    Future<void> pump(
      WidgetTester tester,
      FakeSchedulesRepository repository,
      FakeChannel channel,
    ) async {
      tall(tester);
      final cubit = RemindersCubit(
        repository,
        channel,
        now: () => DateTime(2026, 11, 18, 10),
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: RemindersSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> waitForToast(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    testWidgets('turn on after the sheet and the question of the phone', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository();
      await pump(tester, repository, FakeChannel());

      expect(find.text('НАПОМИНАНИЯ'), findsOneWidget);
      expect(find.text('Уведомления от Birka'), findsOneWidget);
      expect(find.text('пока Birka на телефоне'), findsOneWidget);
      expect(find.text('Время'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Напоминания от Birka'), findsOneWidget);
      expect(find.text('Аренда · ${nb('45 000 ₽')}'), findsOneWidget);
      expect(
        find.text('25 ноября, 9:00 · нажмёте — откроется платёж'),
        findsOneWidget,
      );
      expect(find.text('Живут вместе с Birka'), findsOneWidget);

      await tester.tap(find.text('РАЗРЕШИТЬ УВЕДОМЛЕНИЯ'));
      await tester.pumpAndSettle();
      expect(repository.reminders.notify, isTrue);
      expect(find.text('Birka напомнит о 6 платежах'), findsOneWidget);
      expect(find.text('6 платежей · в 9:00'), findsOneWidget);
      expect(find.text('Время'), findsOneWidget);
      expect(find.text('Суммы в напоминаниях'), findsOneWidget);
      expect(
        find.text('Удалите Birka — напоминания исчезнут вместе с ней.'),
        findsOneWidget,
      );
      await waitForToast(tester);
    });

    testWidgets('say where to turn them on when the phone refuses', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository();
      final channel = FakeChannel()..answer = ReminderAccess.denied;
      await pump(tester, repository, channel);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('РАЗРЕШИТЬ УВЕДОМЛЕНИЯ'));
      await tester.pumpAndSettle();
      expect(find.text('Нет доступа к уведомлениям'), findsOneWidget);
      expect(repository.reminders.notify, isFalse);

      await tester.tap(find.text('ПОНЯТНО'));
      await tester.pumpAndSettle();
      expect(find.text('нет доступа к уведомлениям'), findsOneWidget);

      // Another try goes straight to where to turn them on.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Нет доступа к уведомлениям'), findsOneWidget);
      expect(find.text('Напоминания от Birka'), findsNothing);
    });

    testWidgets('take another time, leave the amounts out and turn off', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository()
        ..reminders = const ReminderSettings(notify: true);
      await pump(tester, repository, FakeChannel());

      await tester.tap(find.text('Время'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20:00'));
      await tester.pumpAndSettle();
      expect(repository.reminders.minutes, 20 * 60);
      expect(find.text('6 платежей · в 20:00'), findsOneWidget);

      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();
      expect(repository.reminders.sums, isFalse);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repository.reminders.notify, isFalse);
      expect(find.text('Время'), findsNothing);
    });
  });

  group('the form of a payment', () {
    Future<void> pump(
      WidgetTester tester,
      FakeSchedulesRepository repository, {
      VoidCallback? onEnableReminders,
    }) async {
      tall(tester);
      final cubit = ScheduleFormCubit(repository, id: 'rent');
      addTearDown(cubit.close);
      await tester.pumpWidget(
        phone(
          cubit,
          ScheduleFormPage(
            onClose: () {},
            onEnableReminders: onEnableReminders,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says when the reminder comes and who sends it', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository()
        ..reminders = const ReminderSettings(notify: true);
      await pump(tester, repository);

      expect(find.text('НАПОМНИТЬ'), findsOneWidget);
      expect(find.text('25 ноября в 9:00 · напомнит Birka'), findsOneWidget);

      await tester.tap(find.text('За день'));
      await tester.pumpAndSettle();
      expect(find.text('24 ноября в 9:00 · напомнит Birka'), findsOneWidget);

      await tester.tap(find.text('Не напоминать'));
      await tester.pumpAndSettle();
      expect(find.text('Без напоминания'), findsOneWidget);
    });

    testWidgets('offers to turn the reminders on while they are off', (
      tester,
    ) async {
      var enabled = 0;
      await pump(
        tester,
        FakeSchedulesRepository(),
        onEnableReminders: () => enabled++,
      );

      expect(find.text('Напоминания выключены в «Ещё»'), findsOneWidget);
      await tester.tap(find.text('Включить напоминания'));
      expect(enabled, 1);

      await tester.tap(find.text('Не напоминать'));
      await tester.pumpAndSettle();
      expect(find.text('Включить напоминания'), findsNothing);
    });
  });
}
