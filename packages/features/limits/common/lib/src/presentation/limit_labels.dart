import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/src/presentation/limit_form_cubit.dart';
import 'package:limits_common/src/presentation/limit_suggest_cubit.dart';
import 'package:limits_common/src/presentation/limits_cubit.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The name of the month of [day]: «ноябрь».
String limitMonthName(CivilDate day) => t.limits.months[day.month - 1];

/// The title of the limits of the month of [today]: «Лимиты на ноябрь».
String limitsTitle(CivilDate today) =>
    t.limits.monthOf(month: limitMonthName(today));

String _day(CivilDate day, CivilDate today) => dateLabel(
  year: day.year,
  month: day.month,
  day: day.day,
  thisYear: today.year,
);

String _amount(Money amount, {bool approximate = false}) => approximate
    ? t.limits.about(amount: formatMoney(amount))
    : formatMoney(amount);

/// What the month took of the limit: «≈ 261 €».
String limitSpent(LimitProgress progress) =>
    _amount(progress.spent, approximate: progress.approximate);

/// The limit under it: «из 400 €».
String limitOf(LimitProgress progress) =>
    t.limits.ofLimit(limit: formatMoney(progress.limit.amount));

/// Both in one line: «10 150 ₽ из 12 000 ₽».
String limitFigures(LimitProgress progress) => t.limits.spentOf(
  spent: limitSpent(progress),
  limit: formatMoney(progress.limit.amount),
);

/// What is left of the limit, or how far the month went over it.
String limitNote(LimitProgress progress) => progress.state == LimitState.over
    ? t.limits.over(amount: formatMoney(-progress.left))
    : t.limits.left(
        amount: _amount(progress.left, approximate: progress.approximate),
      );

/// The same, short, for a row of the page: «больше на 1 300 ₽».
String limitNoteShort(LimitProgress progress) =>
    progress.state == LimitState.over
    ? t.limits.overShort(amount: formatMoney(-progress.left))
    : limitNote(progress);

/// The day a limit near its end runs out at the pace of the month: «В таком
/// темпе хватит до 21 ноября», or `null` for any other limit.
String? limitPace(LimitProgress progress) {
  final day = progress.lastsUntil;
  if (progress.state != LimitState.near || day == null) return null;
  return t.limits.lastsUntil(day: _day(day, progress.today));
}

/// The note of a limit on the overview, with the pace of one near its end:
/// «осталось 1 850 ₽ · хватит примерно до 21 ноября».
String limitOverviewNote(LimitProgress progress) {
  final note = limitNote(progress);
  final day = progress.lastsUntil;
  if (progress.state != LimitState.near || day == null) return note;
  return '$note · ${t.limits.lastsUntilShort(day: _day(day, progress.today))}';
}

/// What screen readers say of the bar of a limit.
String limitMeter(LimitProgress progress) => t.limits.meter(
  category: progress.category.name,
  percent: (progress.share * 100).round(),
);

/// The summary of the limits on the overview: «превышен 1 · 13 дней».
String limitsSummary(LimitsState state) {
  final over = state.over > 0
      ? t.limits.overCount(n: state.over)
      : t.limits.allWithin;
  return '$over · ${t.limits.days(n: state.daysLeft)}';
}

/// The figure of the card «В лимите»: «4 из 5».
String limitsWithin(LimitsState state) =>
    t.limits.withinValue(within: state.within, all: state.limits.length);

/// Under it: «1 превышен», or that none is.
String limitsOverNote(LimitsState state) =>
    state.over > 0 ? t.limits.overNote(n: state.over) : t.limits.nothingOver;

/// The figure of the card «До конца месяца»: «13 дней».
String limitsDaysLeft(LimitsState state) => t.limits.days(n: state.daysLeft);

/// Under it: «с 1 декабря заново».
String limitsRestart(LimitsState state) =>
    t.limits.restartsOn(day: _day(state.next, state.today));

