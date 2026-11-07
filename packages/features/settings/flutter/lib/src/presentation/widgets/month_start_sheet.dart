import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

/// Asks which day of the calendar a month of the overview and the reports
/// starts on (ADR 0024), and gives it, or `null` when the sheet closes
/// without a choice. The settings and the page of the money until the salary
/// both ask through it.
Future<int?> showMonthStartSheet(
  BuildContext context, {
  required int selected,
}) async {
  final picked = await showChoiceSheet<int>(
    context,
    title: t.settings.monthStart,
    subtitle: t.settings.monthStartNote,
    choices: monthStartChoices,
    selected: selected,
    labelOf: monthStartLabel,
    subtitleOf: (day) => day == 1 ? t.settings.monthStartCalendar : null,
  );
  return picked?.$1;
}
