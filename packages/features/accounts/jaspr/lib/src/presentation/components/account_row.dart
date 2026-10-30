import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/src/presentation/components/card_art_of.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// A row of the list of accounts.
class AccountRow extends StatelessComponent {
  /// Creates a row for [row]. The [main] account says so.
  const AccountRow({
    required this.row,
    required this.href,
    this.main = false,
    super.key,
  });

  /// The account and its balance.
  final AccountBalance row;

  /// Where the row leads.
  final String href;

  /// Whether this is the main account.
  final bool main;

  @override
  Component build(BuildContext context) {
    final account = row.account;
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
      trailing: span(classes: 'account-row__side', [
        AmountText(
          formatMoney(row.balance),
          tone: row.balance.isNegative
              ? AmountTone.negative
              : AmountTone.neutral,
          textClass: 'text-body-strong',
        ),
        if (main)
          span(classes: 'text-caption account-row__main', [
            .text(t.accounts.main),
          ]),
      ]),
      href: href,
    );
  }

  /// The styles of the row.
  @css
  static List<StyleRule> get styles => [
    css('.account-row__side').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'flex': 'none',
        'flex-direction': 'column',
      },
    ),
    css('.account-row__main').styles(raw: {'color': 'var(--color-text-muted)'}),
  ];
}
