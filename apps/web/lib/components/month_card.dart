import 'dart:async';

import 'package:birka_web/app/report_address.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:reports_common/reports_common.dart';
import 'package:reports_jaspr/reports_jaspr.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

/// What the month of the operations came to, beside them on a wide page:
/// what went out and came in, the categories that took the most, and the way
/// to the report of the month.
///
/// It needs an [OperationsCubit] above it and a [ReportsCubit] on
/// [CalendarMonths], and keeps the report on the month of the operations.
class MonthCard extends StatefulComponent {
  /// Creates the card.
  const MonthCard({super.key});

  /// How many categories the card names.
  static const _categories = 4;

  @override
  State<MonthCard> createState() => _MonthCardState();

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.month-card').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.month-card .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.month-card__lines').styles(
      raw: {'display': 'flex', 'flex-direction': 'column'},
    ),
    // The rows keep their insides and lose their outsides to the card.
    css('.month-card__lines .share-line').styles(
      raw: {'padding-left': '0', 'padding-right': '0'},
    ),
    css('.month-card__lines .share-line + .share-line::before').styles(
      raw: {'left': '0', 'right': '0'},
    ),
  ];
}

class _MonthCardState extends State<MonthCard> {
  @override
  void initState() {
    super.initState();
    _follow(context.read<OperationsCubit>().state.month);
  }

  /// Keeps the report on [month] of the operations.
  void _follow(CivilDate month) {
    unawaited(context.read<ReportsCubit>().monthChanged(month));
  }

  @override
  Component build(BuildContext context) {
    return BlocListener<OperationsCubit, OperationsState>(
      listenWhen: (previous, current) => previous.month != current.month,
      listener: (_, state) => _follow(state.month),
      child: BlocBuilder<OperationsCubit, OperationsState>(
        builder: (context, operations) =>
            BlocBuilder<ReportsCubit, ReportsState>(
              builder: (context, reports) => _card(operations, reports),
            ),
      ),
    );
  }

  Component _card(OperationsState operations, ReportsState reports) {
    final lines = reports.status == ReportsStatus.ready
        ? reports.report.lines.take(MonthCard._categories).toList()
        : const <ReportLine>[];
    final month = operations.month;
    final today = operations.today;
    return GlassSurface(
      child: div(classes: 'month-card', [
        SectionLabel(monthLabel(month, today: today)),
        if (operations.expenses.isNotEmpty || operations.income.isNotEmpty)
          OperationsTotals(operations, stacked: true),
        if (lines.isNotEmpty) ...[
          const BirkaRule(),
          div(classes: 'month-card__lines', [
            for (final line in lines)
              ReportLineRow(
                line,
                kind: reports.kind,
                key: ValueKey(categoryKey(line.category)),
              ),
          ]),
        ],
        BirkaLinkRow(
          label: monthReportLabel(month, today: today),
          href: reportAddress(month),
        ),
      ]),
    );
  }
}

/// The reports of [MonthCard], counted by the months of the calendar as the
/// operations are, whatever day the months of the reports start on, so that
/// its categories and its totals cover the same days.
class CalendarMonths implements ReportsRepository {
  /// Counts the reports of [_reports] by the months of the calendar.
  const CalendarMonths(this._reports);

  final ReportsRepository _reports;

  @override
  Stream<Currency?> watchMainCurrency() => _reports.watchMainCurrency();

  @override
  Stream<Currency?> watchBaseCurrency() => _reports.watchBaseCurrency();

  @override
  int monthStart() => 1;

  @override
  Stream<int> watchMonthStart() => Stream.value(1);

  @override
  Stream<RateBook> watchRates() => _reports.watchRates();

  @override
  Stream<List<CategoryDayTotal>> watchDays(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => _reports.watchDays(kind, from: from, to: to);

  @override
  Future<List<CivilDate>> months({int start = 1}) => _reports.months();
}
