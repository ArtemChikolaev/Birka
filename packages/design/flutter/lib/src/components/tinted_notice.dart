import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glyph_badge.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A box tinted with [color] that says what the person should know before
/// going on, such as the columns that a file still lacks: an optional
/// [title] in that color over the [text], and the mark of [glyph] before
/// them.
class TintedNotice extends StatelessWidget {
  /// Creates a notice.
  const TintedNotice({
    required this.color,
    required this.text,
    this.title,
    this.glyph,
    super.key,
  });

  /// The color of the tint, of the title and of the mark.
  final Color color;

  /// What the notice says.
  final String text;

  /// The heading over [text], which then gets quieter.
  final String? title;

  /// The mark before the words.
  final BirkaGlyph? glyph;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final title = this.title;
    final glyph = this.glyph;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title, style: styles.bodyStrong.copyWith(color: color)),
          const SizedBox(height: BirkaTokens.spaceXxs),
        ],
        Text(
          text,
          style: styles.body.copyWith(
            color: title == null ? colors.text : colors.textSecondary,
          ),
        ),
      ],
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BirkaTokens.spaceMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusMd),
        ),
      ),
      child: glyph == null
          ? words
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: GlyphBadge(glyph: glyph, color: color),
                ),
                const SizedBox(width: BirkaTokens.spaceSm),
                Expanded(child: words),
              ],
            ),
    );
  }
}
