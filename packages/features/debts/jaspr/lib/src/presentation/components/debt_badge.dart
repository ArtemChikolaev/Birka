import 'package:debts_common/debts_common.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:ledger/ledger.dart';

/// The initial of the person of a debt, in the bright color of its art
/// (ADR 0029).
class DebtBadge extends StatelessComponent {
  /// Creates the badge of debt [account].
  const DebtBadge(this.account, {this.size = 36, super.key});

  /// The account of the debt, named after the person.
  final Account account;

  /// The width and the height in pixels.
  final int size;

  @override
  Component build(BuildContext context) => InitialBadge(
    name: account.name,
    color: CardArt.values.byName(account.art.name).tint,
    size: size,
  );
}

/// The color of a line of a debt in [tone], as CSS.
String debtToneColor(DebtTone tone) => switch (tone) {
  DebtTone.plain => 'var(--color-text-secondary)',
  DebtTone.muted => 'var(--color-text-muted)',
  DebtTone.due => 'var(--color-palette-amber)',
  DebtTone.good => 'var(--color-accent)',
};
