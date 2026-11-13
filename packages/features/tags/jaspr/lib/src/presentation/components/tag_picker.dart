import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:tags_common/tags_common.dart';

/// The метки to put on an operation, as the board «Операция на сайте ·
/// метка» draws it (ADR 0027): a search that finds a метка or makes one,
/// and the метки as chips that pick several at once, the trip that goes on
/// first. A form cannot open over it on the site, so a метка made from the
/// search has no days; its page can give it some.
///
/// It needs a [TagPickerCubit] above it, which reads the метки and keeps the
/// search. The picked ones come from [picked], and every pick goes to
/// [onChanged] at once.
class TagPicker extends StatelessComponent {
  /// Creates the picker.
  const TagPicker({required this.picked, required this.onChanged, super.key});

  /// The ids of the метки that are picked.
  final Set<String> picked;

  /// Called with the ids of the метки picked after a click.
  final ValueChanged<Set<String>> onChanged;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<TagPickerCubit, TagPickerState>(
      builder: (context, state) {
        final cubit = context.read<TagPickerCubit>();
        final tags = [...state.trips, ...state.plain];
        return div(classes: 'glass tag-picker', [
          GlassSearchField(
            label: t.tags.picker.search,
            clearLabel: t.tags.picker.clear,
            hint: t.tags.picker.search,
            value: state.query,
            onChanged: cubit.queryChanged,
          ),
          if (state.isEmpty && !state.canCreate)
            p(classes: 'text-caption tag-picker__note', [
              .text(t.tags.picker.emptyText),
            ])
          else
            div(classes: 'tag-picker__chips', [
              for (final tag in tags)
                BirkaChip(
                  key: ValueKey(tag.id),
                  label: tag.name,
                  glyph: tag.isTrip ? BirkaGlyph.plane : BirkaGlyph.tag,
                  selected: picked.contains(tag.id),
                  onTap: () => onChanged(_toggled(tag.id)),
                ),
              if (state.canCreate)
                BirkaChip(
                  key: const ValueKey('create'),
                  label: t.tags.picker.create(name: state.query.trim()),
                  glyph: BirkaGlyph.plus,
                  selected: false,
                  dashed: true,
                  onTap: () => unawaited(_create(cubit)),
                ),
            ]),
          if (state.trips.isNotEmpty)
            p(classes: 'text-caption tag-picker__note', [
              .text(t.tags.picker.tripsNote),
            ]),
        ]);
      },
    );
  }

  Set<String> _toggled(String id) {
    final next = {...picked};
    if (!next.remove(id)) next.add(id);
    return next;
  }

  Future<void> _create(TagPickerCubit cubit) async {
    final id = await cubit.create();
    if (id != null) onChanged({...picked, id});
  }

  /// The styles of the picker.
  @css
  static List<StyleRule> get styles => [
    css('.glass.tag-picker').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.tag-picker__chips').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.tag-picker__note').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
  ];
}
