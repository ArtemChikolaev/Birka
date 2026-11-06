import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:import_common/import_common.dart';
import 'package:l10n/l10n.dart';

/// Lists the rows of the file of [state] that will not go in, as their board
/// draws them: those that did not read, those that the bank declined and
/// those that do not fit their account, each with its operation and its row,
/// and what to do about the unread ones.
Future<void> showLeftRows(BuildContext context, ImportState state) {
  final colors = BirkaColors.of(context);
  final statement = state.statement!;
  final unread = unreadRows(statement);
  final declined = declinedRows(statement);
  final unfit = state.plan?.problems ?? const <PlanProblem>[];
  final left = unread.length + declined.length + unfit.length;
  final fine = statement.rows.length - unfit.length;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: colors.background,
    builder: (context) => ChoiceSheet(
      title: t.imports.rowsLeft(n: left, count: formatCount(left)),
      subtitle: [
        ?state.fileName,
        t.imports.restFine(n: fine, count: formatCount(fine)),
      ].join(' · '),
      children: [
        if (unread.isNotEmpty)
          _Group(
            title: t.imports.unreadTitle,
            rows: [for (final problem in unread) rowProblemLabel(problem)],
            glyph: BirkaGlyph.alert,
            color: colors.negative,
          ),
        if (declined.isNotEmpty)
          _Group(
            title: t.imports.declinedTitle,
            rows: [for (final problem in declined) rowProblemLabel(problem)],
            glyph: BirkaGlyph.close,
            color: colors.textMuted,
          ),
        if (unfit.isNotEmpty)
          _Group(
            title: t.imports.unfitTitle,
            rows: [for (final problem in unfit) planProblemLabel(problem)],
            glyph: BirkaGlyph.alert,
            color: const Color(BirkaTokens.colorPaletteAmber),
          ),
        if (unread.isNotEmpty) ...[
          Text(
            t.imports.leftNote,
            style: BirkaTextStyles.of(
              context,
            ).caption.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
        ],
        BirkaButton(
          label: t.imports.understood,
          quiet: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// The rows of one kind under its heading, at most [_shown] of them.
class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.rows,
    required this.glyph,
    required this.color,
  });

  final String title;
  final List<LeftRow> rows;
  final BirkaGlyph glyph;
  final Color color;

  /// How many rows a kind shows; «и ещё N» stands for the rest.
  static const _shown = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(title),
          const SizedBox(height: BirkaTokens.spaceXs),
          GlassListGroup(
            children: [
              for (final row in rows.take(_shown))
                GlassListRow(
                  title: row.title,
                  subtitle: row.line,
                  subtitleLines: 2,
                  leading: GlyphBadge(glyph: glyph, color: color, size: 32),
                ),
            ],
          ),
          if (rows.length > _shown)
            Padding(
              padding: const EdgeInsets.only(top: BirkaTokens.spaceXs),
              child: Text(
                t.imports.andMore(count: formatCount(rows.length - _shown)),
                style: BirkaTextStyles.of(
                  context,
                ).caption.copyWith(color: BirkaColors.of(context).textSubtle),
              ),
            ),
        ],
      ),
    );
  }
}
