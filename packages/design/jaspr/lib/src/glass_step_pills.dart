import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The steps of a long task as a row of pills: the steps passed with a check,
/// the one on the screen lit, those ahead quiet. A passed step opens with a
/// click.
class GlassStepPills extends StatelessComponent {
  /// Creates the row. [current] and [reachable] count from zero.
  const GlassStepPills({
    required this.labels,
    required this.current,
    required this.reachable,
    required this.onStep,
    this.label,
    super.key,
  });

  /// The names of the steps, in their order.
  final List<String> labels;

  /// The step on the screen.
  final int current;

  /// The furthest step that opens; the steps up to it other than [current]
  /// stand as passed.
  final int reachable;

  /// Called with the step that was clicked, which is never [current].
  final ValueChanged<int> onStep;

  /// What the steps are of, for screen readers.
  final String? label;

  @override
  Component build(BuildContext context) {
    return nav(
      classes: 'glass-step-pills',
      attributes: {'aria-label': ?label},
      [
        ol(classes: 'glass-step-pills__list', [
          for (final (index, name) in labels.indexed) li([_pill(index, name)]),
        ]),
      ],
    );
  }

  Component _pill(int index, String name) {
    final passed = index != current && index <= reachable;
    final classes = [
      'text-body-strong glass-step-pills__pill',
      if (index == current) 'glass-step-pills__pill--current',
      if (passed) 'glass-step-pills__pill--passed',
    ].join(' ');
    final children = [
      span(classes: 'glass-step-pills__mark', [
        if (passed)
          const BirkaIcon(BirkaGlyph.check)
        else
          .text('${index + 1}'),
      ]),
      span(classes: 'glass-step-pills__name', [.text(name)]),
    ];
    if (!passed) {
      return span(
        classes: classes,
        attributes: {if (index == current) 'aria-current': 'step'},
        children,
      );
    }
    return button(
      classes: classes,
      type: ButtonType.button,
      onClick: () => onStep(index),
      children,
    );
  }

  /// The styles of the row.
  @css
  static List<StyleRule> get styles => [
    // A phone scrolls the row rather than squeezing its names.
    css('.glass-step-pills').styles(
      raw: {
        'margin': '0 calc(-1 * var(--space-lg))',
        'overflow-x': 'auto',
        'padding': '0 var(--space-lg)',
        'scrollbar-width': 'none',
      },
    ),
    css('.glass-step-pills__list').styles(
      raw: {
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'list-style': 'none',
        'margin': '0',
        'padding': '0',
      },
    ),
    css('.glass-step-pills__pill').styles(
      raw: {
        'align-items': 'center',
        'background': 'none',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'color': 'var(--color-text-subtle)',
        'display': 'inline-flex',
        'gap': 'var(--space-xs)',
        'height': '40px',
        'padding': '0 var(--space-md) 0 var(--space-xs)',
        'transition':
            'background var(--duration-base) var(--easing-fade), '
            'color var(--duration-base) var(--easing-fade)',
        'white-space': 'nowrap',
      },
    ),
    css('.glass-step-pills__pill--passed').styles(
      raw: {
        'background': 'var(--color-surface)',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
      },
    ),
    css('.glass-step-pills__pill--current').styles(
      raw: {
        'background': 'var(--color-text)',
        'border-color': 'var(--color-text)',
        'color': 'var(--color-background)',
      },
    ),
    css('.glass-step-pills__mark').styles(
      raw: {
        'align-items': 'center',
        'border': '1px solid var(--color-hairline)',
        'border-radius': '50%',
        'box-sizing': 'border-box',
        'display': 'inline-flex',
        'flex': 'none',
        'font-size': '12px',
        'height': '24px',
        'justify-content': 'center',
        'width': '24px',
      },
    ),
    css('.glass-step-pills__pill--passed .glass-step-pills__mark').styles(
      raw: {
        'background': 'var(--color-accent)',
        'border-color': 'var(--color-accent)',
        'color': 'var(--color-on-accent)',
      },
    ),
    css('.glass-step-pills__pill--current .glass-step-pills__mark').styles(
      raw: {
        'background': 'var(--color-background)',
        'border-color': 'var(--color-background)',
        'color': 'var(--color-text)',
      },
    ),
    css('.glass-step-pills__mark .birka-icon').styles(
      raw: {'height': '14px', 'width': '14px'},
    ),
    css('.glass-step-pills__pill--passed:focus-visible').styles(
      raw: {
        'outline': '2px solid var(--color-accent)',
        'outline-offset': '2px',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.glass-step-pills__pill').styles(raw: {'transition': 'none'}),
    ]),
  ];
}
