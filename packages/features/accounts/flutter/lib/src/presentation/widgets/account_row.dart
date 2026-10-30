import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/src/presentation/widgets/account_labels.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// A row of the list of accounts.
class AccountRow extends StatelessWidget {
  /// Creates a row for [row]. The [main] account says so.
  const AccountRow({
    required this.row,
    required this.onTap,
    this.main = false,
    super.key,
  });

  /// The account and its balance.
  final AccountBalance row;

  /// Called on a tap.
  final VoidCallback onTap;

  /// Whether this is the main account.
  final bool main;

  @override
  Widget build(BuildContext context) {
    final account = row.account;
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return GlassListRow(
      title: account.name,
      subtitle: accountSubtitle(
        currency: account.currency,
        type: account.type,
        lastDigits: account.lastDigits,
      ),
      leading: CardArtThumbnail(
        art: cardArtOf(account.art),
        highlighted: main,
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            AmountText(
              formatMoney(row.balance),
              tone: row.balance.isNegative
                  ? AmountTone.negative
                  : AmountTone.neutral,
              style: styles.bodyStrong.copyWith(color: colors.text),
            ),
            if (main)
              Text(
                t.accounts.main,
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}
