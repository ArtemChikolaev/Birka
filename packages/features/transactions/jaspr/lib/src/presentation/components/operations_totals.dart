import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';

/// What the operations on the page come to, `Расходы −86 420 ₽` and `Доходы
/// +125 000 ₽`, one amount for each currency: in a line under the filters,
/// or [stacked] one under the other, as in the card of the month at the side
/// of a wide page. With nothing spent or earned it says nothing.
class OperationsTotals extends StatelessComponent {
  /// Creates the totals of the operations that [state] shows.
  const OperationsTotals(this.state, {this.stacked = false, super.key});

  /// The operations on the page.
  final OperationsState state;

  /// Whether the two stand one under the other.
  final bool stacked;

  @override
  Component build(BuildContext context) {
    final expenses = state.expenses;
    final income = state.income;
    if (expenses.isEmpty && income.isEmpty) return const div([]);
    return div(
      classes: stacked
          ? 'text-body operations__totals operations__totals--stacked'
          : 'text-body operations__totals',
      [
        if (expenses.isNotEmpty)
          _total(
            t.transactions.filterExpenses,
            amountsLabel(expenses),
            AmountTone.neutral,
          ),
        if (income.isNotEmpty)
          _total(
            t.transactions.filterIncome,
            amountsLabel(income),
            AmountTone.positive,
          ),
      ],
    );
  }

  /// `Расходы −86 420 ₽`.
  static Component _total(String label, String amounts, AmountTone tone) {
    return span([
      .text('$label '),
      AmountText(amounts, tone: tone, textClass: 'text-body-strong'),
    ]);
  }

  /// The styles of the totals.
  @css
  static List<StyleRule> get styles => [
    css('.operations__totals').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-md)',
      },
    ),
    // Amounts in several currencies can take more than a line.
    css('.operations__totals .amount').styles(raw: {'white-space': 'normal'}),
    css('.operations__totals--stacked').styles(
      raw: {'align-items': 'flex-start', 'flex-direction': 'column'},
    ),
  ];
}
