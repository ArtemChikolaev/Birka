import 'dart:async';

import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

/// A keypad of digits and operators that fills the space it gets.
class GlassKeypad extends StatelessWidget {
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

  /// The smallest height at which the keys are still easy to hit.
  static const double minHeight = 200;

  @override
  Widget build(BuildContext context) {
    Widget digit(int value) => _Key(
      label: '$value',
      onTap: () => onDigit(value),
      child: _Symbol('$value'),
    );
    Widget operator(KeypadOperator value) => _Key(
      label: operatorLabels[value] ?? value.symbol,
      raised: true,
      onTap: () => onOperator(value),
      child: _Symbol(value.symbol, accent: true),
    );
    final point = _Key(
      label: pointLabel,
      onTap: onPoint,
      child: _Symbol(this.point),
    );
    final backspace = _Key(
      label: backspaceLabel,
      onTap: onBackspace,
      child: BirkaIcon(
        BirkaGlyph.backspace,
        size: 26,
        color: BirkaColors.of(context).text,
      ),
    );
    return Column(
      children: [
        _Row([
          digit(7),
          digit(8),
          digit(9),
          operator(KeypadOperator.divide),
        ]),
        _Row([
          digit(4),
          digit(5),
          digit(6),
          operator(KeypadOperator.multiply),
        ]),
        _Row([
          digit(1),
          digit(2),
          digit(3),
          operator(KeypadOperator.subtract),
        ]),
        _Row([point, digit(0), backspace, operator(KeypadOperator.add)]),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.keys);

  final List<Widget> keys;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: BirkaTokens.spaceXxs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, key) in keys.indexed) ...[
              if (index > 0) const SizedBox(width: BirkaTokens.spaceXs),
              Expanded(child: key),
            ],
          ],
        ),
      ),
    );
  }
}

class _Symbol extends StatelessWidget {
  const _Symbol(this.text, {this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Text(
      text,
      style: BirkaTextStyles.of(
        context,
      ).amount.copyWith(color: accent ? colors.accent : colors.text),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.child,
    this.raised = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool raised;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  var _pressed = false;

  void _press({required bool pressed}) => setState(() => _pressed = pressed);

  void _tap() {
    unawaited(HapticFeedback.selectionClick());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(pressed: true),
        onTapUp: (_) => _press(pressed: false),
        onTapCancel: () => _press(pressed: false),
        onTap: _tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: BirkaTokens.durationFastMs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: switch ((_pressed, widget.raised)) {
              (true, _) => colors.surfaceSelected,
              (false, true) => colors.surfaceRaised,
              (false, false) => colors.surface,
            },
            borderRadius: const BorderRadius.all(
              Radius.circular(BirkaTokens.radiusMd),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
