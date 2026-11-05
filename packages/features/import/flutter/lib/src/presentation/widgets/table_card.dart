import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:import_common/import_common.dart';
import 'package:l10n/l10n.dart';

/// The card of a file of no format that Birka knows: its name, and how many
/// columns and rows it has.
class TableCard extends StatelessWidget {
  /// Creates the card of [table].
  const TableCard({required this.table, super.key});

  /// The table of the file.
  final StatementTable table;

  @override
  Widget build(BuildContext context) {
    final columns = table.width;
    final rows = table.rows.length;
    return GlassFileCard(
      mark: const GlyphBadge(
        glyph: BirkaGlyph.file,
        color: Color(BirkaTokens.colorPaletteAmber),
      ),
      name: table.fileName,
      line: [
        t.imports.columnsCount(n: columns, count: formatCount(columns)),
        t.imports.rowsCount(n: rows, count: formatCount(rows)),
      ].join(' · '),
    );
  }
}
