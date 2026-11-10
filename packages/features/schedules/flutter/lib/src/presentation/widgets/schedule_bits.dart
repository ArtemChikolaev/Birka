import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/schedules_common.dart';

/// Has the [SchedulesCubit] above it catch up with the calendar each time
/// the app comes back, as a night in the background may bring a new day.
class CalendarCatchUp extends StatefulWidget {
  /// Wraps [child].
  const CalendarCatchUp({required this.child, super.key});

  /// What it shows.
  final Widget child;

  @override
  State<CalendarCatchUp> createState() => _CalendarCatchUpState();
}

class _CalendarCatchUpState extends State<CalendarCatchUp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(context.read<SchedulesCubit>().calendarChecked()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The dot before a regular payment: the color of its category, or the
/// accent for an income and a quiet one for a transfer.
class ScheduleDot extends StatelessWidget {
  /// Creates the dot of [schedule] in [view].
  const ScheduleDot(this.view, this.schedule, {super.key});

  /// What the payments show.
  final SchedulesView view;

  /// The payment.
  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final color = view.categories[schedule.categoryId]?.color;
    if (color != null) return CategoryDot(color);
    return SizedBox.square(
      dimension: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: schedule.kind == TransactionKind.income
              ? colors.positive
              : colors.textSubtle,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// The color of the amount of [schedule]: the positive one for an income.
Color scheduleInk(BuildContext context, Schedule schedule) {
  final colors = BirkaColors.of(context);
  return schedule.kind == TransactionKind.income
      ? colors.positive
      : colors.text;
}

/// The day of a time in a list: its number large, and the month and the
/// weekday under it.
class DateColumn extends StatelessWidget {
  /// Creates the column of [day].
  const DateColumn(this.day, {super.key});

  /// The day.
  final CivilDate day;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: styles.heading.copyWith(color: colors.text, height: 1.1),
          ),
          // The month and the weekday shrink to the column rather than lose
          // their last letters.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${shortDate(day).split(' ').last} · ${weekdayLabel(day)}',
              maxLines: 1,
              softWrap: false,
              style: styles.caption.copyWith(color: colors.textSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

/// [amount] as a person would type it: `45000` or `799,90`.
String typedAmount(Money amount) {
  final digits = amount.currency.decimalDigits;
  var unit = 1;
  for (var i = 0; i < digits; i++) {
    unit *= 10;
  }
  final whole = amount.minorUnits ~/ unit;
  final part = amount.minorUnits % unit;
  return part == 0
      ? '$whole'
      : '$whole$decimalSeparator${'$part'.padLeft(digits, '0')}';
}

/// What a person typed as an amount in [currency], spaces and all, or `null`
/// when it is no amount or is below zero. An empty field is zero.
Money? amountTyped(String typed, Currency currency) {
  final cleaned = typed.replaceAll(RegExp(r'\s'), '');
  if (cleaned.isEmpty) return Money(0, currency);
  try {
    final money = Money.parse(cleaned, currency);
    return money.isNegative ? null : money;
  } on FormatException {
    return null;
  }
}