/// What a category without a limit spent: «6 400 ₽ в ноябре», or that its
/// money goes to regular payments.
String freeNote(FreeCategory free, CivilDate today) => free.regular
    ? '${formatMoney(free.spent)} · ${t.limits.regular}'
    : t.limits.spentIn(
        amount: formatMoney(free.spent),
        month: t.overview.monthsIn[today.month - 1],
      );

/// The months the averages come from: «По тратам за август — октябрь».
String suggestionsFrom(CivilDate month) {
  final months = fullMonthsBefore(month);
  return t.limits.suggestFrom(
    from: limitMonthName(months.first),
    to: limitMonthName(months.last),
  );
}

/// Why a limit is offered checked or not.
String suggestionNote(LimitSuggestion suggestion) =>
    switch (suggestion.reason) {
      SuggestionReason.steady => t.limits.suggestions.average(
        amount: formatMoney(suggestion.average),
      ),
      SuggestionReason.jumps => t.limits.suggestions.jumps(
        least: formatMoney(suggestion.least),
        most: formatMoney(suggestion.most),
      ),
      SuggestionReason.rare => t.limits.suggestions.rare(
        n: suggestion.monthsWithSpending,
      ),
      SuggestionReason.regular => t.limits.suggestions.regular,
    };

/// What the offer is made from.
String suggestionsText(LimitSuggestState state) => t.limits.suggestions.text(
  from: limitMonthName(state.months.first),
  to: limitMonthName(state.months.last),
  step: formatMoney(state.step),
);

/// The button of the offer: «Поставить 4 лимита».
String suggestionsButton(LimitSuggestState state) => state.picked.isEmpty
    ? t.limits.suggestions.none
    : t.limits.suggestions.put(n: state.picked.length);

/// What the toast says once the limits are set.
String suggestionsDone(LimitSuggestState state) => t.limits.suggestions.done(
  n: state.saved,
  month: limitMonthName(state.month),
);

/// When the averages come for a ledger without a full month.
String suggestionsShort(LimitSuggestState state) =>
    t.limits.suggestions.shortText(day: _day(state.nextFull, state.month));

/// The title of the form.
String limitFormTitle(LimitFormState state) => switch (state.category) {
  final category? when state.editing => t.limits.form.editTitle(
    category: category.name,
  ),
  _ => t.limits.form.newTitle,
};

/// What the month took of the category whose limit changes: «В ноябре —
/// 10 150 ₽ из 12 000 ₽».
String? limitSpentNow(LimitFormState state) {
  final spent = state.spent;
  final limit = state.category?.limit;
  if (!state.editing || spent == null || limit == null) return null;
  final month = t.overview.monthsIn[state.today.month - 1];
  return t.limits.form.spentNow(
    month: month.isEmpty ? month : month[0].toUpperCase() + month.substring(1),
    spent: formatMoney(spent),
    limit: formatMoney(limit.amount),
  );
}

/// The button that takes the offered limit: «Взять 6 500 ₽».
String limitTake(Money offer) => t.limits.form.take(amount: formatMoney(offer));

/// What the early word says.
String limitWarnLine(LimitFormState state) {
  if (!state.warnEarly) return t.limits.form.warnOff;
  final at = state.warnAt;
  return at == null
      ? t.limits.form.warnLater
      : t.limits.form.warnAt(amount: formatMoney(at));
}

/// How the month of a limit runs, and how other currencies count.
String limitCaption(LimitFormState state) => [
  if (state.monthStart == 1)
    t.limits.form.calendarMonth
  else
    t.limits.form.ownMonth(day: state.monthStart),
  if (state.currencies.length > 1) t.limits.form.otherCurrencies,
].join(' ');

/// What the toast says once the form is done.
String limitDone(LimitFormState state) {
  final name = state.category?.name ?? '';
  final amount = state.amount == null ? '' : formatMoney(state.amount!);
  return switch (state.status) {
    LimitFormStatus.removed => t.limits.form.removed(category: name),
    _ when state.editing => t.limits.form.changed(
      category: name,
      amount: amount,
    ),
    _ => t.limits.form.saved(category: name, amount: amount),
  };
}
