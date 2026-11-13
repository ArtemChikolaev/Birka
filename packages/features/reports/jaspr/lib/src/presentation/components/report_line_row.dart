import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';

/// A category of a report: its dot, its name, its change against the month
/// before, what it took or brought, and a bar against the biggest one, as a
/// [ShareLine] of the kit.
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
    final change = line.change;
    return ShareLine(
      color: categoryColor(line.category),
      title: line.category?.name ?? t.app.noCategory,
      note: change == null
          ? null
          : AmountText(
              percentLabel(change),
              tone: changeTone(change, kind),
              textClass: 'text-caption',
              alwaysShown: true,
            ),
      amount: AmountText(
        formatMoney(line.total),
        textClass: 'text-body-strong',
      ),
      fraction: line.share,
    );
  }
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
