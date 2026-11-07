import 'package:design_flutter/design_flutter.dart' show BirkaTokens;
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';

/// The calendar of the phone, through `device_calendar_plus` (ADR 0025).
///
/// Birka keeps a calendar of its own, «Birka», with a recurring event for
/// each series of a payment that reminds. An event starts at the time of the
/// reminders and rings at its start, or a day before. The id of the calendar,
/// the ids of the events and what was written stay in [_store], so that an
/// equal plan leaves the calendar alone.
final class DeviceReminderCalendar implements ReminderCalendar {
  /// Creates the calendar on [_store], with [plugin] in tests.
  DeviceReminderCalendar(this._store, [DeviceCalendar? plugin])
    : _plugin = plugin ?? DeviceCalendar.instance;

  final SettingsStore _store;
  final DeviceCalendar _plugin;

  /// The name of the calendar, the same in every language.
  static const name = 'Birka';

  static const _calendarKey = 'remind-calendar-id';
  static const _eventsKey = 'remind-calendar-events';
  static const _planKey = 'remind-calendar-plan';

  /// How long an event lasts, as on the boards: 9:00–9:15.
  static const _length = Duration(minutes: 15);

  @override
  Future<ReminderAccess> access() async =>
      _accessOf(await _plugin.hasPermissions());

  @override
  Future<ReminderAccess> requestAccess() async =>
      _accessOf(await _plugin.requestPermissions());

  /// Full access only: without it Birka could not change or delete its own
  /// events, so writing alone counts as none.
  static ReminderAccess _accessOf(CalendarPermissionStatus status) =>
      switch (status) {
        CalendarPermissionStatus.granted => ReminderAccess.granted,
        CalendarPermissionStatus.notDetermined => ReminderAccess.unknown,
        _ => ReminderAccess.denied,
      };

  @override
  Future<void> write(List<CalendarReminder> events) async {
    final plan = [for (final event in events) _signature(event)].join('\n');
    final (calendarId, fresh) = await _calendar();
    if (!fresh && _store.read(_planKey) == plan) return;
    for (final id in _events()) {
      await _forget(id);
    }
    final ids = <String>[];
    for (final event in events) {
      for (final (first, rule) in _parts(event)) {
        final start = DateTime(
          first.year,
          first.month,
          first.day,
          event.minutes ~/ 60,
          event.minutes % 60,
        );
        ids.add(
          await _plugin.createEvent(
            calendarId: calendarId,
            title: event.title,
            startDate: start,
            endDate: start.add(_length),
            recurrenceRule: rule,
            reminders: [
              if (event.early) const Duration(days: 1) else Duration.zero,
            ],
          ),
        );
      }
    }
    await _store.write(_eventsKey, ids.join(','));
    await _store.write(_planKey, plan);
  }

  @override
  Future<void> remove() async {
    final id = _store.read(_calendarKey);
    if (id != null && id.isNotEmpty) {
      final calendars = await _plugin.listCalendars();
      if (calendars.any((it) => it.id == id)) {
        await _plugin.deleteCalendar(id);
      }
    }
    await _store.write(_calendarKey, '');
    await _store.write(_eventsKey, '');
    await _store.write(_planKey, '');
  }

  @override
  Future<void> openSettings() => _plugin.openAppSettings();

  /// The calendar «Birka», and whether its events are unknown: when it was
  /// made just now, or found after Birka came back to the phone. A calendar
  /// found so keeps the events of the Birka of before, and they go.
  Future<(String, bool)> _calendar() async {
    final calendars = await _plugin.listCalendars();
    final stored = _store.read(_calendarKey);
    if (calendars.any((it) => it.id == stored)) return (stored!, false);
    final left = calendars.where((it) => it.name == name && !it.readOnly);
    final String id;
    if (left.firstOrNull case final calendar?) {
      id = calendar.id;
      await _clear(id);
    } else {
      id = await _plugin.createCalendar(name: name, colorHex: _accent);
    }
    await _store.write(_calendarKey, id);
    await _store.write(_eventsKey, '');
    return (id, true);
  }

  /// Deletes the events of calendar [id] from two years back to two years on,
  /// where every series of a payment has a time.
  Future<void> _clear(String id) async {
    final now = DateTime.now();
    final events = await _plugin.listEvents(
      DateTime(now.year - 2, now.month),
      DateTime(now.year + 2, now.month),
      calendarIds: [id],
    );
    for (final eventId in {for (final event in events) event.eventId}) {
      await _forget(eventId);
    }
  }

  /// Deletes event [id], which the person may have deleted already.
  Future<void> _forget(String id) async {
    try {
      await _plugin.deleteEvent(eventId: id);
    } on DeviceCalendarException catch (error) {
      if (error.errorCode != DeviceCalendarError.notFound) rethrow;
    }
  }

  /// The events of the phone that make [event]: its series, from its first
  /// time and with its rule. A calendar of the phone drops the days of a rule
  /// that the month of its first time lacks, so a monthly series of the 29th
  /// or the 30th whose first time falls on the last day of a shorter month
  /// starts the month after, and that first time is an event of its own.
  static List<(CivilDate, RecurrenceRule?)> _parts(CalendarReminder event) {
    final first = event.first;
    final rule = calendarRule(event);
    if (event.every == ScheduleEvery.month &&
        event.day > 28 &&
        event.day < 31 &&
        first.day < event.day) {
      final next = CivilDate.onDay(first.year, first.month + 1, event.day);
      return [(first, null), (next, rule)];
    }
    return [(first, rule)];
  }

  List<String> _events() => [
    for (final id in (_store.read(_eventsKey) ?? '').split(','))
      if (id.isNotEmpty) id,
  ];

  static String _signature(CalendarReminder event) => [
    event.title,
    event.first,
    event.minutes,
    event.every.name,
    event.day,
    event.early,
  ].join('|');

  /// The accent of Birka as `#RRGGBB`, the color of its calendar.
  static String get _accent {
    final rgb = (BirkaTokens.colorAccent & 0xFFFFFF).toRadixString(16);
    return '#${rgb.padLeft(6, '0').toUpperCase()}';
  }
}

/// The rule of [event] in the calendar: every week, every month on its day,
/// or every year in the month of its first time and on its day. A shorter
/// month gets its last day, as the rules of Birka do: the 31st is the last
/// day of every month, and the 29th or the 30th is the last of the days from
/// the 28th up to it.
RecurrenceRule calendarRule(CalendarReminder event) {
  final day = event.day;
  final (days, last) = switch (day) {
    >= 31 => (const [-1], null),
    > 28 => ([for (var it = 28; it <= day; it++) it], const [-1]),
    _ => ([day], null),
  };
  return switch (event.every) {
    ScheduleEvery.week => WeeklyRecurrence(
      daysOfWeek: [DayOfWeek.values[event.first.weekday - 1]],
    ),
    ScheduleEvery.month => MonthlyRecurrence(
      daysOfMonth: days,
      setPositions: last,
    ),
    ScheduleEvery.year => YearlyRecurrence(
      months: [event.first.month],
      daysOfMonth: days,
      setPositions: last,
    ),
  };
}
