import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A panel of glass with rows and thin lines between them.
class GlassListGroup extends StatelessWidget {
  /// Creates a group of [children], usually [GlassListRow]s.
  const GlassListGroup({required this.children, super.key});

  /// The rows.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final line = Padding(
      padding: const EdgeInsets.symmetric(horizontal: BirkaTokens.spaceMd),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: BirkaColors.of(context).hairline),
      ),
    );
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) line,
            child,
          ],
        ],
      ),
    );
  }
}

/// A row of a [GlassListGroup]: an optional [leading] widget, a [title] with
/// a [subtitle] under it and an optional [trailing] widget.
class GlassListRow extends StatelessWidget {
  /// Creates a row.
  const GlassListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  /// The main line.
  final String title;

  /// The quieter line under [title].
  final String? subtitle;

  /// What stands before the text, such as a small picture.
  final Widget? leading;

  /// What stands after the text, such as an amount or a switch.
  final Widget? trailing;

  /// Called on a tap. Without it the row is not a button.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final leading = this.leading;
    final trailing = this.trailing;
    final subtitle = this.subtitle;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BirkaTokens.sizeTouchTarget),
      child: Padding(
        padding: const EdgeInsets.all(BirkaTokens.spaceMd),
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: BirkaTokens.spaceSm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.bodyStrong.copyWith(color: colors.text),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.caption.copyWith(color: colors.textMuted),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: BirkaTokens.spaceSm),
              trailing,
            ],
          ],
        ),
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}
