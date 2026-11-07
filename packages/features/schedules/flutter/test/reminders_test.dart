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

/// A calendar that answers as told.
final class FakeCalendar implements ReminderCalendar {
  ReminderAccess answer = ReminderAccess.granted;
  ReminderAccess current = ReminderAccess.unknown;
  int removed = 0;
  int settings = 0;

  @override
  Future<ReminderAccess> access() async => current;

  @override
  Future<ReminderAccess> requestAccess() async => current = answer;

  @override
  Future<void> write(List<CalendarReminder> events) async {}

  @override
  Future<void> remove() async => removed++;

  @override
  Future<void> openSettings() async => settings++;
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
      FakeChannel channel, [
      FakeCalendar? calendar,
    ]) async {
      tall(tester);
      final cubit = RemindersCubit(
        repository,
        channel,
        calendar ?? FakeCalendar(),
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

      await tester.tap(find.byType(Switch).first);
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
        find.text(
          'Удалите Birka — напоминания исчезнут вместе с ней. '
          'Календарь напомнит и без неё.',
        ),
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

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('РАЗРЕШИТЬ УВЕДОМЛЕНИЯ'));
      await tester.pumpAndSettle();
      expect(find.text('Нет доступа к уведомлениям'), findsOneWidget);
      expect(repository.reminders.notify, isFalse);

      await tester.tap(find.text('ОТМЕНА'));
      await tester.pumpAndSettle();
      expect(find.text('нет доступа к уведомлениям'), findsOneWidget);

      // Another try goes straight to where to turn them on.
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.text('Нет доступа к уведомлениям'), findsOneWidget);
      expect(find.text('Напоминания от Birka'), findsNothing);
    });

    testWidgets('keep the payments in the calendar «Birka» and remove it', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository();
      final calendar = FakeCalendar();
      await pump(tester, repository, FakeChannel(), calendar);

      expect(find.text('События в календаре'), findsOneWidget);
      expect(find.text('напомнит и без Birka'), findsOneWidget);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Birka заведёт календарь «Birka» и добавит в него регулярные '
          'платежи. Напоминать будет сам календарь — даже если удалить Birka.',
        ),
        findsOneWidget,
      );
      expect(find.text('6 платежей · напомнит в 9:00'), findsOneWidget);
      expect(find.text('Чужие события Birka не читает'), findsOneWidget);

      await tester.tap(find.text('РАЗРЕШИТЬ ДОСТУП К КАЛЕНДАРЮ'));
      await tester.pumpAndSettle();
      expect(repository.reminders.calendar, isTrue);
      expect(find.text('Платежи в календаре «Birka»'), findsOneWidget);
      expect(find.text('календарь «Birka» · 6 событий'), findsOneWidget);
      expect(find.text('Время'), findsOneWidget);
      expect(
        find.text(
          'Если календарь синхронизируется с iCloud или Google, названия и '
          'суммы платежей попадут туда.',
        ),
        findsOneWidget,
      );
      await waitForToast(tester);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Убрать календарь «Birka»?'), findsOneWidget);
      expect(
        find.text(
          'Календарь «Birka» и 6 событий в нём исчезнут с телефона, и '
          'календарь перестанет напоминать о платежах. Другие календари не '
          'изменятся.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('УБРАТЬ КАЛЕНДАРЬ'));
      await tester.pumpAndSettle();
      expect(calendar.removed, 1);
      expect(repository.reminders.calendar, isFalse);
      expect(find.text('Календарь «Birka» убран'), findsOneWidget);
      await waitForToast(tester);
    });

    testWidgets('both ways remind twice', (tester) async {
      final repository = FakeSchedulesRepository()
        ..reminders = const ReminderSettings(notify: true, calendar: true);
      await pump(tester, repository, FakeChannel());

      expect(
        find.text('О платеже напомнят дважды: Birka и календарь.'),
        findsOneWidget,
      );
    });

    testWidgets('send to the settings when the phone keeps the calendar', (
      tester,
    ) async {
      final calendar = FakeCalendar()..current = ReminderAccess.denied;
      await pump(tester, FakeSchedulesRepository(), FakeChannel(), calendar);

      expect(find.text('нет доступа к календарю'), findsOneWidget);
      expect(
        find.text(
          'Чтобы календарь напоминал, откройте ему доступ в настройках '
          'телефона.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Нет доступа к календарю'), findsOneWidget);
      expect(find.text('События в календаре'), findsOneWidget);
      await tester.tap(find.text('ОТКРЫТЬ НАСТРОЙКИ'));
      await tester.pumpAndSettle();
      expect(calendar.settings, 1);
      expect(find.text('Нет доступа к календарю'), findsNothing);
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
      String? id = 'rent',
      VoidCallback? onEnableReminders,
    }) async {
      tall(tester);
      final cubit = ScheduleFormCubit(repository, id: id);
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

    testWidgets('a new payment of today names the reminder still to come', (
      tester,
    ) async {
      final repository = FakeSchedulesRepository()
        ..reminders = const ReminderSettings(notify: true);
      await pump(tester, repository, id: null);

      // A new payment starts today, 18 November, and the day before it has
      // gone, so the first reminder comes before its next time.
      await tester.tap(find.text('За день'));
      await tester.pumpAndSettle();
      expect(find.text('17 декабря в 9:00 · напомнит Birka'), findsOneWidget);
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
