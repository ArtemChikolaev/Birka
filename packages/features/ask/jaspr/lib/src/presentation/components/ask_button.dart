import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// The way to «Спросить» in the header of the overview: a glass magnifier
/// (ADR 0028).
class AskButton extends StatelessComponent {
  /// Creates the button that leads to [href].
  const AskButton({required this.href, super.key});

  /// Where «Спросить» opens.
  final String href;

  @override
  Component build(BuildContext context) {
    return GlassIconButton(
      glyph: BirkaGlyph.search,
      label: t.ask.open,
      href: href,
    );
  }
}
