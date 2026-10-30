import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A switch between on and off.
class BirkaSwitch extends StatelessComponent {
  /// Creates a switch. Screen readers read [label].
  const BirkaSwitch({
    required this.value,
    required this.label,
    required this.onChanged,
    super.key,
  });

  /// Whether the switch is on.
  final bool value;

  /// What the switch turns on and off.
  final String label;

  /// Called with the new value.
  final ValueChanged<bool> onChanged;

  @override
  Component build(BuildContext context) {
    return button(
      classes: 'birka-switch${value ? ' birka-switch--on' : ''}',
      type: ButtonType.button,
      onClick: () => onChanged(!value),
      attributes: {
        'role': 'switch',
        'aria-checked': '$value',
        'aria-label': label,
      },
      const [span(classes: 'birka-switch__thumb', [])],
    );
  }

  /// The styles of the switch.
  @css
  static List<StyleRule> get styles => [
    css('.birka-switch').styles(
      raw: {
        'background': 'var(--color-surface-selected)',
        'border': '0',
        'border-radius': 'var(--radius-pill)',
        'cursor': 'pointer',
        'display': 'block',
        'flex': 'none',
        'height': '32px',
        'padding': '4px',
        'transition': 'background var(--duration-fast)',
        'width': '52px',
      },
    ),
    css('.birka-switch--on').styles(raw: {'background': 'var(--color-accent)'}),
    css('.birka-switch__thumb').styles(
      raw: {
        'background': 'var(--color-text)',
        'border-radius': 'var(--radius-pill)',
        'display': 'block',
        'height': '24px',
        'transition': 'transform var(--duration-fast)',
        'width': '24px',
      },
    ),
    css('.birka-switch--on .birka-switch__thumb').styles(
      raw: {'transform': 'translateX(20px)'},
    ),
  ];
}
