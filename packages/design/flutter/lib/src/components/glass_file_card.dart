import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A file as a card of glass: its [mark], its [name] on one line, and a
/// quieter [line] about it, such as when it was made or what it holds.
class GlassFileCard extends StatelessWidget {
  /// Creates the card.
  const GlassFileCard({
    required this.mark,
    required this.name,
    required this.line,
    super.key,
  });

  /// What stands before the name, such as the badge of its kind.
  final Widget mark;

  /// The name of the file.
  final String name;

  /// What the card says about the file.
  final String line;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return GlassSurface(
      child: Row(
        children: [
          mark,
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
                Text(
                  line,
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
