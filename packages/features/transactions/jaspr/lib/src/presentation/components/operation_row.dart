import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_badge.dart';

/// An operation in a list.
class OperationRow extends StatelessComponent {
  /// Creates a row of [operation].
  const OperationRow({required this.operation, required this.href, super.key});

  /// The operation.
  final Operation operation;

  /// Where the row leads.
  final String href;

  @override
  Component build(BuildContext context) {
    return GlassListRow(
      title: operationTitle(operation),
      subtitle: operationSubtitle(operation),
      leading: OperationBadge(operation),
      trailing: AmountText(
        operationAmount(operation),
        tone: operationTone(operation),
        textClass: 'text-body-strong',
      ),
      href: href,
    );
  }
}

/// The color of the amount of [operation]: green for money that comes in and
/// quiet for a transfer, which only moves it.
AmountTone operationTone(Operation operation) => switch (operation.kind) {
  TransactionKind.transfer => AmountTone.muted,
  _ when operation.amount.isPositive => AmountTone.positive,
  _ => AmountTone.neutral,
};
