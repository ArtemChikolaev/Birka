import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_badge.dart';

/// An operation in a list, with what can be done to it behind the row.
class OperationRow extends StatelessWidget {
  /// Creates a row of [operation].
  const OperationRow({
    required this.operation,
    required this.onOpen,
    required this.onRepeat,
    required this.onDelete,
    this.accountId,
    super.key,
  });

  /// The operation.
  final Operation operation;

  /// Called on a tap.
  final VoidCallback onOpen;

  /// Called by the button that records it once more.
  final VoidCallback onRepeat;

  /// Called by the button that deletes it.
  final VoidCallback onDelete;

  /// The account that the amount is about, on the page of that account.
  final String? accountId;

  /// The most room an amount takes, which it shrinks to fit.
  static const double _amountWidth = 170;

  @override
  Widget build(BuildContext context) {
    final accountId = this.accountId;
    // A transfer of a debt speaks of the account of the person, as its label
    // does (ADR 0029).
    final shown = accountId ?? operation.ownAccount?.id;
    return GlassSwipeRow(
      actions: [
        if (operation.canChange)
          GlassSwipeAction(
            glyph: BirkaGlyph.copy,
            label: t.transactions.repeat,
            onPressed: onRepeat,
          ),
        GlassSwipeAction(
          glyph: BirkaGlyph.trash,
          label: t.transactions.delete,
          danger: true,
          onPressed: onDelete,
        ),
      ],
      child: GlassListRow(
        title: operationTitle(operation),
        subtitle: operationSubtitle(operation),
        leading: OperationBadge(operation),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _amountWidth),
          child: AmountText(
            accountId == null
                ? operationAmount(operation)
                : operationAmountOn(operation, accountId),
            value:
                (shown == null ? operation.amount : operation.amountOn(shown))
                    .minorUnits,
            rise: operationRise(operation, accountId: accountId),
            tone: accountId == null
                ? operationTone(operation)
                : operationToneOn(operation, accountId),
          ),
        ),
        onTap: onOpen,
      ),
    );
  }
}

/// What a change of the amount of [operation] means: more is better, but a
/// transfer only moves money and is neither good nor bad news, unless it is
/// seen from account [accountId], which it brings money to or takes it from.
AmountRise? operationRise(Operation operation, {String? accountId}) =>
    accountId == null && operation.kind == TransactionKind.transfer
    ? null
    : AmountRise.good;

/// The color of the amount of [operation]: green for money that comes in and
/// quiet for a transfer, which only moves it.
AmountTone operationTone(Operation operation) => switch (operation.kind) {
  TransactionKind.transfer => AmountTone.muted,
  _ when operation.amount.isPositive => AmountTone.positive,
  _ => AmountTone.neutral,
};

/// The color of the amount of [operation] on the page of account [accountId]:
/// green for money that comes to it, a transfer included.
AmountTone operationToneOn(Operation operation, String accountId) =>
    operation.amountOn(accountId).isPositive
    ? AmountTone.positive
    : AmountTone.neutral;
