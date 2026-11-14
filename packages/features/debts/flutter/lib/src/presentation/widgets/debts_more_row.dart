import 'package:debts_common/debts_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// The row of the debts in «Ещё» (ADR 0029): what others owe and what the
/// person owes, or what the page is for while there are no debts.
///
/// It needs a [DebtsCubit] above it.
class DebtsMoreRow extends StatelessWidget {
  /// Creates the row.
  const DebtsMoreRow({required this.onOpen, super.key});

  /// Opens the list of debts.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return BlocBuilder<DebtsCubit, DebtsState>(
      builder: (context, state) => GlassListRow(
        leading: ExcludeSemantics(
          child: GlyphBadge(glyph: BirkaGlyph.people, color: colors.accent),
        ),
        title: t.debts.title,
        subtitle: state.status == DebtsStatus.ready
            ? HiddenAmounts.mask(context, debtsMoreLine(state))
            : t.debts.moreHint,
        trailing: BirkaIcon(
          BirkaGlyph.chevron,
          size: 18,
          color: colors.textSubtle,
        ),
        onTap: onOpen,
      ),
    );
  }
}
