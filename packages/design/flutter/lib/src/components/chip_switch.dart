import 'dart:math';

import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A row of chips with one picked, such as the periods of a chart or the
/// types of an account. The white pill of the picked chip slides to the chip
/// that is tapped over `duration.spring`, and the labels change their color
/// as it passes; when the system asks for less motion, the pill moves at once.
class ChipSwitch<T> extends StatelessWidget {
  /// Creates a switch. [options] maps every option to its label.
  const ChipSwitch({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.wrap = false,
    this.compact = false,
    super.key,
  });

  /// The options and their labels.
  final Map<T, String> options;

  /// The picked option.
  final T selected;

  /// Called with the option that was tapped. Without it the switch cannot
  /// change.
  final ValueChanged<T>? onChanged;

  /// Whether the chips go on to more lines when they do not fit in one,
  /// instead of shrinking to fit.
  final bool wrap;

  /// Whether the chips leave less room around their labels, for a row of
  /// many, as a compact `BirkaChip` does.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = BirkaTextStyles.of(context).bodyStrong;
    final widths = [
      for (final label in options.values) _widthOf(context, label, style),
    ];
    if (!wrap) {
      final line = _lay(widths, double.infinity);
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox.fromSize(
          size: line.size,
          child: _chips(context, line, style),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final lines = _lay(widths, constraints.maxWidth);
        return SizedBox.fromSize(
          size: constraints.constrain(lines.size),
          child: _chips(context, lines, style),
        );
      },
    );
  }

  /// Where the chips of [widths] stand, in lines no wider than [room].
  static _Layout _lay(List<double> widths, double room) {
    const height = BirkaTokens.sizeTouchTarget;
    const gap = BirkaTokens.spaceXs;
    final places = <Rect>[];
    var start = 0.0;
    var top = 0.0;
    var widest = 0.0;
    for (final width in widths) {
      if (start > 0 && start + width > room) {
        start = 0;
        top += height + gap;
      }
      final place = Rect.fromLTWH(start, top, min(width, room), height);
      places.add(place);
      widest = max(widest, place.right);
      start = place.right + gap;
    }
    final bottom = places.isEmpty ? 0.0 : top + height;
    return _Layout(places, Size(widest, bottom));
  }

  Widget _chips(BuildContext context, _Layout layout, TextStyle style) {
    final colors = BirkaColors.of(context);
    final places = layout.places;
    final picked = options.keys.toList().indexOf(selected);
    final duration = BirkaMotion.reduced(context)
        ? Duration.zero
        : BirkaMotion.spring;
    final onChanged = this.onChanged;
    const pill = BorderRadius.all(Radius.circular(BirkaTokens.radiusPill));
    return Stack(
      children: [
        for (final place in places)
          PositionedDirectional(
            start: place.left,
            top: place.top,
            width: place.width,
            height: place.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: pill,
              ),
            ),
          ),
        if (picked >= 0)
          AnimatedPositionedDirectional(
            duration: duration,
            curve: BirkaMotion.springCurve,
            start: places[picked].left,
            top: places[picked].top,
            width: places[picked].width,
            height: places[picked].height,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.text, borderRadius: pill),
            ),
          ),
        for (final (index, MapEntry(key: value, value: label))
            in options.entries.indexed)
          PositionedDirectional(
            start: places[index].left,
            top: places[index].top,
            width: places[index].width,
            height: places[index].height,
            child: Semantics(
              button: true,
              selected: index == picked,
              enabled: onChanged != null,
              label: label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null ? null : () => onChanged(value),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: _padding),
                    child: AnimatedDefaultTextStyle(
                      duration: duration == Duration.zero
                          ? Duration.zero
                          : BirkaMotion.base,
                      style: style.copyWith(
                        color: index == picked
                            ? colors.background
                            : colors.textSecondary,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The room on each side of a label.
  double get _padding => compact ? BirkaTokens.spaceSm : BirkaTokens.spaceMd;

  /// How wide the chip of [label] is: the label and room on both sides.
  double _widthOf(BuildContext context, String label, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceilToDouble() + _padding * 2;
  }
}

/// Where each chip of a [ChipSwitch] stands, and how much room they take.
class _Layout {
  const _Layout(this.places, this.size);

  final List<Rect> places;
  final Size size;
}
