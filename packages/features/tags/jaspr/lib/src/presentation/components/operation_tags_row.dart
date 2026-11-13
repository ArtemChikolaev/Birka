import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';
import 'package:tags_jaspr/src/presentation/components/tag_picker.dart';

/// The метки on the card of an operation, as the board «Операция на сайте ·
/// метка» draws it (ADR 0027): each метка that it wears leads to its report,
/// and an operation without one offers «Добавить метку», which opens the
/// [TagPicker] under it. A pick there puts the метки on at once, and
/// «Готово» closes it.
///
/// It needs an [OperationTagsCubit] and a [TagPickerCubit] above it.
class OperationTagsRow extends StatefulComponent {
  /// Creates the row.
  const OperationTagsRow({required this.hrefOf, super.key});

  /// Where the report of the метка with this id opens.
  final String Function(String id) hrefOf;

  @override
  State<OperationTagsRow> createState() => _OperationTagsRowState();

  /// The styles of the row.
  @css
  static List<StyleRule> get styles => [
    // The picker keeps the gap of its fold from the row above it.
    css('.operation-tags').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.operation-tags .birka-fold__body > .birka-button').styles(
      raw: {'align-self': 'flex-end'},
    ),
  ];
}

class _OperationTagsRowState extends State<OperationTagsRow> {
  /// Whether the picker is open under the row.
  var _picking = false;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<OperationTagsCubit, OperationTagsState>(
      builder: (context, state) {
        if (!state.read || !state.can) return const div([]);
        final cubit = context.read<OperationTagsCubit>();
        return div(classes: 'operation-tags', [
          GlassListGroup(
            children: [
              if (state.worn.isEmpty)
                GlassListRow(
                  key: const ValueKey('add'),
                  leading: const GlyphBadge(
                    glyph: BirkaGlyph.tag,
                    color: 'var(--color-text-muted)',
                  ),
                  title: t.tags.row.add,
                  subtitle: t.tags.row.addText,
                  chevron: true,
                  onTap: () => setState(() => _picking = !_picking),
                )
              else
                for (final worn in state.worn)
                  GlassListRow(
                    key: ValueKey(worn.tag.id),
                    leading: GlyphBadge(
                      glyph: worn.tag.isTrip
                          ? BirkaGlyph.plane
                          : BirkaGlyph.tag,
                      color: 'var(--color-accent)',
                    ),
                    title: worn.tag.name,
                    subtitle: _line(worn, state.today),
                    href: component.hrefOf(worn.tag.id),
                    chevron: true,
                  ),
            ],
          ),
          BirkaFold(
            open: _picking,
            gap: 'var(--space-sm)',
            children: [
              TagPicker(
                picked: state.picked,
                onChanged: (ids) => unawaited(cubit.pick(ids)),
              ),
              BirkaButton(
                label: t.tags.form.done,
                quiet: true,
                compact: true,
                onPressed: () => setState(() => _picking = false),
              ),
            ],
          ),
        ]);
      },
    );
  }

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
