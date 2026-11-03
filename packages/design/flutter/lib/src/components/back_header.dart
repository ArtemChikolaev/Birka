import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_icon_button.dart';
import 'package:design_flutter/src/components/section_label.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// The top line of a page that leads back: the way back, what the page is
/// about in the middle, and what can be done to it at the other end.
class BackHeader extends StatelessWidget {
  /// Creates a header that says [label].
  const BackHeader({
    required this.label,
    required this.backLabel,
    required this.onBack,
    this.trailing,
    super.key,
  });

  /// What the page is about.
  final String label;

  /// What the way back says to screen readers.
  final String backLabel;

  /// Called by the way back.
  final VoidCallback onBack;

  /// What stands at the other end of the line, such as a button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassIconButton(
          glyph: BirkaGlyph.back,
          label: backLabel,
          onPressed: onBack,
        ),
        Expanded(
          child: Center(
            child: SectionLabel(
              label,
              color: BirkaColors.of(context).textMuted,
            ),
          ),
        ),
        // Keeps the label in the middle when the other end stays empty.
        trailing ?? const SizedBox(width: BirkaTokens.sizeTouchTarget),
      ],
    );
  }
}
