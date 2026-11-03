import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A row of chips with one picked, such as the periods of a chart. The white
/// pill of the picked chip slides to the chip that is tapped over
/// `duration.spring`, and the labels change their color as it passes; when
/// the system asks for less motion, the pill moves at once.
class ChipSwitch<T> extends StatelessWidget {
  /// Creates a switch. [options] maps every option to its label.
  const ChipSwitch({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The options and their labels.
  final Map<T, String> options;

  /// The picked option.
  final T selected;

  /// Called with the option that was tapped.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final style = BirkaTextStyles.of(context).bodyStrong;
    final widths = [
      for (final label in options.values) _widthOf(context, label, style),
    ];
    final starts = <double>[];
    var end = 0.0;
    for (final width in widths) {
      if (starts.isNotEmpty) end += BirkaTokens.spaceXs;
      starts.add(end);
      end += width;
    }
    final picked = options.keys.toList().indexOf(selected);
    final duration = BirkaMotion.reduced(context)
        ? Duration.zero
        : BirkaMotion.spring;
    const pill = BorderRadius.all(Radius.circular(BirkaTokens.radiusPill));
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: end,
        height: BirkaTokens.sizeTouchTarget,
        child: Stack(
          children: [
            for (final (index, width) in widths.indexed)
              PositionedDirectional(
                start: starts[index],
                width: width,
                top: 0,
                bottom: 0,
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
                start: starts[picked],
                width: widths[picked],
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.text,
                    borderRadius: pill,
                  ),
                ),
              ),
            for (final (index, MapEntry(key: value, value: label))
                in options.entries.indexed)
              PositionedDirectional(
                start: starts[index],
                width: widths[index],
                top: 0,
                bottom: 0,
                child: Semantics(
                  button: true,
                  selected: index == picked,
                  label: label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(value),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: duration == Duration.zero
                            ? Duration.zero
                            : BirkaMotion.base,
                        style: style.copyWith(
                          color: index == picked
                              ? colors.background
                              : colors.textSecondary,
                        ),
                        child: Text(label, maxLines: 1, softWrap: false),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// How wide the chip of [label] is: the label and room on both sides.
  static double _widthOf(BuildContext context, String label, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceilToDouble() + BirkaTokens.spaceSm * 2;
  }
}
