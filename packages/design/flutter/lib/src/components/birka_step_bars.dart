import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// How far a few steps have come: a bar for each, lit up to the current one.
class BirkaStepBars extends StatelessWidget {
  /// Creates the bars. [current] counts from zero.
  const BirkaStepBars({required this.count, required this.current, super.key});

  /// How many steps there are.
  final int count;

  /// The step on the screen.
  final int current;

  static const double _height = 4;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Semantics(
      container: true,
      value: '${current + 1} / $count',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var step = 0; step < count; step++) ...[
            if (step > 0) const SizedBox(width: BirkaTokens.spaceXs),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: BirkaTokens.durationBaseMs,
                ),
                height: _height,
                decoration: BoxDecoration(
                  color: step <= current ? colors.accent : colors.surfaceRaised,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(BirkaTokens.radiusPill),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
