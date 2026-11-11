import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';

/// A category of a report: its dot, its name, its change against the month
/// before, what it took or brought, and a bar against the biggest one. The
/// rows of a list are parted by a thin line.
class ReportLineRow extends StatelessComponent {
  /// Creates the row of [line], a category of [kind].
  const ReportLineRow(this.line, {required this.kind, super.key});

  /// The category and its numbers.
  final ReportLine line;

  /// Whether the report is of expenses or of income, which tells good news
  /// from bad.
  final CategoryKind kind;

  @override
  Component build(BuildContext context) {
    final color = categoryColor(line.category);
    final change = line.change;
    return div(classes: 'reports__line', [
      div(classes: 'reports__head', [
        span(
          classes: 'reports__dot',
          styles: Styles(raw: {'background': color}),
          const [],
        ),
        span(classes: 'text-body-strong reports__name', [
          .text(line.category?.name ?? t.app.noCategory),
        ]),
        if (change != null)
          AmountText(
            percentLabel(change),
            tone: changeTone(change, kind),
            textClass: 'text-caption',
            alwaysShown: true,
          ),
        AmountText(formatMoney(line.total), textClass: 'text-body-strong'),
      ]),
      div(classes: 'reports__bar', [
        div(
          classes: 'reports__fill',
          styles: Styles(
            raw: {'background': color, 'width': '${line.share * 100}%'},
          ),
          const [],
        ),
      ]),
    ]);
  }

  /// The styles of the row.
  @css
  static List<StyleRule> get styles => [
    css('.reports__line').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'padding': 'var(--space-md)',
        'position': 'relative',
      },
    ),
    // The thin line between rows, which stops short of the edges.
    css('.reports__line + .reports__line::before').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'content': '""',
        'height': '1px',
        'left': 'var(--space-md)',
        'position': 'absolute',
        'right': 'var(--space-md)',
        'top': '0',
      },
    ),
    // An amount too long for the line takes its own.
    css('.reports__head').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-xs)',
      },
    ),
    css('.reports__dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '10px',
        'width': '10px',
      },
    ),
    css('.reports__name').styles(
      raw: {
        'flex': '1',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.reports__head .text-body-strong.amount').styles(
      raw: {'margin-left': 'auto'},
    ),
    css('.reports__bar').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-xs)',
        'height': '4px',
        'overflow': 'hidden',
      },
    ),
    css('.reports__fill').styles(raw: {'height': '100%'}),
  ];
}

/// The color of [category], which is its own choice.
String categoryColor(Category? category) =>
    category?.color ?? 'var(--color-text-subtle)';

/// How a change of [percent] reads in a report of [kind]: a rise of expenses
/// is bad news, and of income good news.
AmountTone changeTone(int percent, CategoryKind kind) {
  if (percent == 0) return AmountTone.muted;
  final good = (percent > 0) == (kind == CategoryKind.income);
  return good ? AmountTone.positive : AmountTone.negative;
}
