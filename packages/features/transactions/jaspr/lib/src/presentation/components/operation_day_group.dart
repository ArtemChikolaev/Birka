import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_row.dart';

/// The operations of one day under a heading with what the day comes to.
class OperationDayGroup extends StatelessComponent {
  /// Creates a group of [day]. With [accountId] the amounts are what the
  /// operations did to that account.
  const OperationDayGroup({
    required this.day,
    required this.today,
    required this.hrefOf,
    this.accountId,
    this.picked,
    super.key,
  });

  /// The day.
  final OperationDay day;

  /// The day of today, which names the day.
  final CivilDate today;

  /// Where the operation with this id opens.
  final String Function(String id) hrefOf;

  /// The account that the amounts are about.
  final String? accountId;

  /// The operation whose card is open beside the list.
  final String? picked;

  @override
  Component build(BuildContext context) {
    final accountId = this.accountId;
    return section(classes: 'operation-day', [
      div(classes: 'operation-day__heading', [
        SectionLabel(dayHeading(day.day, today: today)),
        AmountText(
          amountsLabel(accountId == null ? day.total : day.totalOn(accountId)),
          tone: AmountTone.muted,
          textClass: 'text-caption',
        ),
      ]),
      GlassListGroup(
        children: [
          for (final operation in day.operations)
            OperationRow(
              key: ValueKey(operation.id),
              operation: operation,
              href: hrefOf(operation.id),
              accountId: accountId,
              picked: operation.id == picked,
            ),
        ],
      ),
    ]);
  }

  /// The styles of the group.
  @css
  static List<StyleRule> get styles => [
    css('.operation-day').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.operation-day__heading').styles(
      raw: {
        'align-items': 'baseline',
        'color': 'var(--color-text-secondary)',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
        'padding': '0 var(--space-xs)',
      },
    ),
    css('.operation-day__heading .amount').styles(
      raw: {'white-space': 'normal'},
    ),
  ];
}
