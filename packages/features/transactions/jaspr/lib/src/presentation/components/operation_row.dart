import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_badge.dart';

/// An operation in a list.
class OperationRow extends StatelessComponent {
  /// Creates a row of [operation]. With [accountId] its amount is what it did
  /// to that account.
  const OperationRow({
    required this.operation,
    required this.href,
    this.accountId,
    this.picked = false,
    super.key,
  });

  /// The operation.
  final Operation operation;

  /// Where the row leads.
  final String href;

  /// The account that the amount is about.
  final String? accountId;

  /// Whether the card of the operation is open beside the list.
  final bool picked;

  @override
  Component build(BuildContext context) {
    final accountId = this.accountId;
    return GlassListRow(
      title: operationTitle(operation),
      subtitle: operationSubtitle(operation),
      leading: OperationBadge(operation),
      trailing: AmountText(
        accountId == null
            ? operationAmount(operation)
            : operationAmountOn(operation, accountId),
        tone: accountId == null
            ? operationTone(operation)
            : operationToneOn(operation, accountId),
        textClass: 'text-body-strong',
      ),
      href: href,
      picked: picked,
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

/// The color of the amount of [operation] on the page of account [accountId]:
/// green for money that comes in, a transfer included.
AmountTone operationToneOn(Operation operation, String accountId) =>
    operation.amountOn(accountId).isPositive
    ? AmountTone.positive
    : AmountTone.neutral;
