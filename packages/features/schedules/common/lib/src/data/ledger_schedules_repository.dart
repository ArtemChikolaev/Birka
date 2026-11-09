import 'dart:async';
import 'dart:convert';

import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedule_draft.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';

/// Keeps the regular payments in the ledger, which holds their rules, and the
/// settings of the money until the salary and the dismissed finds on the
/// [_store] of the device.
final class LedgerSchedulesRepository implements SchedulesRepository {
  /// Creates a repository. [now] tells the time in tests.
  LedgerSchedulesRepository(
    this._ledger,
    this._baseCurrency,
    this._monthStart,
    this._store, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _settings = PaydaySettings.read(_store),
       _reminders = ReminderSettings.read(_store),
       _dismissed = _readDismissed(_store);

  final LedgerRepository _ledger;
  final BaseCurrency _baseCurrency;
  final MonthStart _monthStart;
  final SettingsStore _store;
  final DateTime Function() _now;
  PaydaySettings _settings;
  final _changes = StreamController<PaydaySettings>.broadcast();
  ReminderSettings _reminders;
  final _reminderChanges = StreamController<ReminderSettings>.broadcast();
  Set<String> _dismissed;
  final _dismissedChanges = StreamController<Set<String>>.broadcast();

  /// Where the keys of the dismissed finds stay, as a list in JSON. They
  /// belong to this device and leave it in no copy.
  static const _dismissedKey = 'schedule-finds-dismissed';

  static Set<String> _readDismissed(SettingsStore store) {
    final raw = store.read(_dismissedKey);
    if (raw == null) return const {};
    try {
      return {for (final key in jsonDecode(raw) as List<Object?>) '$key'};
    } on Object {
      return const {};
    }
  }

  @override
  CivilDate today() => CivilDate.of(_now());

  @override
  Stream<List<Schedule>> watchSchedules() => _ledger.watchSchedules();

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _ledger.watchAccountBalances(includeArchived: true);

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      _ledger.watchCategories(kind, includeArchived: true);

  @override
  Stream<List<Transaction>> watchDay(CivilDate day) =>
      _ledger.watchTransactions(from: day, to: day, limit: null);

  @override
  Stream<Transaction?> watchTransaction(String id) =>
      _ledger.watchTransaction(id);

  @override
  Stream<List<Transaction>> watchHistory(CivilDate from) =>
      _ledger.watchTransactions(from: from, limit: null);

  @override
  Stream<Set<String>> watchDismissedFinds() => Stream.multi((controller) {
    controller.add(_dismissed);
    final subscription = _dismissedChanges.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> dismissFind(String key, {bool dismissed = true}) async {
    final keys = {..._dismissed};
    dismissed ? keys.add(key) : keys.remove(key);
    _dismissed = keys;
    _dismissedChanges.add(keys);
    await _store.write(_dismissedKey, jsonEncode(keys.toList()..sort()));
  }

  @override
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

  @override
  Stream<int> watchMonthStart() => _monthStart.watch();

  @override
  Stream<List<LedgerImport>> watchImports() => _ledger.watchImports();

  @override
  Stream<PaydaySettings> watchSettings() => Stream.multi((controller) {
    controller.add(_settings);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> saveSettings(PaydaySettings settings) async {
    _settings = settings;
    _changes.add(settings);
    await settings.write(_store);
  }

  @override
  Stream<ReminderSettings> watchReminders() => Stream.multi((controller) {
    controller.add(_reminders);
    final subscription = _reminderChanges.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> saveReminders(ReminderSettings settings) async {
    _reminders = settings;
    _reminderChanges.add(settings);
    await settings.write(_store);
  }

  @override
  Future<Schedule> add(ScheduleDraft draft) => _ledger.addSchedule(
    kind: draft.kind,
    name: draft.name.trim(),
    accountId: draft.accountId,
    toAccountId: draft.toAccountId,
    categoryId: draft.categoryId,
    amount: draft.amount,
    every: draft.every,
    next: draft.next,
    day: draft.day,
    advanceDay: draft.advanceDay,
    advanceAmount: draft.advanceAmount,
    onDay: draft.onDay,
    reminder: draft.reminder,
    madeFrom: draft.madeFrom,
  );

  @override
  Future<void> update(Schedule schedule) => _ledger.updateSchedule(schedule);

  @override
  Future<void> delete(String id) => _ledger.deleteSchedule(id);

  @override
  Future<String> post(String id, {Money? amount, CivilDate? on}) =>
      _ledger.postSchedule(id, amount: amount, on: on);

  @override
  Future<void> skip(String id) => _ledger.skipSchedule(id);

  @override
  Future<List<String>> postDue() => _ledger.postDueSchedules(today());

  @override
  Future<void> noteReminders(List<PlannedReminder> reminders) =>
      _ledger.noteReminders([
        for (final reminder in reminders)
          (
            scheduleId: reminder.schedule.id,
            time: reminder.on,
            at: reminder.at,
          ),
      ]);
}
