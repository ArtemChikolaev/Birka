import 'package:debts_common/debts_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// Asks by what day a debt should come back: none, a week, two weeks or a
/// month from [today], or a day from the calendar. The answer comes in a
/// record, since no day is an answer too, and a closed sheet gives none.
Future<(CivilDate?,)?> pickDebtDue(
  BuildContext context, {
  required CivilDate today,
  required CivilDate? current,
}) async {
  final choices = <_Due>[
    const _Due(null),
    _Due(today.addDays(7), label: t.debts.form.dueChoices.week),
    _Due(today.addDays(14), label: t.debts.form.dueChoices.twoWeeks),
    _Due(today.addMonths(1), label: t.debts.form.dueChoices.month),
    const _Due(null, pick: true),
  ];
  final selected = choices.firstWhere(
    (choice) => !choice.pick && choice.day == current,
    orElse: () => choices.last,
  );
  final picked = await showChoiceSheet<_Due>(
    context,
    title: t.debts.form.dueBy,
    choices: choices,
    selected: selected,
    labelOf: (choice) => choice.pick
        ? t.debts.form.dueChoices.pick
        : choice.label ?? t.debts.form.dueChoices.none,
    subtitleOf: (choice) => switch (choice) {
      _Due(pick: true) when selected.pick && current != null => debtDay(
        current,
        today: today,
      ),
      _Due(:final day?, pick: false) => debtDay(day, today: today),
      _ => null,
    },
  );
  if (picked == null || !context.mounted) return null;
  final (choice,) = picked;
  if (!choice.pick) return (choice.day,);
  final day = await pickDebtDay(
    context,
    today: today,
    current: current ?? today.addDays(7),
    first: today,
  );
  return day == null ? null : (day,);
}

class _Due {
  const _Due(this.day, {this.label, this.pick = false});

  final CivilDate? day;
  final String? label;
  final bool pick;
}

/// Asks for a day from the calendar, from [first] on when it is given.
Future<CivilDate?> pickDebtDay(
  BuildContext context, {
  required CivilDate today,
  required CivilDate current,
  CivilDate? first,
}) async {
  DateTime of(CivilDate day) => DateTime(day.year, day.month, day.day);
  final start = first ?? CivilDate(today.year - 5, 1, 1);
  final picked = await showDatePicker(
    context: context,
    initialDate: of(current.compareTo(start) < 0 ? start : current),
    firstDate: of(start),
    lastDate: DateTime(today.year + 5, 12, 31),
  );
  return picked == null ? null : CivilDate.of(picked);
}

/// Asks for an account among [accounts], with what each holds under it.
Future<String?> pickDebtAccount(
  BuildContext context, {
  required String title,
  required List<AccountBalance> accounts,
  required String? selected,
}) async {
  final picked = await showChoiceSheet<String>(
    context,
    title: title,
    choices: [for (final row in accounts) row.account.id],
    selected: selected ?? '',
    labelOf: (id) =>
        accounts.firstWhere((row) => row.account.id == id).account.name,
    subtitleOf: (id) => HiddenAmounts.mask(
      context,
      formatMoney(accounts.firstWhere((row) => row.account.id == id).balance),
    ),
  );
  return picked?.$1;
}

/// Asks for an amount in the currency of [amount], starting from it, and
/// gives it in minor units, or `null` when the sheet closed or the text is no
/// amount.
Future<int?> editDebtAmount(
  BuildContext context, {
  required String label,
  required Money amount,
}) async {
  final typed = await showFieldSheet(
    context,
    label: label,
    done: t.debts.done,
    initial: amount.isZero ? '' : typedAmount(amount),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
  );
  if (typed == null) return null;
  return amountTyped(typed, amount.currency)?.minorUnits;
}

/// The day of a transfer for people: «Сегодня», or the date.
String debtDayValue(CivilDate day, {required CivilDate today}) =>
    day == today ? t.debts.form.today : debtDay(day, today: today);
