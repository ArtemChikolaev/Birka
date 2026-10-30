import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A row of a few options of equal width with one picked, such as expenses
/// and income.
class GlassSegmented<T> extends StatelessWidget {
  /// Creates a control. [segments] maps every option to its label.
  const GlassSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The options and their labels, as written, not in capitals.
  final Map<T, String> segments;

  /// The picked option.
  final T selected;

  /// Called with the option that was tapped.
  final ValueChanged<T> onChanged;

  /// The height of the control.
  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    const radius = BorderRadius.all(Radius.circular(BirkaTokens.radiusMd));
    return Container(
      height: height,
      padding: const EdgeInsets.all(BirkaTokens.spaceXxs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusLg),
        ),
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: value, value: label) in segments.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: BirkaTokens.durationFastMs,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected
                          ? colors.surfaceSelected
                          : const Color(0x00000000),
                      borderRadius: radius,
                    ),
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.label.copyWith(
                        color: value == selected
                            ? colors.text
                            : colors.textSubtle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
