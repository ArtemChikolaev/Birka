import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';

/// The way to «Спросить» in the header of the overview: a glass button with
/// a magnifier, before the bell.
class AskButton extends StatelessWidget {
  /// Creates the button.
  const AskButton({required this.onOpen, super.key});

  /// Opens «Спросить».
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => GlassIconButton(
    glyph: BirkaGlyph.search,
    label: t.ask.open,
    onPressed: onOpen,
  );
}
