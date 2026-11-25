import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:tags_common/tags_common.dart';

/// The list of метки (ADR 0027): the trip that goes on, the other trips and
/// the метки without days, each with what it took.
///
/// It needs a [TagsCubit] above it.
class TagsPage extends StatefulWidget {
  /// Creates the page.
  const TagsPage({
    required this.onBack,
    required this.onAdd,
    required this.onOpen,
    super.key,
  });

  /// Called by the way back.
  final VoidCallback onBack;

  /// Opens the form of a new метка.
  final VoidCallback onAdd;

  /// Opens the report of a метка, by its id.
  final ValueChanged<String> onOpen;

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: context.read<TagsCubit>().state.query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<TagsCubit, TagsState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXs,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXxl,
              ),
              children: [
                BackHeader(
                  label: t.tags.title,
                  backLabel: t.tags.back,
                  onBack: widget.onBack,
                  trailing: GlassIconButton(
                    glyph: BirkaGlyph.plus,
                    label: t.tags.add,
                    onPressed: widget.onAdd,
                  ),
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                ...switch (state.status) {
                  TagsStatus.loading => const <Widget>[],
                  TagsStatus.failed => [_Failure()],
                  TagsStatus.ready when state.isEmpty => [
                    _Empty(onAdd: widget.onAdd),
                  ],
                  TagsStatus.ready => _shelves(context, state),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _shelves(BuildContext context, TagsState state) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final shelves = state.visibleShelves;
    return [
      GlassSearchField(
        label: t.tags.search,
        hint: t.tags.search,
        clearLabel: t.tags.picker.clear,
        controller: _search,
        onChanged: context.read<TagsCubit>().queryChanged,
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      for (final (shelf, title) in [
        (TagShelf.now, t.tags.now),
        (TagShelf.trips, t.tags.trips),
        (TagShelf.plain, t.tags.plain),
      ])
        if (shelves[shelf] case final summaries?) ...[
          SectionLabel(title),
          const SizedBox(height: BirkaTokens.spaceXs),
          GlassListGroup(
            key: ValueKey((shelf, state.query)),
            children: [
              for (final summary in summaries)
                GlassListRow(
                  key: ValueKey(summary.tag.id),
                  leading: ExcludeSemantics(
                    child: GlyphBadge(
                      glyph: summary.tag.isTrip
                          ? BirkaGlyph.plane
                          : BirkaGlyph.tag,
                      color: colors.accent,
                    ),
                  ),
                  title: summary.tag.name,
                  subtitle: shelfLine(summary, today: state.today),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        HiddenAmounts.mask(context, formatMoney(summary.total)),
                        style: styles.bodyStrong.copyWith(color: colors.text),
                      ),
                      const SizedBox(width: BirkaTokens.spaceXs),
                      BirkaIcon(
                        BirkaGlyph.chevron,
                        size: 16,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                  onTap: () => widget.onOpen(summary.tag.id),
                ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
        ],
      Text(
        shelves.isEmpty ? t.tags.noMatches : t.tags.note,
        style: styles.caption.copyWith(color: colors.textMuted),
      ),
    ];
  }
}

class _Failure extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    t.tags.failed,
    textAlign: TextAlign.center,
    style: BirkaTextStyles.of(
      context,
    ).body.copyWith(color: BirkaColors.of(context).negative),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceXxl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: GlyphBadge(
              glyph: BirkaGlyph.tag,
              color: colors.accent,
              size: 72,
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Text(
            t.tags.emptyTitle,
            textAlign: TextAlign.center,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.tags.emptyText,
            textAlign: TextAlign.center,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          SizedBox(
            width: double.infinity,
            child: BirkaButton(label: t.tags.add, onPressed: onAdd),
          ),
        ],
      ),
    );
  }
}
