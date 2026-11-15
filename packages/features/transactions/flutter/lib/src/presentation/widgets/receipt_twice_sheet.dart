import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_row.dart';

/// What the person does about a receipt that the ledger already has.
enum ReceiptTwiceChoice {
  /// Opens the operation made from it.
  open,

  /// Goes back to the camera for another receipt.
  scanAnother,
}

/// Says that the receipt of [operation] is already in the ledger, and asks
/// whether to open its operation or to scan another (ADR 0032).
Future<ReceiptTwiceChoice> showReceiptTwice(
  BuildContext context,
  Operation operation,
) async {
  final colors = BirkaColors.of(context);
  final choice = await showModalBottomSheet<ReceiptTwiceChoice>(
    context: context,
    useRootNavigator: true,
    backgroundColor: colors.background,
    builder: (context) {
      void choose(ReceiptTwiceChoice choice) =>
          Navigator.of(context).pop(choice);
      return ChoiceSheet(
        title: t.transactions.receipt.twiceTitle,
        subtitle: t.transactions.receipt.twiceText,
        children: [
          GlassListGroup(
            children: [
              OperationRow(
                operation: operation,
                onOpen: () => choose(ReceiptTwiceChoice.open),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          BirkaButton(
            label: t.transactions.receipt.openOperation,
            onPressed: () => choose(ReceiptTwiceChoice.open),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.transactions.receipt.scanAnother,
            quiet: true,
            onPressed: () => choose(ReceiptTwiceChoice.scanAnother),
          ),
        ],
      );
    },
  );
  return choice ?? ReceiptTwiceChoice.scanAnother;
}
