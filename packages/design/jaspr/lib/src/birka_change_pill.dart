import 'package:design_jaspr/src/amount_text.dart';
import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A pill with the arrow and the amount of a change.
class BirkaChangePill extends StatelessComponent {
  /// Creates a pill that says [label].
  const BirkaChangePill({
    required this.label,
    required this.rise,
    this.good,
    super.key,
  });

  /// The formatted amount with its sign.
  final String label;

  /// Whether the amount went up.
  final bool rise;

  /// Whether the change is good news, green, or bad, red: more spent is bad
  /// news although it went up. Without it a rise is good.
  final bool? good;

  @override
  Component build(BuildContext context) {
    final good = this.good ?? rise;
    return span(
      classes: good
          ? 'birka-change-pill birka-change-pill--rise'
          : 'birka-change-pill birka-change-pill--fall',
      [
        BirkaIcon(rise ? BirkaGlyph.rise : BirkaGlyph.fall),
        AmountText(
          label,
          tone: good ? AmountTone.positive : AmountTone.negative,
          textClass: 'text-body-strong',
        ),
      ],
    );
  }

  /// The styles of the pill.
  @css
  static List<StyleRule> get styles => [
    css('.birka-change-pill').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'var(--radius-pill)',
        'display': 'inline-flex',
        'gap': 'var(--space-xxs)',
        'max-width': '100%',
        'padding': 'var(--space-xxs) var(--space-sm)',
      },
    ),
    css('.birka-change-pill .birka-icon').styles(
      raw: {'height': '14px', 'width': '14px'},
    ),
    css('.birka-change-pill--rise').styles(
      raw: {
        'background':
            'color-mix(in srgb, var(--color-positive) 16%, transparent)',
        'color': 'var(--color-positive)',
      },
    ),
    css('.birka-change-pill--fall').styles(
      raw: {
        'background':
            'color-mix(in srgb, var(--color-negative) 16%, transparent)',
        'color': 'var(--color-negative)',
      },
    ),
  ];
}
