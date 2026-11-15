import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// The row of the widgets in «Ещё» (ADR 0031).
class WidgetsMoreRow extends StatelessWidget {
  /// Creates the row.
  const WidgetsMoreRow({required this.onOpen, super.key});

  /// Opens the page of the widgets.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final android = Theme.of(context).platform == TargetPlatform.android;
    return GlassListRow(
      leading: ExcludeSemantics(
        child: GlyphBadge(glyph: BirkaGlyph.widgets, color: colors.accent),
      ),
      title: t.widgets.title,
      subtitle: android ? t.widgets.moreLineAndroid : t.widgets.moreLine,
      trailing: BirkaIcon(
        BirkaGlyph.chevron,
        size: 18,
        color: colors.textSubtle,
      ),
      onTap: onOpen,
    );
  }
}
