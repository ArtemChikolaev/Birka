import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:import_common/import_common.dart';

/// The mark of a format: the first letter of its bank in its color, as on
/// the site, or the file of a format of one's own.
class FormatMark extends StatelessWidget {
  /// Creates the mark of [format].
  const FormatMark(this.format, {super.key});

  /// The format.
  final StatementFormat format;

  /// The color of [format].
  static Color colorOf(StatementFormat format) => Color(switch (format.id) {
    'alfa' => BirkaTokens.colorPaletteRuby,
    'tbank' => BirkaTokens.colorPaletteAmber,
    'sber' => BirkaTokens.colorPaletteGreen,
    'zenmoney' => BirkaTokens.colorPaletteEmerald400,
    'wise' => BirkaTokens.colorPaletteSky,
    'revolut' => BirkaTokens.colorPaletteViolet,
    _ => BirkaTokens.colorPaletteGray400,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnFormat(format)) {
      return GlyphBadge(
        glyph: BirkaGlyph.file,
        color: BirkaColors.of(context).accent,
      );
    }
    final color = colorOf(format);
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: const BorderRadius.all(
            Radius.circular(BirkaTokens.radiusSm),
          ),
        ),
        child: Text(
          formatLabel(format).substring(0, 1),
          style: BirkaTextStyles.of(context).bodyStrong.copyWith(color: color),
        ),
      ),
    );
  }
}
