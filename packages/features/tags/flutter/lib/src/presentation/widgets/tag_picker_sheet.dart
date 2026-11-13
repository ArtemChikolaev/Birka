import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';

/// Shows the picker of метки over [context] with [cubit], and completes with
/// the метки that are picked once it closes, however it closes (ADR 0027).
/// [onCreate] makes a new метка of the name in the search and completes with
/// its id. The picker closes [cubit].
Future<Set<String>> showTagPicker(
  BuildContext context, {
  required TagPickerCubit cubit,
  required Future<String?> Function(BuildContext context, String name) onCreate,
}) async {
  try {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => FractionallySizedBox(
        // The sheet keeps its height while the search narrows the list.
        heightFactor: 0.82,
        child: BlocProvider.value(
          value: cubit,
          child: TagPickerSheet(onCreate: onCreate),
        ),
      ),
    );
    return cubit.state.picked;
  } finally {
    // The метки picked do not wait for the picker to let go of the ledger.
    unawaited(cubit.close());
  }
}

/// The метки to pick from (ADR 0027): a search that finds them or makes a
/// new one, the trips, the one that goes on first, and the метки without
/// days, each with a box that a tap checks or clears at once.
///
/// It needs a [TagPickerCubit] above it.
class TagPickerSheet extends StatefulWidget {
  /// Creates the picker.
  const TagPickerSheet({required this.onCreate, super.key});

  /// Makes a new метка of the name in the search, and completes with its id.
  final Future<String?> Function(BuildContext context, String name) onCreate;

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create(BuildContext context, String name) async {
    final cubit = context.read<TagPickerCubit>();
    final id = await widget.onCreate(context, name.trim());
    if (id == null || cubit.isClosed) return;
    _search.clear();
    cubit.created(id);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TagPickerCubit>();
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    const gap = SizedBox(height: BirkaTokens.spaceLg);
    const small = SizedBox(height: BirkaTokens.spaceXs);
    return BlocBuilder<TagPickerCubit, TagPickerState>(
      builder: (context, state) {
        final trips = state.trips;
        final plain = state.plain;
        return ChoiceSheet(
          title: t.tags.picker.title,
          children: [
            GlassSearchField(
              label: t.tags.picker.search,
              hint: t.tags.picker.search,
              clearLabel: t.tags.close,
              controller: _search,
              onChanged: cubit.queryChanged,
            ),
            gap,
            if (state.canCreate) ...[
              GlassListGroup(
                children: [
                  GlassListRow(
                    leading: ExcludeSemantics(
                      child: GlyphBadge(
                        glyph: BirkaGlyph.plus,
                        color: colors.accent,
                      ),
                    ),
                    title: t.tags.picker.create(name: state.query.trim()),
                    subtitle: t.tags.picker.createText,
                    trailing: BirkaIcon(
                      BirkaGlyph.chevron,
                      size: 16,
                      color: colors.textMuted,
                    ),
                    onTap: () => unawaited(_create(context, state.query)),
                  ),
                ],
              ),
              gap,
            ],
            if (trips.isNotEmpty) ...[
              SectionLabel(t.tags.trips),
              small,
              GlassListGroup(
                children: [
                  for (final tag in trips) _Row(tag: tag, state: state),
                ],
              ),
              small,
              Text(
                t.tags.picker.tripsNote,
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
              gap,
            ],
            if (plain.isNotEmpty) ...[
              SectionLabel(t.tags.plain),
              small,
              GlassListGroup(
                children: [
                  for (final tag in plain) _Row(tag: tag, state: state),
                ],
              ),
            ],
            if (state.isEmpty && !state.canCreate) _Empty(),
          ],
        );
      },
    );
  }
}

/// A метка with the box that says whether it is picked.
class _Row extends StatelessWidget {
  const _Row({required this.tag, required this.state});

  final Tag tag;
  final TagPickerState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TagPickerCubit>();
    final colors = BirkaColors.of(context);
    final days = tag.days;
    final picked = state.picked.contains(tag.id);
    return GlassListRow(
      key: ValueKey(tag.id),
      leading: ExcludeSemantics(
        child: GlyphBadge(
          glyph: tag.isTrip ? BirkaGlyph.plane : BirkaGlyph.tag,
          color: colors.accent,
        ),
      ),
      title: tag.name,
      subtitle: days == null
          ? null
          : [
              daysLabel(days, thisYear: state.today.year),
              if (state.goesOn(tag)) t.tags.picker.now,
            ].join(' · '),
      trailing: BirkaCheckbox(
        checked: picked,
        label: tag.name,
        onChanged: (_) => cubit.toggle(tag.id),
      ),
      onTap: () => cubit.toggle(tag.id),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceLg),
      child: Column(
        children: [
          ExcludeSemantics(
            child: GlyphBadge(glyph: BirkaGlyph.tag, color: colors.accent),
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          Text(
            t.tags.picker.emptyTitle,
            textAlign: TextAlign.center,
            style: styles.bodyStrong.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.tags.picker.emptyText,
            textAlign: TextAlign.center,
            style: styles.body.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
