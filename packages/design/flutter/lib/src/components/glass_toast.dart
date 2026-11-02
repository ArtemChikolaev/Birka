import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A short message on glass: what came of an action, after a check mark, or
/// what went wrong, after a cross.
class GlassToast extends StatelessWidget {
  /// Creates a message that says [text].
  const GlassToast(this.text, {this.trouble = false, super.key});

  /// What it says.
  final String text;

  /// Whether it says that something went wrong.
  final bool trouble;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return GlassSurface(
      child: Row(
        children: [
          BirkaIcon(
            trouble ? BirkaGlyph.close : BirkaGlyph.check,
            size: 20,
            color: trouble ? colors.negative : colors.accent,
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: Text(
              text,
              style: BirkaTextStyles.of(
                context,
              ).body.copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [text] in a [GlassToast] over the bottom of the screen for a few
/// seconds, in place of the message before it. It needs a [Scaffold].
void showGlassToast(BuildContext context, String text, {bool trouble = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: GlassToast(text, trouble: trouble),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          BirkaTokens.spaceLg,
          0,
          BirkaTokens.spaceLg,
          BirkaTokens.spaceLg,
        ),
      ),
    );
}
