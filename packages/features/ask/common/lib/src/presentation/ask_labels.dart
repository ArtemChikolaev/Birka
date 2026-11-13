import 'package:ask_common/src/domain/ask_answer.dart';
import 'package:ask_common/src/domain/ask_period.dart';
import 'package:ask_common/src/domain/ask_query.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// What a plaque of «Понял так» stands for.
enum AskChipKind {
  /// Which money: `Траты`.
  side,

  /// A category.
  category,

  /// A метка or a trip.
  tag,

  /// An account.
  account,

  /// Words of the note.
  words,

  /// A bound of the amount.
  amount,

  /// The days, which a tap changes.
  period,
}

/// A plaque of «Понял так»: one part of what the question was read as.
@immutable
final class AskChip {
  /// Creates a plaque that says [label].
  const AskChip(this.kind, this.label, {this.category, this.tag});

  /// What it stands for.
  final AskChipKind kind;

  /// What it says.
  final String label;

  /// The category of a plaque of [AskChipKind.category].
  final Category? category;

  /// The метка of a plaque of [AskChipKind.tag].
  final Tag? tag;
}

/// The names that the plaques and titles of an answer need.
@immutable
final class AskNames {
  /// Creates the names.
  const AskNames({
    this.categories = const {},
    this.tags = const {},
    this.accounts = const {},
  });

  /// The categories by id.
  final Map<String, Category> categories;

  /// The метки by id.
  final Map<String, Tag> tags;

  /// The accounts by id.
  final Map<String, Account> accounts;
}

/// The plaques of [query]: the money, what it keeps, its bounds and its
/// days.
List<AskChip> askChips(
  AskQuery query,
  AskNames names, {
  required CivilDate today,
}) {
  final period = query.period;
  final tag = names.tags[query.tagId];
  return [
    AskChip(AskChipKind.side, sideLabel(query.side)),
    for (final id in query.categoryIds)
      if (names.categories[id] case final category?)
        AskChip(AskChipKind.category, category.name, category: category),
    if (tag != null) AskChip(AskChipKind.tag, tagLabel(tag, today), tag: tag),
    if (names.accounts[query.accountId] case final account?)
      AskChip(AskChipKind.account, account.name),
    for (final word in query.words)
      AskChip(AskChipKind.words, t.ask.word(word: word)),
    if (query.above case final above?)
      AskChip(AskChipKind.amount, t.ask.above(amount: formatMoney(above))),
    if (query.below case final below?)
      AskChip(AskChipKind.amount, t.ask.below(amount: formatMoney(below))),
    if (period != null)
      AskChip(AskChipKind.period, periodLabel(period, today: today))
    else if (tag == null)
      AskChip(AskChipKind.period, t.ask.allTime),
  ];
}

/// `Траты` or `Доходы`.
String sideLabel(AskSide side) => switch (side) {
  AskSide.expenses => t.ask.side.expenses,
  AskSide.income => t.ask.side.income,
};

/// The name of [tag], with the days of a trip: `Тбилиси · 3–12 ноября`.
String tagLabel(Tag tag, CivilDate today) {
  final days = tag.days;
  if (days == null) return tag.name;
  return '${tag.name} · ${daysLabel(days.first, days.last, today: today)}';
}

/// The days from [first] to [last] for people: `3–12 ноября`, or
/// `28 октября — 3 ноября`, with the year when it is not the one of
/// [today].
String daysLabel(CivilDate first, CivilDate last, {required CivilDate today}) {
  final to = _date(last, today.year);
  if (first == last) return to;
  if (first.year == last.year && first.month == last.month) {
    return t.ask.period.days(from: first.day, to: to);
  }
  final sameYear = first.year == last.year;
  return t.ask.period.daysApart(
    from: _date(first, sameYear ? first.year : today.year),
    to: to,
  );
}

String _date(CivilDate date, int thisYear) => dateLabel(
  year: date.year,
  month: date.month,
  day: date.day,
  thisYear: thisYear,
);

