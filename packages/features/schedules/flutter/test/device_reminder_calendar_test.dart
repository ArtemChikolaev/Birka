import 'package:device_calendar_plus_platform_interface/device_calendar_plus_platform_interface.dart';
import 'package:device_settings/device_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/schedules_flutter.dart';

/// The settings of a device in memory.
final class MemorySettingsStore implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// The calendars of a phone in memory.
final class FakePlatform extends DeviceCalendarPlusPlatform {
  final calendars = <Map<String, dynamic>>[];
  final events = <String, ({String calendarId, String title, String? rule})>{};
  final starts = <DateTime>[];
  String status = 'granted';
  int settings = 0;
  int _ids = 0;

  @override
  Future<String?> hasPermissions() async => status;

  @override
  Future<String?> requestPermissions(bool writeOnly) async => status;

  @override
  Future<void> openAppSettings() async => settings++;

  @override
  Future<List<Map<String, dynamic>>> listCalendars() async => [...calendars];

  @override
  Future<String> createCalendar(
    String name,
    String? colorHex,
    CreateCalendarPlatformOptions? platformOptions,
  ) async {
    final id = 'calendar ${++_ids}';
    calendars.add({'id': id, 'name': name, 'colorHex': colorHex});
    return id;
  }

  @override
  Future<void> deleteCalendar(String calendarId) async {
    calendars.removeWhere((it) => it['id'] == calendarId);
    events.removeWhere((_, it) => it.calendarId == calendarId);
  }

  @override
  Future<String> createEvent(
    String? calendarId,
    String title,
    DateTime startDate,
    DateTime endDate,
    bool isAllDay,
    String? description,
    String? location,
    String? url,
    String? timeZone,
    String availability,
    String? recurrenceRule,
    List<int>? reminders,
  ) async {
    final id = 'event ${++_ids}';
    events[id] = (calendarId: calendarId!, title: title, rule: recurrenceRule);
    starts.add(startDate);
    return id;
  }

  @override
  Future<void> deleteEvent(String eventId, {int? timestamp}) async {
    if (events.remove(eventId) == null) {
      throw PlatformException(code: 'NOT_FOUND');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listEvents(
    DateTime startDate,
    DateTime endDate,
    List<String>? calendarIds,
  ) async => [
    for (final MapEntry(:key, :value) in events.entries)
      if (calendarIds?.contains(value.calendarId) ?? true)
        {
          'eventId': key,
          'instanceId': key,
          'calendarId': value.calendarId,
          'title': value.title,
          'startDate': startDate.millisecondsSinceEpoch,
          'endDate': startDate.millisecondsSinceEpoch,
          'isAllDay': false,
          'availability': 'busy',
          'status': 'confirmed',
        },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CalendarReminder event(
  String title, {
  int day = 25,
  ScheduleEvery every = ScheduleEvery.month,
  CivilDate? first,
}) => CalendarReminder(
  title: title,
  first: first ?? CivilDate(2026, 11, day),
  minutes: 9 * 60,
  every: every,
  day: day,
  early: false,
);

void main() {
  late FakePlatform platform;
  late MemorySettingsStore store;
  late DeviceReminderCalendar calendar;

  setUp(() {
    platform = FakePlatform();
    DeviceCalendarPlusPlatform.instance = platform;
    store = MemorySettingsStore();
    calendar = DeviceReminderCalendar(store);
  });

  test('only full access to the calendar counts', () async {
    expect(await calendar.access(), ReminderAccess.granted);
    platform.status = 'writeOnly';
    expect(await calendar.requestAccess(), ReminderAccess.denied);
    platform.status = 'notDetermined';
    expect(await calendar.access(), ReminderAccess.unknown);
  });

  test(
    'makes the calendar «Birka» once and leaves equal events alone',
    () async {
      await calendar.write([event('Аренда'), event('Интернет', day: 28)]);
      expect(platform.calendars.single['name'], 'Birka');
      expect(platform.calendars.single['colorHex'], '#3DDC97');
      expect(
        [for (final it in platform.events.values) it.title],
        ['Аренда', 'Интернет'],
      );

      final before = {...platform.events.keys};
      await calendar.write([event('Аренда'), event('Интернет', day: 28)]);
      expect(platform.events.keys, before);

      await calendar.write([event('Аренда · 45 000 ₽')]);
      expect(platform.calendars, hasLength(1));
      expect(
        [for (final it in platform.events.values) it.title],
        ['Аренда · 45 000 ₽'],
      );
    },
  );

  test('makes the calendar again when the person deleted it', () async {
    await calendar.write([event('Аренда')]);
    await platform.deleteCalendar(platform.calendars.single['id'] as String);

    await calendar.write([event('Аренда')]);
    expect(platform.calendars, hasLength(1));
    expect(platform.events, hasLength(1));
  });

  test(
    'takes over a calendar «Birka» left on the phone and clears it',
    () async {
      final left = await platform.createCalendar('Birka', null, null);
      await platform.createEvent(
        left,
        'Старое',
        DateTime(2026),
        DateTime(2026),
        false,
        null,
        null,
        null,
        null,
        'busy',
        null,
        null,
      );

      await calendar.write([event('Аренда')]);
      expect(platform.calendars, hasLength(1));
      expect(
        [for (final it in platform.events.values) it.title],
        ['Аренда'],
      );
    },
  );

  test(
    'a series of the 30th that starts in February starts in March',
    () async {
      await calendar.write([
        event('Кружок', day: 30, first: CivilDate(2027, 2, 28)),
      ]);
      expect(
        [for (final it in platform.events.values) it.rule],
        [null, 'FREQ=MONTHLY;BYMONTHDAY=28,29,30;BYSETPOS=-1'],
      );
      expect(platform.starts, [
        DateTime(2027, 2, 28, 9),
        DateTime(2027, 3, 30, 9),
      ]);
    },
  );

  test('removes the calendar with its events and opens the settings', () async {
    await calendar.write([event('Аренда')]);
    await calendar.remove();
    expect(platform.calendars, isEmpty);
    expect(platform.events, isEmpty);

    await calendar.openSettings();
    expect(platform.settings, 1);
  });

  test('the rules keep to the days of Birka', () {
    String rule(CalendarReminder event) => calendarRule(event).toRruleString();

    expect(rule(event('Аренда')), 'FREQ=MONTHLY;BYMONTHDAY=25');
    expect(
      rule(event('Связь', day: 31, first: CivilDate(2026, 11, 30))),
      'FREQ=MONTHLY;BYMONTHDAY=-1',
    );
    expect(
      rule(event('Кружок', day: 30)),
      'FREQ=MONTHLY;BYMONTHDAY=28,29,30;BYSETPOS=-1',
    );
    expect(
      rule(
        event(
          'Бассейн',
          every: ScheduleEvery.week,
          first: CivilDate(2026, 11, 18),
        ),
      ),
      'FREQ=WEEKLY;BYDAY=WE',
    );
    expect(
      rule(
        event(
          'Страховка',
          day: 29,
          every: ScheduleEvery.year,
          first: CivilDate(2028, 2, 29),
        ),
      ),
      'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=28,29;BYSETPOS=-1',
    );
  });
}
