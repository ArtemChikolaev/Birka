import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// How the line under a notice in the history reads (ADR 0026): it went
/// through, it waits for the person, it was skipped or taken back, or it only
/// tells something. A new notice reads plainly: it is news.
enum NoticeTone {
  /// It only tells something.
  plain,

  /// It went through.
  done,

  /// It waits for the person.
  waits,

  /// It was skipped or taken back.
  left,
}

/// Where a tap on a notice leads.
enum NoticePlace {
  /// The regular payments, where a time that waits is posted or skipped.
  schedules,

  /// One regular payment, which a reminder of the day before opens.
  schedule,

  /// The inbox, where the operations of an import wait for a category.
  inbox,

  /// The card of a debt, which its day opens (ADR 0029).
  debt,
}

/// `Аренда · 45 000 ₽`, `Срок сегодня · Маша, 3 000 ₽` or `Альфа-Банк ·
/// ноябрь`: what [notice] is about on [today]. A time of a payment reads as
/// the reminders name it (ADR 0025), the day of a debt by the person and what
/// was owed then (ADR 0029), and an import by its bank and its months.
String noticeTitle(Notice notice, {required CivilDate today}) =>
    switch (notice) {
      PaymentNotice(:final name, :final advance, :final amount, :final kind) =>
        '${advance ? t.schedules.advance : name} · '
            '${paymentAmount(amount, income: kind == TransactionKind.income)}',
      DebtNotice(:final name, :final owed, :final due) =>
        due == today
            ? t.notifications.debtTitleToday(
                name: name,
                amount: formatMoney(owed),
              )
            : t.notifications.debtTitle(name: name, amount: formatMoney(owed)),
      ImportNotice(
        :final format,
        :final fileName,
        :final firstDay,
        :final lastDay,
      ) =>
        t.notifications.importTitle(
          bank: t.imports.formats[format] ?? fileName,
          period: _period(firstDay, lastDay, thisYear: today.year),
        ),
    };

/// The line under [notice] on [today] with its tone. A [fresh] one says
/// when its time comes or came, as the reminder did; one in the history
/// says what became of it.
(String, NoticeTone) noticeLine(
  Notice notice, {
  required CivilDate today,
  bool fresh = false,
}) => switch (notice) {
  PaymentNotice() => _paymentLine(notice, today: today, fresh: fresh),
  DebtNotice() => _debtLine(notice, today: today, fresh: fresh),
  ImportNotice(undone: true) => (
    t.notifications.importUndone,
    NoticeTone.left,
  ),
  ImportNotice(:final waiting, :final transactions) when waiting > 0 => (
    t.notifications.importWaiting(
      n: waiting,
      count: formatCount(transactions),
    ),
    NoticeTone.waits,
  ),
  ImportNotice(:final transactions) => (
    t.notifications.importAdded(
      n: transactions,
      count: formatCount(transactions),
    ),
    NoticeTone.plain,
  ),
};

(String, NoticeTone) _paymentLine(
  PaymentNotice notice, {
  required CivilDate today,
  required bool fresh,
}) {
  final time = notice.time;
  switch (notice.outcome) {
    case NoticeOutcome.posted:
      final at = notice.outcomeAt ?? notice.at;
      final sameDay =
          CivilDate.of(at.toLocal()) == CivilDate.of(notice.at.toLocal());
      return (
        sameDay
            ? t.notifications.posted(time: clockOf(at))
            : t.notifications.postedOn(
                date: _date(CivilDate.of(at.toLocal()), today),
              ),
        NoticeTone.done,
      );
    case NoticeOutcome.postedItself:
      return (t.notifications.postedItself, NoticeTone.done);
    case NoticeOutcome.skipped:
      final next = notice.next;
      return (
        next == null
            ? t.notifications.waits
            : t.notifications.skipped(date: _date(next, today)),
        NoticeTone.left,
      );
    case NoticeOutcome.found:
      return (t.notifications.found, NoticeTone.done);
    case null:
      if (time.compareTo(today) > 0) {
        final date = _date(time, today);
        return (
          time == today.addDays(1)
              ? t.notifications.tomorrow(date: date)
              : date,
          NoticeTone.plain,
        );
      }
      if (notice.postsItself) {
        return (
          time == today ? t.notifications.postsToday : t.notifications.posts,
          NoticeTone.plain,
        );
      }
      // The day of an earlier time stands beside a new notice already.
      return (
        fresh && time == today
            ? t.notifications.waitsToday
            : t.notifications.waits,
        NoticeTone.waits,
      );
  }
}

