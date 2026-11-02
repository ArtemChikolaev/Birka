import 'package:backup_common/src/domain/operations_csv.dart';
import 'package:backup_common/src/presentation/backup_cubit.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// When a copy was made, for people: `сегодня, 21:40`, `вчера, 21:40` or
/// `28 октября, 21:40`, on the clock of this device.
String copyMomentLabel(DateTime moment, {required DateTime now}) {
  final local = moment.toLocal();
  final today = now.toLocal();
  final time = timeLabel(local);
  final days = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
  return switch (days) {
    0 => t.backup.todayAt(time: time),
    1 => t.backup.yesterdayAt(time: time),
    _ => t.backup.dayAt(
      day: copyDayLabel(moment, now: now),
      time: time,
    ),
  };
}

/// The day a copy was made: `28 октября`, with the year when it is not the
/// year of [now]. Its words stay on one line, so that a message never breaks
/// between the day and its month.
String copyDayLabel(DateTime moment, {required DateTime now}) {
  final local = moment.toLocal();
  return dateLabel(
    year: local.year,
    month: local.month,
    day: local.day,
    thisYear: now.toLocal().year,
  ).replaceAll(' ', '\u00A0');
}

/// The line under the name of a copy on offer:
/// `28 октября, 21:40 · 1 190 операций · 6 счетов`.
String offerLabel(CopyOffer offer, {required DateTime now}) {
  final LedgerCopy(:madeAt, :counts) = offer.copy;
  return [
    t.backup.dayAt(
      day: copyDayLabel(madeAt, now: now),
      time: timeLabel(madeAt),
    ),
    t.backup.operationsCount(
      n: counts.transactions,
      count: formatCount(counts.transactions),
    ),
    t.backup.accountsCount(
      n: counts.accounts,
      count: formatCount(counts.accounts),
    ),
  ].join(' · ');
}

/// What [notice] says.
String noticeLabel(BackupNotice notice, {required DateTime now}) =>
    switch (notice) {
      CopySaved(:final fileName) => t.backup.saved(name: fileName),
      CopyRestored(:final madeAt) => t.backup.restored(
        day: copyDayLabel(madeAt, now: now),
      ),
      OperationsExported(:final fileName) => t.backup.exported(name: fileName),
      LedgerWiped() => t.backup.wiped,
      CopyRefused(problem: LedgerCopyProblem.notACopy) => t.backup.notACopy,
      CopyRefused(problem: LedgerCopyProblem.newer) => t.backup.newer,
      CopyRefused(problem: LedgerCopyProblem.damaged) => t.backup.damaged,
      BackupFailed() => t.backup.failed,
    };

/// The language of a table of operations: the one of the app.
CsvLanguage csvLanguage() {
  final csv = t.backup.csv;
  return CsvLanguage(
    separator: LocaleSettings.currentLocale == AppLocale.ru ? ';' : ',',
    decimalMark: decimalSeparator,
    headings: [
      csv.date,
      csv.kind,
      csv.amount,
      csv.currency,
      csv.account,
      csv.category,
      csv.subcategory,
      csv.note,
    ],
    kinds: {
      TransactionKind.expense: csv.expense,
      TransactionKind.income: csv.income,
      TransactionKind.transfer: csv.transfer,
      TransactionKind.adjustment: csv.adjustment,
    },
  );
}
