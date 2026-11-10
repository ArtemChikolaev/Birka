import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';

/// The dot before a regular payment: the color of its category, or the
/// positive one for an income and a quiet one for a transfer.
class ScheduleDot extends StatelessComponent {
  /// Creates the dot of [schedule] in [view].
  const ScheduleDot(this.view, this.schedule, {super.key});

  /// What the payments show.
  final SchedulesView view;

  /// The payment.
  final Schedule schedule;

  @override
  Component build(BuildContext context) {
    final color =
        view.categories[schedule.categoryId]?.color ??
        (schedule.kind == TransactionKind.income
            ? 'var(--color-positive)'
            : 'var(--color-text-subtle)');
    return span(
      classes: 'schedule-dot',
      styles: Styles(raw: {'background': color}),
      attributes: const {'aria-hidden': 'true'},
      const [],
    );
  }

  /// The styles of the dot.
  @css
  static List<StyleRule> get styles => [
    css('.schedule-dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '8px',
        'width': '8px',
      },
    ),
  ];
}

/// The day of a time in a list: its number large, and the month and the
/// weekday under it.
class DateColumn extends StatelessComponent {
  /// Creates the column of [day].
  const DateColumn(this.day, {super.key});

  /// The day.
  final CivilDate day;

  @override
  Component build(BuildContext context) {
    return span(classes: 'schedule-date', [
      span(classes: 'text-heading schedule-date__day', [.text('${day.day}')]),
      span(classes: 'text-caption schedule-date__month', [
        .text('${shortDate(day).split(' ').last} · ${weekdayLabel(day)}'),
      ]),
    ]);
  }

  /// The styles of the column.
  @css
  static List<StyleRule> get styles => [
    css('.schedule-date').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex': 'none',
        'flex-direction': 'column',
        'width': '52px',
      },
    ),
    css('.schedule-date__day').styles(
      raw: {'color': 'var(--color-text)', 'line-height': '1.1'},
    ),
    css('.schedule-date__month').styles(
      raw: {'color': 'var(--color-text-subtle)', 'white-space': 'nowrap'},
    ),
  ];
}

/// The classes of the amount of [kind]: the positive color for an income.
String amountClasses(TransactionKind kind) => kind == TransactionKind.income
    ? 'text-body-strong amount amount--positive'
    : 'text-body-strong amount amount--neutral';
