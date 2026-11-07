import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedule_draft.dart';

/// What the regular payments need of the ledger and of the device.
abstract interface class SchedulesRepository {
  /// Today on the calendar of this device.
  CivilDate today();

  /// The regular payments, the nearest first.
  Stream<List<Schedule>> watchSchedules();

  /// The accounts with what they hold, archived ones included.
  Stream<List<AccountBalance>> watchAccounts();

  /// The categories of [kind], archived ones included.
  Stream<List<Category>> watchCategories(CategoryKind kind);

  /// The transactions of [day].
  Stream<List<Transaction>> watchDay(CivilDate day);

  /// The currency that totals are in, or `null` to follow the first account.
  Stream<Currency?> watchBaseCurrency();

  /// The day of the calendar that the months start on (ADR 0024), now and
  /// after every change.
  Stream<int> watchMonthStart();

  /// The imports whose transactions the ledger holds, for the statements that
  /// brought the times of payments (ADR 0023).
  Stream<List<LedgerImport>> watchImports();

  /// How this device counts the money until the salary, now and after every
  /// change.
  Stream<PaydaySettings> watchSettings();

  /// Keeps [settings] on this device.
  Future<void> saveSettings(PaydaySettings settings);

  /// How this device reminds of the payments, now and after every change
  /// (ADR 0025).
  Stream<ReminderSettings> watchReminders();

  /// Keeps [settings] of the reminders on this device.
  Future<void> saveReminders(ReminderSettings settings);

  /// Adds a regular payment.
  Future<Schedule> add(ScheduleDraft draft);

  /// Puts [schedule] in place of the payment with its id.
  Future<void> update(Schedule schedule);

  /// Deletes payment [id]; the transactions it gave stay.
  Future<void> delete(String id);

  /// Records the next time of payment [id] and moves it on, and returns the
  /// id of the transaction. [amount] and [on] change what the time gives.
  Future<String> post(String id, {Money? amount, CivilDate? on});

  /// Moves payment [id] on with no transaction.
  Future<void> skip(String id);

  /// Posts what has come of the payments that post themselves, and returns
  /// the ids of the transactions.
  Future<List<String>> postDue();
}
