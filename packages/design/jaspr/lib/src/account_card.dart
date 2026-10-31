import 'package:design_jaspr/src/amount_text.dart';
import 'package:design_jaspr/src/card_art.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The card of an account, with its art behind the name and the amount.
class AccountCard extends StatelessComponent {
  /// Creates a card. With [href] it is a link.
  const AccountCard({
    required this.art,
    required this.name,
    required this.subtitle,
    required this.amount,
    this.href,
    this.compact = false,
    super.key,
  });

  /// The art of the card.
  final CardArt art;

  /// The name of the account.
  final String name;

  /// The quiet line under the name.
  final String subtitle;

  /// The formatted amount.
  final String amount;

  /// Where the card leads.
  final String? href;

  /// Whether the card is one of several in a row.
  final bool compact;

  @override
  Component build(BuildContext context) {
    final card = CardArtSurface(
      art: art,
      child: div(
        classes: compact
            ? 'account-card account-card--compact'
            : 'account-card',
        [
          div(classes: 'account-card__top', [
            div(classes: 'account-card__names', [
              span(classes: 'text-label account-card__line', [.text(name)]),
              span(
                classes:
                    'text-caption account-card__line account-card__subtitle',
                [.text(subtitle)],
              ),
            ]),
            const div(classes: 'account-card__chip', []),
          ]),
          AmountText(
            amount,
            textClass: compact ? 'text-title' : 'text-display',
          ),
        ],
      ),
    );
    if (href case final href?) {
      return a(classes: 'account-card-link', href: href, [card]);
    }
    return card;
  }

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.account-card-link').styles(
      raw: {
        'border-radius': 'var(--radius-xl)',
        'color': 'inherit',
        'display': 'block',
        'text-decoration': 'none',
      },
    ),
    css('.account-card').styles(
      raw: {
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'height': '188px',
        'justify-content': 'space-between',
        'padding': 'var(--space-lg)',
      },
    ),
    css('.account-card--compact').styles(
      raw: {'height': '146px', 'padding': 'var(--space-md)'},
    ),
    css('.account-card .amount').styles(
      raw: {'overflow': 'hidden', 'text-overflow': 'ellipsis'},
    ),
    css('.account-card__top').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.account-card__names').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.account-card__line').styles(
      raw: {
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.account-card__subtitle').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.account-card__chip').styles(
      raw: {
        'background':
            'linear-gradient(135deg, var(--color-text-subtle), '
            'var(--color-surface-selected))',
        'border': '1px solid var(--color-glass-border)',
        'border-radius': 'var(--radius-xs)',
        'box-sizing': 'border-box',
        'flex': 'none',
        'height': '28px',
        'width': '38px',
      },
    ),
  ];
}
