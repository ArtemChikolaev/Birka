import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A link in the accent: its [label] and a chevron, tall enough to hit, such
/// as «Все регулярные · 6» under a card or «Включить напоминания» under a
/// line. One that acts where it stands, such as «Прочитать все», goes
/// without the chevron.
class AccentLink extends StatelessWidget {
  /// Creates the link.
  const AccentLink({
    required this.label,
    required this.onTap,
    this.expand = false,
    this.chevron = true,
    super.key,
  });

  /// What it says.
  final String label;

  /// Called on a tap.
  final VoidCallback onTap;

  /// Whether it spans its width with the chevron at the end, rather than
  /// hugging its label.
  final bool expand;

  /// Whether the chevron follows the label: a link that leads somewhere has
  /// it, and one that acts where it stands has none.
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final text = Text(
      label,
      style: BirkaTextStyles.of(
        context,
      ).bodyStrong.copyWith(color: colors.accent),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (expand) Expanded(child: text) else text,
              if (chevron) ...[
                if (!expand) const SizedBox(width: BirkaTokens.spaceXxs),
                BirkaIcon(BirkaGlyph.chevron, size: 16, color: colors.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
