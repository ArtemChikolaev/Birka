import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// How a question named the days it asks about, which tells how to call
/// them and what came right before them.
enum AskSpan {
  /// One day: `вчера`, `8 ноября`.
  day,

  /// A week from Monday to Sunday: `на прошлой неделе`.
  week,

  /// One month, from the day months start on: `в октябре`.
  month,

  /// Whole months one after another: `за 3 месяца`.
  months,

  /// A year: `в 2025 году`.
  year,

  /// The last days up to today: `за 30 дней`.
  days,

  /// Days from one date to another: `с 1 по 15 октября`.
  range,
}

/// The days that a question asks about, with both ends included (ADR 0028).
@immutable
final class AskPeriod {
  const AskPeriod._(
    this.first,
    this.last,
    this.span, {
    this.count = 1,
    this.cut = false,
  });

  /// The day [day].
  factory AskPeriod.day(CivilDate day) => AskPeriod._(day, day, AskSpan.day);

  /// The week from Monday to Sunday that [day] falls in.
  factory AskPeriod.week(CivilDate day) {
    final monday = day.addDays(1 - day.weekday);
    return AskPeriod._(monday, monday.addDays(6), AskSpan.week);
  }

  /// The month that [day] falls in, when months start on day [start] of the
  /// calendar (ADR 0024).
  factory AskPeriod.month(CivilDate day, {int start = 1}) {
    final first = day.monthStart(start);
    return AskPeriod._(
      first,
      first.addMonths(1).addDays(-1),
      AskSpan.month,
    );
  }

  /// [count] whole months, the last of them the one that [day] falls in.
  factory AskPeriod.months(CivilDate day, int count, {int start = 1}) {
    final last = AskPeriod.month(day, start: start);
    if (count <= 1) return last;
    return AskPeriod._(
      last.first.addMonths(1 - count),
      last.last,
      AskSpan.months,
      count: count,
    );
  }

  /// The year [year].
  factory AskPeriod.year(int year) =>
      AskPeriod._(CivilDate(year, 1, 1), CivilDate(year, 12, 31), AskSpan.year);

  /// The last [count] days up to [today], today included.
  factory AskPeriod.lastDays(CivilDate today, int count) => AskPeriod._(
    today.addDays(1 - count),
    today,
    AskSpan.days,
    count: count,
  );

  /// The days from [first] to [last], in whichever order they come.
  factory AskPeriod.range(CivilDate first, CivilDate last) =>
      first.compareTo(last) <= 0
      ? AskPeriod._(first, last, AskSpan.range)
      : AskPeriod._(last, first, AskSpan.range);

  /// The first day.
  final CivilDate first;

  /// The last day.
  final CivilDate last;

  /// How the question named the days.
  final AskSpan span;

  /// How many months, days or weeks [span] takes, such as 3 of `за 3 месяца`.
  final int count;

  /// Whether the period stops at today before its natural end, such as the
  /// current month, which has only the days up to today so far.
  final bool cut;

  /// How many days the period takes.
  int get days => first.daysUntil(last) + 1;

  /// Whether [day] falls in the period.
  bool contains(CivilDate day) =>
      first.compareTo(day) <= 0 && day.compareTo(last) <= 0;

  /// The period without the days after [today]: a month that is not over
  /// yet ends today, and one that has not begun stays as it is.
  AskPeriod upTo(CivilDate today) {
    if (last.compareTo(today) <= 0 || first.compareTo(today) > 0) return this;
    return AskPeriod._(first, today, span, count: count, cut: true);
  }

  /// The same stretch right before the period, for a comparison: the month
  /// before a month, and the same days of it for a month not over yet.
  AskPeriod get before {
    final whole = switch (span) {
      AskSpan.day => AskPeriod.day(first.addDays(-1)),
      AskSpan.week => AskPeriod.week(first.addDays(-7)),
      AskSpan.month => AskPeriod._(
        first.addMonths(-1),
        first.addDays(-1),
        AskSpan.month,
      ),
      AskSpan.months => AskPeriod._(
        first.addMonths(-count),
        first.addDays(-1),
        AskSpan.months,
        count: count,
      ),
      AskSpan.year => AskPeriod.year(first.year - 1),
      AskSpan.days || AskSpan.range => AskPeriod._(
        first.addDays(-days),
        first.addDays(-1),
        span,
        count: count,
      ),
    };
    if (!cut) return whole;
    final end = whole.first.addDays(days - 1);
    return AskPeriod._(
      whole.first,
      end.compareTo(whole.last) < 0 ? end : whole.last,
      span,
      count: count,
      cut: true,
    );
  }

  /// The period as plain data, for the golden tests of the parser.
  Map<String, Object> toJson() => {
    'span': span.name,
    'from': first.toString(),
    'to': last.toString(),
    if (count > 1) 'count': count,
  };

  @override
  bool operator ==(Object other) =>
      other is AskPeriod &&
      other.first == first &&
      other.last == last &&
      other.span == span &&
      other.count == count &&
      other.cut == cut;

  @override
  int get hashCode => Object.hash(first, last, span, count, cut);

  @override
  String toString() => 'AskPeriod(${span.name} $first..$last)';
}
