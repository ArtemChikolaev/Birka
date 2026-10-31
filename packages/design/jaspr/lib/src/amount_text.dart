import 'package:design_jaspr/src/hidden_amounts.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The color of an [AmountText].
enum AmountTone {
  /// The color of the surrounding text.
  neutral,

  /// The positive color, for a rise.
  positive,

  /// The negative color, for a fall.
  negative,

  /// The muted text color, for a figure that matters less.
  muted,
}

/// A figure in the amount style with tabular digits, which line up in
/// columns and keep their width when they change.
///
/// It shows [text] as it is: the caller formats the number and its sign. Under
/// [HiddenAmounts] its digits are hidden, unless it is [alwaysShown].
class AmountText extends StatelessComponent {
  /// Creates a figure.
  const AmountText(
    this.text, {
    this.tone = AmountTone.neutral,
    this.textClass = 'text-amount',
    this.alwaysShown = false,
    super.key,
  });

  /// The formatted figure, such as `−1 250 ₽`.
  final String text;

  /// The color of the figure.
  final AmountTone tone;

  /// The text style from the tokens, such as `text-display` for a total.
  final String textClass;

  /// Whether the figure stays even when amounts are hidden, such as what is
  /// being typed.
  final bool alwaysShown;

  @override
  Component build(BuildContext context) {
    return span(classes: '$textClass amount amount--${tone.name}', [
      .text(alwaysShown ? text : HiddenAmounts.mask(context, text)),
    ]);
  }

  /// The styles of the figure.
  @css
  static List<StyleRule> get styles => [
    css('.amount').styles(
      raw: {
        'font-variant-numeric': 'tabular-nums',
        'white-space': 'nowrap',
      },
    ),
    css('.amount--positive').styles(raw: {'color': 'var(--color-positive)'}),
    css('.amount--negative').styles(raw: {'color': 'var(--color-negative)'}),
    css('.amount--muted').styles(raw: {'color': 'var(--color-text-muted)'}),
  ];
}
