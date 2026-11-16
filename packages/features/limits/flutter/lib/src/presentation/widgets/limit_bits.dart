import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';

/// The color of a limit: emerald while it lasts, amber from 80 % and coral
/// over it (ADR 0033).
Color limitColor(BuildContext context, LimitState state) => switch (state) {
  LimitState.ok => BirkaColors.of(context).accent,
  LimitState.near => const Color(BirkaTokens.colorPaletteAmber),
  LimitState.over => BirkaColors.of(context).negative,
};

/// The color of the note under a limit: muted while it lasts.
Color limitNoteColor(BuildContext context, LimitState state) =>
    state == LimitState.ok
    ? BirkaColors.of(context).textMuted
    : limitColor(context, state);

/// The icon of [category] in its own color.
class CategoryBadge extends StatelessWidget {
  /// Creates the icon of [category].
  const CategoryBadge(this.category, {this.size = 36, super.key});

  /// The category.
  final Category category;

  /// The size of the badge.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return ExcludeSemantics(
      child: GlyphBadge(
        glyph: BirkaGlyph.named(category.icon),
        color: color == null
            ? BirkaColors.of(context).textSubtle
            : BirkaColors.fromHex(color),
        size: size,
      ),
    );
  }
}
