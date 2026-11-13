import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';

/// The метки on the card of an operation, as the board «Операция · метка»
/// draws it (ADR 0027): each метка that it wears leads to its report, and an
/// operation without one offers «Добавить метку». It keeps the space under
/// it, so that it can close with it.
///
/// It needs an [OperationTagsCubit] above it.
class OperationTagsRow extends StatelessWidget {
  /// Creates the row.
  const OperationTagsRow({
    required this.onOpen,
    required this.onPick,
    super.key,
  });

  /// Opens the report of a метка, by its id.
  final ValueChanged<String> onOpen;

  /// Lets the person pick the метки, starting from those that the operation
  /// wears, and completes with the ones picked.
  final Future<Set<String>?> Function(BuildContext context, Set<String> picked)
  onPick;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return BlocBuilder<OperationTagsCubit, OperationTagsState>(
      builder: (context, state) => AnimatedColumn(
        children: [
          if (state.read && state.can)
            Padding(
              key: const ValueKey('tags'),
              padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
              child: GlassListGroup(
                children: [
                  if (state.worn.isEmpty)
                    GlassListRow(
                      key: const ValueKey('add'),
                      leading: ExcludeSemantics(
                        child: GlyphBadge(
                          glyph: BirkaGlyph.tag,
                          color: colors.textMuted,
                        ),
                      ),
                      title: t.tags.row.add,
                      subtitle: t.tags.row.addText,
                      trailing: _chevron(colors),
                      onTap: () => unawaited(_pick(context, state)),
                    )
                  else
                    for (final worn in state.worn)
                      GlassListRow(
                        key: ValueKey(worn.tag.id),
                        leading: ExcludeSemantics(
                          child: GlyphBadge(
                            glyph: worn.tag.isTrip
                                ? BirkaGlyph.plane
                                : BirkaGlyph.tag,
                            color: colors.accent,
                          ),
                        ),
                        title: worn.tag.name,
                        subtitle: _line(worn, state.today),
                        trailing: _chevron(colors),
                        onTap: () => onOpen(worn.tag.id),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, OperationTagsState state) async {
    final cubit = context.read<OperationTagsCubit>();
    final picked = await onPick(context, state.picked);
    if (picked != null && !cubit.isClosed) await cubit.pick(picked);
  }

  static Widget _chevron(BirkaColors colors) =>
      BirkaIcon(BirkaGlyph.chevron, size: 16, color: colors.textMuted);

  /// `Поездка · 3–12 ноября · по датам`, or `Метка`.
  static String _line(WornTag worn, CivilDate today) {
    final days = worn.tag.days;
    if (days == null) return t.tags.row.plain;
    final label = daysLabel(days, thisYear: today.year);
    return worn.mark == TagMark.days
        ? t.tags.row.byDays(days: label)
        : t.tags.row.trip(days: label);
  }
}
