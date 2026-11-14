import 'package:debts_common/src/domain/debt.dart';
import 'package:debts_common/src/presentation/debt_form_cubit.dart';
import 'package:debts_common/src/presentation/debt_return_cubit.dart';
import 'package:debts_common/src/presentation/debts_cubit.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// How loudly a line of a debt speaks.
enum DebtTone {
  /// As the text around it.
  plain,

  /// Quieter than the text around it.
  muted,

  /// In amber: its day has come.
  due,

  /// In the accent: it went through.
  good,
}

/// A line of a debt with its tone.
typedef DebtLine = ({String text, DebtTone tone});

/// A day for people: `1 декабря`, with the year when it is not the year of
/// [today].
String debtDay(CivilDate day, {required CivilDate today}) => dateLabel(
  year: day.year,
  month: day.month,
  day: day.day,
  thisYear: today.year,
);

/// What [amount] comes to, with no sign: `3 000 ₽`.
String debtAmount(Money amount) => formatMoney(amount);

/// The line under the name of [debt] in a list: its day, or when it began,
/// or when it was settled.
DebtLine debtLine(Debt debt, {required CivilDate today}) {
  final line = t.debts.line;
  String day(CivilDate day) => debtDay(day, today: today);
  if (debt.closed) {
    final on = debt.closedOn ?? debt.steps.firstOrNull?.day ?? today;
    return (
      text: debt.side == DebtSide.lent
          ? line.returned(day: day(on))
          : line.repaid(day: day(on)),
      tone: DebtTone.muted,
    );
  }
  final due = debt.dueOn;
  if (due == today) return (text: line.dueToday, tone: DebtTone.due);
  if (due != null && due.compareTo(today) < 0) {
    return (text: line.overdue(day: day(due)), tone: DebtTone.due);
  }
  if (due != null) {
    return (text: line.dueOn(day: day(due)), tone: DebtTone.muted);
  }
  final since = debt.since ?? debt.steps.lastOrNull?.day ?? today;
  return (text: line.since(day: day(since)), tone: DebtTone.muted);
}

/// The quiet line under the amount of [debt] in a list: what the round came
/// to once part of it is back, or the amount in [state]'s currency for a
/// debt in another one, or nothing.
String? debtAmountNote(Debt debt, DebtsState state) {
  if (debt.closed) return null;
  if (debt.settled.isPositive) {
    return t.debts.line.of(total: debtAmount(debt.total));
  }
  final inBase = state.inBase(debt);
  return inBase == null
      ? null
      : t.debts.line.approx(amount: debtAmount(inBase));
}

/// The line under the amount on the card of [debt]: what is left of what.
String debtLeftLine(Debt debt, {required CivilDate today}) {
  final card = t.debts.card;
  if (debt.closed) {
    final day = debtDay(debt.closedOn ?? today, today: today);
    return debt.side == DebtSide.lent
        ? card.allReturned(day: day)
        : card.allRepaid(day: day);
  }
  final total = debtAmount(debt.total);
  return debt.side == DebtSide.lent
      ? card.leftToMe(total: total)
      : card.leftToThem(total: total);
}

/// The title of the bar on the card of [debt]: what came back.
String debtSettledTitle(Debt debt) => debt.side == DebtSide.lent
    ? t.debts.card.returned(amount: debtAmount(debt.settled))
    : t.debts.card.repaid(amount: debtAmount(debt.settled));

/// The share of the bar on the card of [debt]: `40%`.
String debtShare(Debt debt) => '${(debt.share * 100).round()}%';

