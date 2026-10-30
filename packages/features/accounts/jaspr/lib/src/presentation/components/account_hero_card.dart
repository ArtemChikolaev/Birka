import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The big card of an account, with its art behind the name and the amount.
class AccountHeroCard extends StatelessComponent {
  /// Creates a card. With [href] it is a link.
  const AccountHeroCard({
    required this.art,
    required this.name,
    required this.subtitle,
    required this.amount,
    this.href,
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

  @override
  Component build(BuildContext context) {
    final card = CardArtSurface(
      art: art,
      child: div(classes: 'account-hero', [
        div(classes: 'account-hero__top', [
          div(classes: 'account-hero__names', [
            span(classes: 'text-label account-hero__line', [.text(name)]),
            span(
              classes: 'text-caption account-hero__line account-hero__subtitle',
              [.text(subtitle)],
            ),
          ]),
          const div(classes: 'account-hero__chip', []),
        ]),
        AmountText(amount, textClass: 'text-display'),
      ]),
    );
    if (href case final href?) {
      return a(classes: 'account-hero-link', href: href, [card]);
    }
    return card;
  }

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.account-hero-link').styles(
      raw: {
        'border-radius': 'var(--radius-xl)',
        'color': 'inherit',
        'display': 'block',
        'text-decoration': 'none',
      },
    ),
    css('.account-hero').styles(
      raw: {
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'height': '188px',
        'justify-content': 'space-between',
        'padding': 'var(--space-lg)',
      },
    ),
    css('.account-hero__top').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.account-hero__names').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.account-hero__line').styles(
      raw: {
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.account-hero__subtitle').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.account-hero__chip').styles(
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
