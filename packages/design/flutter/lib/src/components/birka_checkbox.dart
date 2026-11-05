import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A box that ticks, in a place as large as a finger, as on the site: it
/// fills with emerald and shows a check when [checked].
class BirkaCheckbox extends StatelessWidget {
  /// Creates a box that [checked] says is ticked.
  const BirkaCheckbox({
    required this.checked,
    required this.label,
    required this.onChanged,
    super.key,
  });

  /// Whether the box is ticked.
  final bool checked;

  /// What the box picks, for screen readers.
  final String label;

  /// Called with the new state on a tap; without it the box cannot change.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final onChanged = this.onChanged;
    final duration = BirkaMotion.reduced(context)
        ? Duration.zero
        : BirkaMotion.fast;
    return Semantics(
      container: true,
      checked: checked,
      enabled: onChanged != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged(!checked),
        child: SizedBox.square(
          dimension: BirkaTokens.sizeTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? colors.accent : const Color(0x00000000),
                border: Border.all(
                  color: checked ? colors.accent : colors.textSubtle,
                  width: 2,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(BirkaTokens.radiusXs),
                ),
              ),
              child: AnimatedOpacity(
                duration: duration,
                opacity: checked ? 1 : 0,
                child: BirkaIcon(
                  BirkaGlyph.check,
                  size: 16,
                  color: colors.onAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