/// The line of the day on the card of [debt]. [reminders] says whether this
/// device reminds of debts at all: the site does not.
DebtLine debtDueLine(
  Debt debt, {
  required CivilDate today,
  required bool reminders,
}) {
  final card = t.debts.card;
  if (debt.closed) {
    return (
      text: debt.reminds && reminders ? card.closedRemind : card.closed,
      tone: DebtTone.muted,
    );
  }
  final due = debt.dueOn;
  if (due == null) return (text: card.noDue, tone: DebtTone.muted);
  final day = debtDay(due, today: today);
  if (due == today) return (text: card.dueToday, tone: DebtTone.due);
  if (due.compareTo(today) < 0) {
    return (text: card.dueWas(day: day), tone: DebtTone.due);
  }
  if (debt.reminds && reminders) {
    return (text: card.dueRemind(day: day), tone: DebtTone.plain);
  }
  final days = today.daysUntil(due);
  return (
    text: days <= 31
        ? card.dueIn(
            day: day,
            inDays: t.debts.inDays(n: days),
          )
        : card.dueOn(day: day),
    tone: DebtTone.plain,
  );
}

/// The title of a step on the card of a debt: «Возврат», «В долг».
String debtStepTitle(DebtStep step) => switch (step.move) {
  DebtMove.lent => t.debts.move.lent,
  DebtMove.returned => t.debts.move.returned,
  DebtMove.borrowed => t.debts.move.borrowed,
  DebtMove.repaid => t.debts.move.repaid,
};

/// The line under a step: its day, the account and the note.
String debtStepLine(DebtStep step, {required CivilDate today}) => [
  debtDay(step.day, today: today),
  ?step.account?.name,
  if (step.note.isNotEmpty) step.note,
].join(' · ');

/// What a step did to the account of the person, with its sign.
String debtStepAmount(DebtStep step) => signedMoney(step.onAccount);

/// The line of the debts under «Долги» in «Ещё»: the totals, or what the
/// page is for.
String debtsMoreLine(DebtsState state) {
  final owed = state.owed.isEmpty ? null : state.owedTotal;
  final mine = state.mine.isEmpty ? null : state.mineTotal;
  return switch ((owed, mine)) {
    (final owed?, final mine?) => t.debts.moreBoth(
      owed: debtAmount(owed),
      mine: debtAmount(mine),
    ),
    (final owed?, null) => t.debts.moreOwed(owed: debtAmount(owed)),
    (null, final mine?) => t.debts.moreMine(mine: debtAmount(mine)),
    (null, null) => t.debts.moreHint,
  };
}

/// What the toast says after a new debt or more money on one.
String debtSavedToast(DebtSaved saved) =>
    t.debts.form.saved(name: saved.name, amount: debtAmount(saved.amount));

/// What the toast says after a return.
String debtReturnedToast(DebtReturned returned) {
  final back = t.debts.back;
  if (returned.closed) return back.closedToast(name: returned.name);
  final amount = debtAmount(returned.amount);
  final left = debtAmount(returned.left);
  return returned.side == DebtSide.lent
      ? back.returnedToast(amount: amount, left: left)
      : back.repaidToast(amount: amount, left: left);
}

/// The caption of the form of a return: what the return will do.
/// [reminders] says whether this device reminds of debts at all.
String debtReturnCaption(DebtReturnState state, {required bool reminders}) {
  final back = t.debts.back;
  final debt = state.debt;
  final left = state.leftAfter;
  if (debt == null) return '';
  final lent = debt.side == DebtSide.lent;
  if (left == null || !left.isPositive) {
    final remind = reminders && debt.reminds;
    return switch ((lent, remind)) {
      (true, true) => back.returnClosingRemind,
      (true, false) => back.returnClosing,
      (false, true) => back.repayClosingRemind,
      (false, false) => back.repayClosing,
    };
  }
  final amount = debtAmount(left);
  final due = debt.dueOn;
  if (due == null) {
    return lent ? back.returnLeft(left: amount) : back.repayLeft(left: amount);
  }
  final day = debtDay(due, today: state.today);
  return lent
      ? back.returnLeftDue(left: amount, day: day)
      : back.repayLeftDue(left: amount, day: day);
}

/// The title of the form of a return: «Возврат · Маша».
String debtReturnTitle(Debt debt) => debt.side == DebtSide.lent
    ? t.debts.back.returnTitle(name: debt.name)
    : t.debts.back.repayTitle(name: debt.name);

/// The choice of all that is left: «Всё · 3 000 ₽».
String debtReturnAll(Debt debt) =>
    t.debts.back.all(amount: debtAmount(debt.left));
