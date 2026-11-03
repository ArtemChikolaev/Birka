import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// The main action of a screen: an emerald pill with a label in capitals.
///
/// Once its action is [done], such as a form that has been saved, the pill
/// shrinks into a circle over `duration.slow` as its label fades, a check
/// mark comes in with a little bounce, and [onDone] is called after the
/// check has stood for a moment. When the system asks for less motion, the
/// label only fades into the check.
class BirkaButton extends StatefulWidget {
  /// Creates a button. Without [onPressed] it is disabled.
  const BirkaButton({
    required this.label,
    this.onPressed,
    this.quiet = false,
    this.danger = false,
    this.done = false,
    this.onDone,
    super.key,
  });

  /// The label as written, not in capitals.
  final String label;

  /// Called on a tap.
  final VoidCallback? onPressed;

  /// Whether this is the second choice next to a main action, with no
  /// emerald.
  final bool quiet;

  /// Whether the action cannot be taken back, in the color of a loss.
  final bool danger;

  /// Whether the action is done, which turns the pill into a check mark.
  final bool done;

  /// Called once the check mark has stood for a moment, such as to close
  /// the form.
  final VoidCallback? onDone;

  /// The height of the pill.
  static const double height = 56;

  @override
  State<BirkaButton> createState() => _BirkaButtonState();
}

class _BirkaButtonState extends State<BirkaButton>
    with SingleTickerProviderStateMixin {
  /// How long the check mark stands before the button says it is done.
  static const _stand = Duration(milliseconds: 500);

  late final AnimationController _done = AnimationController(
    vsync: this,
    value: widget.done ? 1 : 0,
  )..addStatusListener(_moved);

  /// Whether the label only fades into the check.
  bool _still = false;

  void _moved(AnimationStatus status) {
    if (status.isCompleted && widget.done) widget.onDone?.call();
  }

  @override
  void didUpdateWidget(BirkaButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done == oldWidget.done) return;
    if (!widget.done) {
      _done.value = 0;
      return;
    }
    _still = BirkaMotion.reduced(context);
    _done.duration =
        (_still ? BirkaMotion.fast : BirkaMotion.fast + BirkaMotion.slow) +
        _stand;
    unawaited(_done.forward(from: 0));
  }

  @override
  void dispose() {
    _done.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final onPressed = widget.done ? null : widget.onPressed;
    final (fill, ink) = switch ((widget.danger, widget.quiet)) {
      (true, _) => (colors.negative.withValues(alpha: 0.16), colors.negative),
      (false, true) => (colors.surfaceRaised, colors.text),
      (false, false) => (colors.accent, colors.onAccent),
    };
    final label = Text(
      widget.label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: BirkaTextStyles.of(context).label.copyWith(color: ink),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: AnimatedOpacity(
          opacity: widget.onPressed == null && !widget.done ? 0.5 : 1,
          duration: const Duration(milliseconds: BirkaTokens.durationFastMs),
          child: AnimatedBuilder(
            animation: _done,
            builder: (context, _) => _done.value == 0
                ? Container(
                    height: BirkaButton.height,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: BirkaTokens.spaceLg,
                    ),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: _pill,
                    ),
                    child: label,
                  )
                : _check(fill, ink, label),
          ),
        ),
      ),
    );
  }

  static const _pill = BorderRadius.all(
    Radius.circular(BirkaTokens.radiusPill),
  );

  /// The pill on its way to the check mark.
  Widget _check(Color fill, Color ink, Widget label) {
    final whole = _done.duration!.inMicroseconds;
    double part(Duration from, Duration length, Curve curve) => Interval(
      from.inMicroseconds / whole,
      (from + length).inMicroseconds / whole,
      curve: curve,
    ).transform(_done.value);
    final faded = part(Duration.zero, BirkaMotion.fast, BirkaMotion.fadeCurve);
    final after = _still ? Duration.zero : BirkaMotion.fast;
    final shown = part(
      after,
      _still ? BirkaMotion.fast : BirkaMotion.base,
      BirkaMotion.fadeCurve,
    );
    final shrunk = _still
        ? 0.0
        : part(Duration.zero, BirkaMotion.slow, BirkaMotion.standardCurve);
    final grown = _still
        ? 1.0
        : part(after, BirkaMotion.slow, BirkaMotion.springCurve);
    return CustomSingleChildLayout(
      delegate: _Shrinking(shrunk),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: fill, borderRadius: _pill),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The label keeps its width as the pill closes around it.
            OverflowBox(
              maxWidth: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BirkaTokens.spaceLg,
                ),
                child: Opacity(opacity: 1 - faded, child: label),
              ),
            ),
            Opacity(
              opacity: shown,
              child: Transform.scale(
                scale: lerpDouble(0.4, 1, grown),
                child: BirkaIcon(BirkaGlyph.check, size: 26, color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays the pill out [shrunk] of the way from the whole width of the button
/// to a circle in its middle.
class _Shrinking extends SingleChildLayoutDelegate {
  const _Shrinking(this.shrunk);

  final double shrunk;

  static double _whole(BoxConstraints constraints) =>
      constraints.hasBoundedWidth ? constraints.maxWidth : BirkaButton.height;

  @override
  Size getSize(BoxConstraints constraints) =>
      constraints.constrain(Size(_whole(constraints), BirkaButton.height));

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tightFor(
        width: lerpDouble(_whole(constraints), BirkaButton.height, shrunk),
        height: BirkaButton.height,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      Offset((size.width - childSize.width) / 2, 0);

  @override
  bool shouldRelayout(_Shrinking oldDelegate) => shrunk != oldDelegate.shrunk;
}
