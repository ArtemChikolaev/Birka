import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A pill to pick one option out of a few.
class BirkaChip extends StatelessWidget {
  /// Creates a chip.
  const BirkaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// What the chip says.
  final String label;

  /// Whether this option is picked.
  final bool selected;

  /// Called on a tap. Without it the chip cannot change.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: BirkaTokens.durationFastMs),
          height: BirkaTokens.sizeTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: BirkaTokens.spaceMd),
          decoration: BoxDecoration(
            color: selected ? colors.text : colors.surfaceRaised,
            borderRadius: const BorderRadius.all(
              Radius.circular(BirkaTokens.radiusPill),
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: BirkaTextStyles.of(context).bodyStrong.copyWith(
                color: selected ? colors.background : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
