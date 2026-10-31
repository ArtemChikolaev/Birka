import 'package:design_jaspr/src/birka_icon.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

/// An operator key of a [GlassKeypad].
enum KeypadOperator {
  /// Divides.
  divide('÷'),

  /// Multiplies.
  multiply('×'),

  /// Subtracts.
  subtract('−'),

  /// Adds.
  add('+')
  ;

  const KeypadOperator(this.symbol);

  /// What the key shows.
  final String symbol;
}

/// A keypad of digits and operators. While it is on the page, a real keyboard
/// types on it too, unless the focus is in a field.
class GlassKeypad extends StatefulComponent {
  /// Creates a keypad. [point] is the decimal mark of the language, and the
  /// labels are what screen readers read for the keys without a digit.
  const GlassKeypad({
    required this.point,
    required this.pointLabel,
    required this.backspaceLabel,
    required this.operatorLabels,
    required this.onDigit,
    required this.onPoint,
    required this.onOperator,
    required this.onBackspace,
    required this.onEnter,
    super.key,
  });

  /// The decimal mark.
  final String point;

  /// What the key with the decimal mark does.
  final String pointLabel;

  /// What the key that erases does.
  final String backspaceLabel;

  /// What each operator key does.
  final Map<KeypadOperator, String> operatorLabels;

  /// Called with a digit.
  final ValueChanged<int> onDigit;

  /// Called by the key with the decimal mark.
  final VoidCallback onPoint;

  /// Called with an operator.
  final ValueChanged<KeypadOperator> onOperator;

  /// Called by the key that erases.
  final VoidCallback onBackspace;

  /// Called by the Enter key of a real keyboard.
  final VoidCallback onEnter;

  /// Does what the key of a real keyboard called [key] means here, and says
  /// whether it means anything.
  bool press(String key) {
    if (int.tryParse(key) case final digit?) {
      onDigit(digit);
      return true;
    }
    switch (key) {
      case '.' || ',':
        onPoint();
      case '+':
        onOperator(KeypadOperator.add);
      case '-':
        onOperator(KeypadOperator.subtract);
      case '*':
        onOperator(KeypadOperator.multiply);
      case '/':
        onOperator(KeypadOperator.divide);
      case 'Backspace':
        onBackspace();
      case 'Enter':
        onEnter();
      default:
        return false;
    }
    return true;
  }

  @override
  State<GlassKeypad> createState() => _GlassKeypadState();

  /// The styles of the keypad.
  @css
  static List<StyleRule> get styles => [
    css('.glass-keypad').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-xs)',
        'grid-template-columns': 'repeat(4, minmax(0, 1fr))',
      },
    ),
    css('.glass-keypad__key').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border': '0',
        'border-radius': 'var(--radius-md)',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'display': 'flex',
        'height': '52px',
        'justify-content': 'center',
        'padding': '0',
        // Lets a quick second tap type instead of zooming the page.
        'touch-action': 'manipulation',
        'transition': 'background var(--duration-fast)',
      },
    ),
    css('.glass-keypad__key--raised').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'color': 'var(--color-accent)',
      },
    ),
    css('.glass-keypad__key:active').styles(
      raw: {'background': 'var(--color-surface-selected)'},
    ),
    // Only where a pointer can hover: on a touch screen it would stay on.
    css.media(const MediaQuery.raw('(hover: hover)'), [
      css('.glass-keypad__key:hover').styles(
        raw: {'background': 'var(--color-surface-selected)'},
      ),
    ]),
  ];
}

class _GlassKeypadState extends State<GlassKeypad> {
  late final JSFunction _keyListener = _onKey.toJS;
  late final JSFunction _mouseListener = _onMouseDown.toJS;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    web.window
      ..addEventListener('keydown', _keyListener)
      ..addEventListener('mousedown', _mouseListener);
  }

  @override
  void dispose() {
    if (kIsWeb) {
      web.window
        ..removeEventListener('keydown', _keyListener)
        ..removeEventListener('mousedown', _mouseListener);
    }
    super.dispose();
  }

  void _onKey(web.Event event) {
    final keys = event as web.KeyboardEvent;
    if (keys.ctrlKey || keys.metaKey || keys.altKey) return;
    final target = keys.target as web.Element?;
    // A field keeps its keys, and a button that Tab has reached keeps Enter.
    // A calendar is no field: after a pick the digits are for the amount.
    if (target != null &&
        (target.matches('input:not([type=date]), textarea, select') ||
            (keys.key == 'Enter' && target.matches('a, button')))) {
      return;
    }
    if (component.press(keys.key)) keys.preventDefault();
  }

  /// Keeps a click from leaving the focus on a button, where Enter would
  /// press it again instead of saving. It still leaves a field, which takes
  /// the keyboard of a phone away from the keypad.
  void _onMouseDown(web.Event event) {
    final target = event.target as web.Element?;
    if (target?.closest('button') == null) return;
    event.preventDefault();
    (web.document.activeElement as web.HTMLElement?)?.blur();
  }

  Component _key({
    required String label,
    required VoidCallback onTap,
    required Component child,
    bool raised = false,
  }) {
    return button(
      classes: raised
          ? 'text-amount glass-keypad__key glass-keypad__key--raised'
          : 'text-amount glass-keypad__key',
      type: ButtonType.button,
      onClick: onTap,
      // A real keyboard has these keys, so Tab goes past them.
      attributes: {'aria-label': label, 'tabindex': '-1'},
      [child],
    );
  }

  @override
  Component build(BuildContext context) {
    final keypad = component;
    Component digit(int value) => _key(
      label: '$value',
      onTap: () => keypad.onDigit(value),
      child: .text('$value'),
    );
    Component operator(KeypadOperator value) => _key(
      label: keypad.operatorLabels[value] ?? value.symbol,
      raised: true,
      onTap: () => keypad.onOperator(value),
      child: .text(value.symbol),
    );
    return div(classes: 'glass-keypad', [
      digit(7),
      digit(8),
      digit(9),
      operator(KeypadOperator.divide),
      digit(4),
      digit(5),
      digit(6),
      operator(KeypadOperator.multiply),
      digit(1),
      digit(2),
      digit(3),
      operator(KeypadOperator.subtract),
      _key(
        label: keypad.pointLabel,
        onTap: keypad.onPoint,
        child: .text(keypad.point),
      ),
      digit(0),
      _key(
        label: keypad.backspaceLabel,
        onTap: keypad.onBackspace,
        child: const BirkaIcon(BirkaGlyph.backspace),
      ),
      operator(KeypadOperator.add),
    ]);
  }
}
