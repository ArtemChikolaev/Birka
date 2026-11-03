import 'dart:async';

import 'package:design_flutter/src/components/hidden_amounts.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The color of an [AmountText].
enum AmountTone {
  /// The color of the surrounding text.
  neutral,

  /// [BirkaColors.positive], for a rise.
  positive,

  /// [BirkaColors.negative], for a fall.
  negative,

  /// [BirkaColors.textMuted], for a figure that matters less.
  muted,
}

/// What it means for the owner of the money when a figure grows.
enum AmountRise {
  /// Good news, as for a balance or an income.
  good,

  /// Bad news, as for what was spent.
  bad,
}

/// A figure in the amount style with tabular digits, which line up in
/// columns and keep their width when they change.
///
/// It shows [text] as it is: the caller formats the number and its sign. A
/// figure never wraps or loses digits; when it does not fit, it shrinks. Under
/// [HiddenAmounts] its digits are hidden, unless it is [alwaysShown].
///
/// With a [value] the figure rolls to a new one over `duration.roll`: the
/// digits that change roll up as it grows and down as it shrinks. With a
/// [rise] it also takes the color of good or bad news while it rolls, and
/// turns back once it settles. A change that comes while the figure is out of
/// sight, such as under a sheet or on another tab, waits and rolls once the
/// figure shows again. A figure does not roll the first time it shows, nor
/// into another currency, nor while amounts are hidden; when the system asks
/// for less motion, it changes at once and only its color comes and goes.
class AmountText extends StatefulWidget {
  /// Creates a figure.
  const AmountText(
    this.text, {
    this.tone = AmountTone.neutral,
    this.style,
    this.alwaysShown = false,
    this.value,
    this.rise,
    super.key,
  });

  /// The formatted figure, such as `−1 250 ₽`.
  final String text;

  /// The color of the figure.
  final AmountTone tone;

  /// A style in place of [BirkaTextStyles.amount], such as
  /// [BirkaTextStyles.display] for a total.
  final TextStyle? style;

  /// Whether the figure stays when amounts are hidden, such as one being typed.
  final bool alwaysShown;

  /// How much the figure stands for, such as the amount in minor units, so
  /// that it can roll to a new value.
  final num? value;

  /// What a rise of [value] means, so that a change takes its color.
  final AmountRise? rise;

  @override
  State<AmountText> createState() => _AmountTextState();
}

typedef _Figure = ({String text, num? value});

class _AmountTextState extends State<AmountText>
    with SingleTickerProviderStateMixin {
  // What the figure shows once it settles.
  late _Figure _shown = (text: widget.text, value: widget.value);

  // What it rolls from, while it rolls.
  _Figure? _from;

  // What it showed before a change that waits for it to come into sight.
  _Figure? _waiting;

  AnimationController? _controller;
  ValueListenable<bool>? _inSight;
  bool _hidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hidden = HiddenAmounts.of(context);
    final inSight = TickerMode.getNotifier(context);
    if (inSight != _inSight) {
      _inSight?.removeListener(_cameIntoSight);
      _inSight = inSight..addListener(_cameIntoSight);
    }
  }

  @override
  void didUpdateWidget(AmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = (text: widget.text, value: widget.value);
    if (next == _shown) return;
    final from = _waiting ?? _shown;
    _shown = next;
    _waiting = null;
    if (!_rolls(from)) {
      _settle();
    } else if (_inSight?.value ?? true) {
      _roll(from);
    } else {
      _waiting = from;
    }
  }

  @override
  void dispose() {
    _inSight?.removeListener(_cameIntoSight);
    _controller?.dispose();
    super.dispose();
  }

  bool _rolls(_Figure from) {
    final (:text, :value) = _shown;
    return !_hidden &&
        from.value != null &&
        value != null &&
        from.value != value &&
        _unitOf(from.text) == _unitOf(text);
  }

  void _cameIntoSight() {
    final from = _waiting;
    if (from == null || !_inSight!.value || !mounted) return;
    setState(() {
      _waiting = null;
      if (_rolls(from)) _roll(from);
    });
  }

  void _roll(_Figure from) {
    final controller = _controller ??= AnimationController(vsync: this)
      ..addStatusListener(_rolled);
    _from = from;
    controller.duration = widget.rise == null
        ? BirkaMotion.roll
        : BirkaMotion.roll + BirkaMotion.slow;
    unawaited(controller.forward(from: 0));
  }

  void _rolled(AnimationStatus status) {
    if (status.isCompleted && mounted) setState(() => _from = null);
  }

  void _settle() {
    _controller?.stop();
    _from = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final style = (widget.style ?? BirkaTextStyles.of(context).amount).copyWith(
      color: switch (widget.tone) {
        AmountTone.neutral => null,
        AmountTone.positive => colors.positive,
        AmountTone.negative => colors.negative,
        AmountTone.muted => colors.textMuted,
      },
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final from = _from;
    final controller = _controller;
    final Widget figure;
    if (from == null || controller == null) {
      final text = (_waiting ?? _shown).text;
      figure = Text(
        widget.alwaysShown ? text : HiddenAmounts.mask(context, text),
        maxLines: 1,
        softWrap: false,
        style: style,
      );
    } else {
      final base = DefaultTextStyle.of(context).style.merge(style);
      figure = AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _rolling(from, base, controller),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: figure,
    );
  }

  Widget _rolling(_Figure from, TextStyle base, AnimationController roll) {
    final (:text, :value) = _shown;
    final grew = value! > from.value!;
    final ms = roll.value * roll.duration!.inMilliseconds;
    final rolled = BirkaMotion.reduced(context)
        ? 1.0
        : BirkaMotion.standardCurve.transform(
            (ms / BirkaMotion.roll.inMilliseconds).clamp(0, 1),
          );
    final rise = widget.rise;
    final colors = BirkaColors.of(context);
    final news = rise == null
        ? null
        : grew == (rise == AmountRise.good)
        ? colors.positive
        : colors.negative;
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: _RollingFigure(
          from: from.text,
          to: text,
          up: value.abs() > from.value!.abs(),
          rolled: rolled,
          style: base.copyWith(
            color: Color.lerp(base.color, news, news == null ? 0 : _glow(ms)),
          ),
        ),
      ),
    );
  }

  /// How strongly a figure shows its news [ms] into a roll: it comes over
  /// `duration.fast`, stays while the digits roll, and goes over
  /// `duration.slow` once they settle.
  static double _glow(double ms) {
    final come = BirkaMotion.fast.inMilliseconds;
    final roll = BirkaMotion.roll.inMilliseconds;
    final go = BirkaMotion.slow.inMilliseconds;
    if (ms < come) return BirkaMotion.fadeCurve.transform(ms / come);
    if (ms < roll) return 1;
    return 1 - BirkaMotion.fadeCurve.transform(((ms - roll) / go).clamp(0, 1));
  }

  static final _notUnit = RegExp(r"[\d\s.,'’+\-−]");

  /// What is left of [text] without its number, such as the currency.
  static String _unitOf(String text) => text.replaceAll(_notUnit, '');
}

