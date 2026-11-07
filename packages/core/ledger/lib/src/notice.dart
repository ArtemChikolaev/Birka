import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/transaction.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// Where a notice comes from (ADR 0026).
enum NoticeSource {
  /// A time of a regular payment.
  payment,

  /// An import of a statement.
  import,
}

/// What became of a time of a regular payment that a notice tells of.
enum NoticeOutcome {
  /// The person posted it.
  posted,

  /// Birka posted it, as the payment posts itself.
  postedItself,

  /// The person skipped it.
  skipped,

  /// A statement brought it, so it needs no transaction of its own.
  found,
}

/// What Birka told the person on this device, which the bell of the overview
/// shows (ADR 0026). The device keeps the notices for 90 days, and neither
/// sync nor the copies of the ledger carry them.
@immutable
sealed class Notice {
  const Notice({required this.id, required this.at, this.readAt});

  /// How many days the device keeps a notice.
  static const keepDays = 90;

  /// The id.
  final String id;

  /// When it came: when Birka reminded of the time, did it or imported.
  final DateTime at;

  /// When the person read it, or `null` while it is new.
  final DateTime? readAt;

  /// Whether the person has not read it yet.
  bool get isNew => readAt == null;

  /// Where it comes from.
  NoticeSource get source;
}

/// A time of a regular payment that Birka reminded of or posted itself, with
/// what became of it since.
final class PaymentNotice extends Notice {
  /// Creates the notice of [time] of regular payment [scheduleId].
  const PaymentNotice({
    required super.id,
    required super.at,
    required this.scheduleId,
    required this.time,
    required this.name,
    required this.kind,
    required this.amount,
    super.readAt,
    this.advance = false,
    this.postsItself = false,
    this.outcome,
    this.outcomeAt,
    this.next,
  });

  /// The regular payment.
  final String scheduleId;

  /// The time of the payment that the notice tells of.
  final CivilDate time;

  /// What the payment was called at that time.
  final String name;

  /// What the payment moves: an expense, an income or a transfer.
  final TransactionKind kind;

  /// Its amount at that time.
  final Money amount;

  /// Whether the time is the advance of a salary paid in halves.
  final bool advance;

  /// Whether the payment posts itself instead of waiting for the person.
  final bool postsItself;

  /// What became of the time, or `null` while nothing has: it is still to
  /// come, or it waits for the person.
  final NoticeOutcome? outcome;

  /// When [outcome] came.
  final DateTime? outcomeAt;

  /// The next time of the payment after [outcome].
  final CivilDate? next;

  @override
  NoticeSource get source => NoticeSource.payment;

  @override
  bool operator ==(Object other) =>
      other is PaymentNotice &&
      other.id == id &&
      other.at == at &&
      other.readAt == readAt &&
      other.scheduleId == scheduleId &&
      other.time == time &&
      other.name == name &&
      other.kind == kind &&
      other.amount == amount &&
      other.advance == advance &&
      other.postsItself == postsItself &&
      other.outcome == outcome &&
      other.outcomeAt == outcomeAt &&
      other.next == next;

  @override
  int get hashCode => Object.hash(
    id,
    at,
    readAt,
    scheduleId,
    time,
    name,
    kind,
    amount,
    advance,
    postsItself,
    outcome,
    outcomeAt,
    next,
  );

  @override
  String toString() =>
      'PaymentNotice($name, $time, ${outcome?.name ?? 'open'})';
}

/// An import of a statement, with what of it the ledger holds now.
final class ImportNotice extends Notice {
  /// Creates the notice of import [importId].
  const ImportNotice({
    required super.id,
    required super.at,
    required this.importId,
    required this.fileName,
    required this.firstDay,
    required this.lastDay,
    required this.transactions,
    required this.waiting,
    super.readAt,
    this.format,
    this.undone = false,
  });

  /// The import.
  final String importId;

  /// The name of the file of the statement.
  final String fileName;

  /// The id of its known format, such as `tbank`, or `null` for columns that
  /// a person named.
  final String? format;

  /// The day of its first operation.
  final CivilDate firstDay;

  /// The day of its last operation.
  final CivilDate lastDay;

  /// How many of its transactions the ledger holds now.
  final int transactions;

  /// How many of those wait in the inbox for a category.
  final int waiting;

  /// Whether the person took the import back.
  final bool undone;

  @override
  NoticeSource get source => NoticeSource.import;

  @override
  bool operator ==(Object other) =>
      other is ImportNotice &&
      other.id == id &&
      other.at == at &&
      other.readAt == readAt &&
      other.importId == importId &&
      other.fileName == fileName &&
      other.format == format &&
      other.firstDay == firstDay &&
      other.lastDay == lastDay &&
      other.transactions == transactions &&
      other.waiting == waiting &&
      other.undone == undone;

  @override
  int get hashCode => Object.hash(
    id,
    at,
    readAt,
    importId,
    fileName,
    format,
    firstDay,
    lastDay,
    transactions,
    waiting,
    undone,
  );

  @override
  String toString() =>
      'ImportNotice($fileName, $transactions, $waiting waiting'
      '${undone ? ', undone' : ''})';
}
