import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A big glass button with its icon over its label, such as the actions
/// under an operation or on the card of a debt. Without [onTap] it fades
/// and does nothing.
class GlassActionTile extends StatelessWidget {
  /// Creates a tile.
  const GlassActionTile({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.accent = false,
    super.key,
  });

  /// The icon.
  final BirkaGlyph glyph;

  /// What the tile does.
  final String label;

  /// Called on a tap, or `null` while the tile can do nothing.
  final VoidCallback? onTap;

  /// Whether the action deletes or undoes something.
  final bool danger;

  /// Whether the action is the main one, in the accent.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final ink = danger
        ? colors.negative
        : accent
        ? colors.accent
        : colors.text;
    final onTap = this.onTap;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.4 : 1,
          duration: BirkaMotion.reduced(context)
              ? Duration.zero
              : BirkaMotion.fast,
          // Narrow side padding leaves room for three tiles in a row.
          child: GlassSurface(
            padding: const EdgeInsets.symmetric(
              horizontal: BirkaTokens.spaceXs,
              vertical: BirkaTokens.spaceMd,
            ),
            child: Column(
              children: [
                BirkaIcon(glyph, color: ink),
                const SizedBox(height: BirkaTokens.spaceXs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: BirkaTextStyles.of(
                    context,
                  ).bodyStrong.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
