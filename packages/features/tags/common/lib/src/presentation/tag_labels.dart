import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/src/domain/tag_report.dart';

/// The days of a trip for people: `3–12 ноября`, `28 октября — 3 ноября`, with
/// the year when it is not [thisYear].
String daysLabel(TagDays days, {required int thisYear}) {
  final first = days.first;
  final last = days.last;
  final to = _date(last, thisYear);
  if (first == last) return to;
  if (first.year == last.year && first.month == last.month) {
    return t.tags.days(from: first.day, to: to);
  }
  final sameYear = first.year == last.year;
  return t.tags.daysApart(
    from: _date(first, sameYear ? first.year : thisYear),
    to: to,
  );
}

/// What the row of a метка in the list says under its name on [today]: how
/// far a trip has come, the days of another trip, or how many operations
/// wear a метка without days.
String shelfLine(TagSummary summary, {required CivilDate today}) {
  final days = summary.tag.days;
  if (days == null) return t.tags.operations(n: summary.count);
  if (days.contains(today)) {
    if (today == days.last) return t.tags.lastDay;
    return t.tags.dayOf(
      day: days.first.daysUntil(today) + 1,
      total: days.length,
    );
  }
  final label = daysLabel(days, thisYear: today.year);
  if (today.compareTo(days.first) < 0) {
    return '$label · ${t.tags.inDays(n: today.daysUntil(days.first))}';
  }
  return label;
}

/// The same line with the days and the operations together, for a wide
/// list: `3–12 ноября · последний день · 46 операций`.
String wideShelfLine(TagSummary summary, {required CivilDate today}) {
  final days = summary.tag.days;
  final count = t.tags.operations(n: summary.count);
  if (days == null) return count;
  final label = daysLabel(days, thisYear: today.year);
  if (days.contains(today)) {
    final where = today == days.last
        ? t.tags.lastDay.toLowerCase()
        : t.tags.dayOf(
            day: days.first.daysUntil(today) + 1,
            total: days.length,
          );
    return [label, where, count].join(' · ');
  }
  if (today.compareTo(days.first) < 0) {
    return '$label · ${t.tags.inDays(n: today.daysUntil(days.first))}';
  }
  return '$label · $count';
}

/// What the line under the total of a report says of [report] on [today]:
/// the days of a trip and how far it has come, or the days that the
/// operations of a метка without days span.
String reportLine(TagReport report, {required CivilDate today}) {
  final days = report.tag.days;
  if (days != null) {
    final label = daysLabel(days, thisYear: today.year);
    if (today == days.last) return '$label · ${t.tags.report.todayLast}';
    if (days.contains(today)) {
      final day = t.tags.dayOf(
        day: days.first.daysUntil(today) + 1,
        total: days.length,
      );
      return '$label · ${day.toLowerCase()}';
    }
    if (today.compareTo(days.first) < 0) {
      return '$label · ${t.tags.inDays(n: today.daysUntil(days.first))}';
    }
    return label;
  }
  final first = report.first;
  final last = report.last;
  if (first == null || last == null) return t.tags.operations(n: 0);
  return daysLabel(TagDays(first, last), thisYear: today.year);
}

String _date(CivilDate day, int thisYear) => dateLabel(
  year: day.year,
  month: day.month,
  day: day.day,
  thisYear: thisYear,
);
