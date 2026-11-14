import 'package:debts_common/debts_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:ledger/ledger.dart';

/// The initial of the person of a debt, in the bright color of its art
/// (ADR 0029).
class DebtBadge extends StatelessWidget {
  /// Creates the badge of debt [account].
  const DebtBadge(this.account, {this.size = 36, super.key});

  /// The account of the debt, named after the person.
  final Account account;

  /// The width and the height.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: InitialBadge(
      name: account.name,
      color: CardArt.values.byName(account.art.name).tint,
      size: size,
    ),
  );
}

/// The amber of a day that has come.
const _due = Color(BirkaTokens.colorPaletteAmber);

/// The color of a line of a debt in [tone].
Color debtToneColor(BuildContext context, DebtTone tone) {
  final colors = BirkaColors.of(context);
  return switch (tone) {
    DebtTone.plain => colors.textSecondary,
    DebtTone.muted => colors.textMuted,
    DebtTone.due => _due,
    DebtTone.good => colors.accent,
  };
}