/// The line under the day of a debt (ADR 0029): the day its round came back
/// to nought, a part that came back since, or what is owed. A [fresh] one
/// that nothing happened to says what the debt is for and since when, as
/// its card does.
(String, NoticeTone) _debtLine(
  DebtNotice notice, {
  required CivilDate today,
  required bool fresh,
}) {
  final lent = notice.side == DebtSide.lent;
  if (notice.gone) return (t.notifications.debtGone, NoticeTone.left);
  if (notice.settledOn case final day?) {
    final date = _dayWord(day, today);
    return (
      lent
          ? t.notifications.debtReturned(date: date)
          : t.notifications.debtRepaid(date: date),
      NoticeTone.done,
    );
  }
  final left = notice.left ?? notice.owed;
  final amount = formatMoney(left);
  if (left.minorUnits < notice.owed.minorUnits) {
    return (
      lent
          ? t.notifications.debtReturnedPart(left: amount)
          : t.notifications.debtRepaidPart(left: amount),
      NoticeTone.waits,
    );
  }
  final note = notice.note.trim();
  if (fresh && notice.since != null) {
    final date = _date(notice.since!, today);
    return (
      note.isEmpty
          ? t.notifications.debtSince(date: date)
          : t.notifications.debtNoteSince(note: note, date: date),
      NoticeTone.plain,
    );
  }
  if (fresh && note.isNotEmpty) return (note, NoticeTone.plain);
  return (
    lent
        ? t.notifications.debtWaits(left: amount)
        : t.notifications.debtWaitsRepaid(left: amount),
    NoticeTone.waits,
  );
}

/// `сегодня`, `вчера` or `2 ноября`: [day] in a line on [today].
String _dayWord(CivilDate day, CivilDate today) {
  if (day == today) return t.notifications.today;
  if (day == today.addDays(-1)) return t.notifications.yesterday;
  return _date(day, today);
}

/// Where a tap on [notice] leads on [today], with the id of its payment or
/// its debt, or `null` when nothing is there to open.
({NoticePlace place, String? id})? noticePlace(
  Notice notice, {
  required CivilDate today,
}) => switch (notice) {
  PaymentNotice(outcome: null, :final time, :final scheduleId)
      when time.compareTo(today) > 0 =>
    (place: NoticePlace.schedule, id: scheduleId),
  PaymentNotice() => (place: NoticePlace.schedules, id: null),
  DebtNotice(gone: false, :final debtId) => (
    place: NoticePlace.debt,
    id: debtId,
  ),
  DebtNotice() => null,
  ImportNotice(undone: false, :final waiting) when waiting > 0 => (
    place: NoticePlace.inbox,
    id: null,
  ),
  ImportNotice() => null,
};

/// `9:14` or `вчера`: when [notice] came, as a new one says it on [today];
/// the history says only the time, as its day stands above it.
String noticeMoment(Notice notice, {required CivilDate today}) {
  final day = CivilDate.of(notice.at.toLocal());
  if (day == today) return clockOf(notice.at);
  if (day == today.addDays(-1)) return t.notifications.yesterday;
  return _date(day, today);
}

/// `Сегодня`, `Вчера` or `5 ноября`: the heading of [day] in the history on
/// [today].
String noticeDayHeading(CivilDate day, {required CivilDate today}) {
  if (day == today) return t.transactions.today;
  if (day == today.addDays(-1)) return t.transactions.yesterday;
  return _date(day, today);
}

/// `9:14`: the time of [moment] on the clock of this device, as the
/// reminders say it.
String clockOf(DateTime moment) {
  final local = moment.toLocal();
  return '${local.hour}:${local.minute.toString().padLeft(2, '0')}';
}

String _date(CivilDate day, CivilDate today) => dateLabel(
  year: day.year,
  month: day.month,
  day: day.day,
  thisYear: today.year,
);

/// `ноябрь`, `октябрь – ноябрь` or `декабрь 2025 – январь`: the months of a
/// statement, with the year of a month outside [thisYear].
String _period(CivilDate first, CivilDate last, {required int thisYear}) {
  String month(CivilDate day) {
    final name = t.notifications.months[day.month - 1];
    return day.year == thisYear ? name : '$name ${day.year}';
  }

  final sameMonth = first.year == last.year && first.month == last.month;
  return sameMonth ? month(last) : '${month(first)} – ${month(last)}';
}
