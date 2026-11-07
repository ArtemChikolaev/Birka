import 'dart:async';

import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/schedule_draft.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';

/// Keeps the regular payments in the ledger, which holds their rules, and the
/// settings of the money until the salary on the [_store] of the device.
final class LedgerSchedulesRepository implements SchedulesRepository {
  /// Creates a repository. [now] tells the time in tests.
  LedgerSchedulesRepository(
    this._ledger,
    this._baseCurrency,
    this._store, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _settings = PaydaySettings.read(_store);

  final LedgerRepository _ledger;
  final BaseCurrency _baseCurrency;
  final SettingsStore _store;
  final DateTime Function() _now;
  PaydaySettings _settings;
  final _changes = StreamController<PaydaySettings>.broadcast();

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
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

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
  Future<Schedule> add(ScheduleDraft draft) => _ledger.addSchedule(
    kind: draft.kind,
    name: draft.name.trim(),
    accountId: draft.accountId,
    toAccountId: draft.toAccountId,
    categoryId: draft.categoryId,
    amount: draft.amount,
    every: draft.every,
    next: draft.next,
    onDay: draft.onDay,
    reminder: draft.reminder,
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
}