/// The name of [period] on its plaque: `Этот месяц`, `Октябрь 2026`,
/// `Авг – Окт`, `1–15 октября`.
String periodLabel(AskPeriod period, {required CivilDate today}) {
  final first = period.first;
  switch (period.span) {
    case AskSpan.day:
      if (first == today) return t.ask.period.today;
      if (first == today.addDays(-1)) return t.ask.period.yesterday;
      return _date(first, today.year);
    case AskSpan.week:
      if (period.contains(today)) return t.ask.period.thisWeek;
      if (period.contains(today.addDays(-7))) return t.ask.period.lastWeek;
      return daysLabel(first, period.last, today: today);
    case AskSpan.month:
      if (period.contains(today)) return t.ask.period.thisMonth;
      return '${t.transactions.monthNames[first.month - 1]} ${first.year}';
    case AskSpan.months:
      // The last month starts a month before the day after the period.
      final last = period.last.addDays(1).addMonths(-1);
      final from = t.reports.monthsShort[first.month - 1];
      final to = t.reports.monthsShort[last.month - 1];
      if (first.year == last.year) {
        return t.ask.period.months(from: from, to: to);
      }
      return t.ask.period.months(
        from: '$from ${first.year}',
        to: '$to ${last.year}',
      );
    case AskSpan.year:
      return '${first.year}';
    case AskSpan.days:
      return t.ask.period.lastDays(n: period.count);
    case AskSpan.range:
      return daysLabel(first, period.last, today: today);
  }
}

/// What a choice of the sheet of periods says under its name, such as the
/// days of the month so far: `1–12 ноября`. `null` when the name says it all.
String? periodLine(AskPeriod period, {required CivilDate today}) =>
    switch (period.span) {
      AskSpan.month when period.contains(today) || period.first.day != 1 =>
        daysLabel(period.first, period.last, today: today),
      AskSpan.months => t.ask.period.months(
        from: t.transactions.monthNames[period.first.month - 1],
        to: t
            .transactions
            .monthNames[period.last.addDays(1).addMonths(-1).month - 1]
            .toLowerCase(),
      ),
      AskSpan.year when period.contains(today) => t.ask.period.sinceYear,
      _ => null,
    };

/// What the total of [period] is set against: `к сентябрю`, `к 1–12
/// октября`, `к тем же дням 2025`.
String beforeLabel(AskPeriod period, {required CivilDate today}) {
  final before = period.before;
  return switch (period.span) {
    AskSpan.month when !period.cut => t.reports.against[before.first.month - 1],
    AskSpan.year when period.cut => t.ask.before.year(year: before.first.year),
    AskSpan.year => t.ask.before.wholeYear(year: before.first.year),
    AskSpan.week => t.ask.before.week,
    AskSpan.day => t.ask.before.day(day: _date(before.first, today.year)),
    _ => t.ask.before.days(
      period: daysLabel(before.first, before.last, today: today),
    ),
  };
}

/// What a bar of an answer says under it: the day, the days of a week, the
/// short name of a month or a year.
String barLabel(AskBar bar) => switch (bar.span) {
  AskBarSpan.day => '${bar.first.day}',
  AskBarSpan.week =>
    bar.first == bar.last
        ? '${bar.first.day}'
        : t.ask.period.days(from: bar.first.day, to: bar.last.day),
  AskBarSpan.month => t.reports.monthsShort[bar.first.month - 1],
  AskBarSpan.year => '${bar.first.year}',
};

/// The title of the card of an answer: what it counts and when, as
/// `Кафе · Октябрь 2026`.
String answerTitle(
  AskQuery query,
  AskNames names, {
  required CivilDate today,
}) {
  final tag = names.tags[query.tagId];
  final what = [
    for (final id in query.categoryIds)
      if (names.categories[id] case final category?) category.name,
  ];
  final above = query.above;
  final subject = what.isNotEmpty
      ? what.join(', ')
      : tag?.name ??
            (above != null
                ? t.ask.above(amount: formatMoney(above))
                : sideLabel(query.side));
  final period = query.period;
  if (period != null) {
    return t.ask.answer.of(
      what: subject,
      when: periodLabel(period, today: today),
    );
  }
  final days = tag?.days;
  if (days != null) {
    return t.ask.answer.of(
      what: subject,
      when: daysLabel(days.first, days.last, today: today),
    );
  }
  return t.ask.answer.everything(what: subject);
}

/// The line under the total: how many operations and what one came to on
/// average.
String answerLine(AskAnswer answer) {
  final count = answer.query.side == AskSide.income
      ? t.ask.answer.incomes(n: answer.count)
      : t.ask.answer.operations(n: answer.count);
  final average = answer.average;
  if (answer.count < 2 || average == null) return count;
  return '$count · ${t.ask.answer.average(amount: formatMoney(average))}';
}
