import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// The way forward on a screen of its own: a light pill with its label at the
/// start and an arrow in a dark circle at the end.
class BirkaArrowButton extends StatelessWidget {
  /// Creates a button. Without [onPressed] it is disabled.
  const BirkaArrowButton({required this.label, this.onPressed, super.key});

  /// What the button says.
  final String label;

  /// Called on a tap.
  final VoidCallback? onPressed;

  /// The height of the pill.
  static const double height = 60;

  static const double _inset = (height - BirkaTokens.sizeTouchTarget) / 2;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final onPressed = this.onPressed;
    return Semantics(
      container: true,
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
            padding: const EdgeInsets.fromLTRB(
              BirkaTokens.spaceXl,
              _inset,
              _inset,
              _inset,
            ),
            decoration: BoxDecoration(
              color: colors.text,
              borderRadius: const BorderRadius.all(
                Radius.circular(BirkaTokens.radiusPill),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BirkaTextStyles.of(
                      context,
                    ).bodyStrong.copyWith(color: colors.background),
                  ),
                ),
                const SizedBox(width: BirkaTokens.spaceXs),
                Container(
                  width: BirkaTokens.sizeTouchTarget,
                  height: BirkaTokens.sizeTouchTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.background,
                    shape: BoxShape.circle,
                  ),
                  child: BirkaIcon(
                    BirkaGlyph.rise,
                    size: 20,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
