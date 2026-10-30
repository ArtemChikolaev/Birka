import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// The main action of a screen: an emerald pill with a label in capitals.
class BirkaButton extends StatelessWidget {
  /// Creates a button. Without [onPressed] it is disabled.
  const BirkaButton({
    required this.label,
    this.onPressed,
    this.quiet = false,
    super.key,
  });

  /// The label as written, not in capitals.
  final String label;

  /// Called on a tap.
  final VoidCallback? onPressed;

  /// Whether this is the second choice next to a main action, with no
  /// emerald.
  final bool quiet;

  /// The height of the pill.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final onPressed = this.onPressed;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: AnimatedOpacity(
          opacity: onPressed == null ? 0.5 : 1,
          duration: const Duration(milliseconds: BirkaTokens.durationFastMs),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: BirkaTokens.spaceLg,
            ),
            decoration: BoxDecoration(
              color: quiet ? colors.surfaceRaised : colors.accent,
              borderRadius: const BorderRadius.all(
                Radius.circular(BirkaTokens.radiusPill),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BirkaTextStyles.of(
                context,
              ).label.copyWith(color: quiet ? colors.text : colors.onAccent),
            ),
          ),
        ),
      ),
    );
  }
}
