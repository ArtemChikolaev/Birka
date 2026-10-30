import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A round button of glass with an icon, such as the way back from a screen.
class GlassIconButton extends StatelessWidget {
  /// Creates a button with [glyph]. Screen readers read [label].
  const GlassIconButton({
    required this.glyph,
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// What the button shows.
  final BirkaGlyph glyph;

  /// What the button does, for screen readers.
  final String label;

  /// Called on a tap.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: GlassSurface(
          borderRadius: const BorderRadius.all(
            Radius.circular(BirkaTokens.radiusPill),
          ),
          padding: EdgeInsets.zero,
          child: SizedBox.square(
            dimension: BirkaTokens.sizeTouchTarget,
            child: Center(child: BirkaIcon(glyph)),
          ),
        ),
      ),
    );
  }
}