/// A figure on its way from [from] to [to], [rolled] of the way.
///
/// When both have the same shape, which is the usual case, only the digits
/// that differ roll, each through the digits between. Otherwise the whole
/// figure rolls out and the new one rolls in.
class _RollingFigure extends StatelessWidget {
  const _RollingFigure({
    required this.from,
    required this.to,
    required this.up,
    required this.rolled,
    required this.style,
  });

  final String from;
  final String to;
  final bool up;
  final double rolled;
  final TextStyle style;

  static final _digit = RegExp(r'\d');

  @override
  Widget build(BuildContext context) {
    if (from.replaceAll(_digit, '0') != to.replaceAll(_digit, '0')) {
      return _Swap(from: from, to: to, up: up, rolled: rolled, style: style);
    }
    final parts = <Widget>[];
    var still = StringBuffer();
    for (var i = 0; i < to.length; i++) {
      if (from[i] == to[i]) {
        still.write(to[i]);
        continue;
      }
      if (still.isNotEmpty) {
        parts.add(Text(still.toString(), style: style));
        still = StringBuffer();
      }
      parts.add(
        _Digit(
          from: int.parse(from[i]),
          to: int.parse(to[i]),
          up: up,
          rolled: rolled,
          style: style,
        ),
      );
    }
    if (still.isNotEmpty) parts.add(Text(still.toString(), style: style));
    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }
}

/// A digit that rolls from [from] to [to] through the digits between, up or
/// down, past 9 and 0 if it has to.
class _Digit extends StatelessWidget {
  const _Digit({
    required this.from,
    required this.to,
    required this.up,
    required this.rolled,
    required this.style,
  });

  final int from;
  final int to;
  final bool up;
  final double rolled;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final steps = (up ? to - from : from - to) % 10;
    final position = rolled * steps;
    final passed = position.floor();
    final share = position - passed;
    final step = up ? 1 : -1;
    final current = (from + step * passed) % 10;
    return ClipRect(
      child: Stack(
        children: [
          FractionalTranslation(
            translation: Offset(0, up ? -share : share),
            child: Text('$current', style: style),
          ),
          if (share > 0)
            FractionalTranslation(
              translation: Offset(0, up ? 1 - share : share - 1),
              child: Text('${(current + step) % 10}', style: style),
            ),
        ],
      ),
    );
  }
}

/// A figure that rolls out while another one, of another shape, rolls in.
class _Swap extends StatelessWidget {
  const _Swap({
    required this.from,
    required this.to,
    required this.up,
    required this.rolled,
    required this.style,
  });

  final String from;
  final String to;
  final bool up;
  final double rolled;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipper: const _AboveAndBelow(),
      child: Stack(
        children: [
          FractionalTranslation(
            translation: Offset(0, up ? 1 - rolled : rolled - 1),
            child: Text(to, maxLines: 1, softWrap: false, style: style),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            child: FractionalTranslation(
              translation: Offset(0, up ? -rolled : rolled),
              child: Text(from, maxLines: 1, softWrap: false, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips what goes above or below, and lets a longer figure stick out to the
/// side while it rolls away.
class _AboveAndBelow extends CustomClipper<Rect> {
  const _AboveAndBelow();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width, 0, size.width * 2, size.height);

  @override
  bool shouldReclip(_AboveAndBelow oldClipper) => false;
}
