import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';

/// Asks whether to delete [operation], and tells the answer.
Future<bool> confirmDelete(BuildContext context, Operation operation) async {
  final colors = BirkaColors.of(context);
  final sure = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: colors.background,
    builder: (context) => ChoiceSheet(
      title: t.transactions.deleteTitle,
      children: [
        Text(
          '${HiddenAmounts.mask(context, operationAmount(operation))} · '
          '${operationTitle(operation)}',
          style: BirkaTextStyles.of(
            context,
          ).body.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: BirkaTokens.spaceLg),
        BirkaButton(
          label: t.transactions.delete,
          danger: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        BirkaButton(
          label: t.transactions.cancel,
          quiet: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return sure ?? false;
}
