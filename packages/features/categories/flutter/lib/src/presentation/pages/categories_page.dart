import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/src/presentation/widgets/category_look.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// The categories of one kind, with their subcategories under them.
///
/// It needs a [CategoriesCubit] above it.
class CategoriesPage extends StatelessWidget {
  /// Creates the page.
  const CategoriesPage({
    required this.onBack,
    required this.onAdd,
    required this.onOpen,
    super.key,
  });

  /// Called by the button that goes back.
  final VoidCallback onBack;

  /// Called with the kind on the screen, to add a category of that kind.
  final ValueChanged<CategoryKind> onAdd;

  /// Called with the id of the category to open.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXs,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXxl,
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassIconButton(
                      glyph: BirkaGlyph.back,
                      label: t.categories.back,
                      onPressed: onBack,
                    ),
                    GlassIconButton(
                      glyph: BirkaGlyph.plus,
                      label: t.categories.add,
                      onPressed: () => onAdd(state.kind),
                    ),
                  ],
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                Text(
                  t.categories.title,
                  style: styles.title.copyWith(color: colors.text),
                ),
                const SizedBox(height: BirkaTokens.spaceMd),
                GlassSegmented<CategoryKind>(
                  segments: {
                    CategoryKind.expense: t.categories.expense,
                    CategoryKind.income: t.categories.income,
                  },
                  selected: state.kind,
                  onChanged: context.read<CategoriesCubit>().kindChanged,
                ),
                const SizedBox(height: BirkaTokens.spaceMd),
                ...switch (state) {
                  CategoriesLoading() => const <Widget>[],
                  CategoriesFailed() => [const _Failure()],
                  CategoriesLoaded(:final overview) when overview.isEmpty => [
                    _Empty(onAddOwn: () => onAdd(state.kind)),
                  ],
                  CategoriesLoaded() => _content(context, state),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    CategoriesLoaded state,
  ) {
    final colors = BirkaColors.of(context);
    final overview = state.overview.matching(state.query);
    return [
      _CategorySearch(key: ValueKey(state.kind), initialValue: state.query),
      const SizedBox(height: BirkaTokens.spaceMd),
      if (overview.isEmpty)
        Text(
          t.categories.noMatches,
          style: BirkaTextStyles.of(
            context,
          ).caption.copyWith(color: colors.textMuted),
        )
      else
        // A new kind or query replaces the list immediately. Ledger updates
        // within the same search still animate.
        AnimatedColumn(
          key: ValueKey((state.kind, state.query)),
          children: [
            if (overview.groups.isNotEmpty)
              GlassListGroup(
                key: const ValueKey('groups'),
                children: [
                  for (final group in overview.groups) ...[
                    GlassListRow(
                      key: ValueKey(group.category.id),
                      title: group.category.name,
                      subtitle: state.searching || group.children.isEmpty
                          ? null
                          : t.categories.subcategories(
                              n: group.children.length,
                            ),
                      leading: categoryBadge(group.category),
                      onTap: () => onOpen(group.category.id),
                    ),
                    for (final child in group.children)
                      Padding(
                        key: ValueKey(child.id),
                        padding: const EdgeInsets.only(
                          left: BirkaTokens.spaceXl,
                        ),
                        child: GlassListRow(
                          title: child.name,
                          leading: categoryBadge(child, size: 28),
                          onTap: () => onOpen(child.id),
                        ),
                      ),
                  ],
                ],
              ),
            if (overview.archived.isNotEmpty)
              Column(
                key: const ValueKey('archive'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: BirkaTokens.spaceLg),
                  SectionLabel(t.categories.archive, color: colors.textSubtle),
                  const SizedBox(height: BirkaTokens.spaceXs),
                  GlassListGroup(
                    children: [
                      for (final category in overview.archived)
                        GlassListRow(
                          key: ValueKey(category.id),
                          title: category.name,
                          leading: categoryBadge(category),
                          onTap: () => onOpen(category.id),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
    ];
  }
}

class _CategorySearch extends StatefulWidget {
  const _CategorySearch({required this.initialValue, super.key});

  final String initialValue;

  @override
  State<_CategorySearch> createState() => _CategorySearchState();
}

class _CategorySearchState extends State<_CategorySearch> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassSearchField(
    label: t.categories.search,
    hint: t.categories.search,
    clearLabel: t.categories.clearSearch,
    controller: _controller,
    onChanged: context.read<CategoriesCubit>().queryChanged,
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAddOwn});

  final VoidCallback onAddOwn;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.categories.emptyTitle,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.categories.emptyHint,
            style: styles.body.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          BirkaButton(
            label: t.categories.addPresets,
            onPressed: context.read<CategoriesCubit>().addPresets,
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.categories.addOwn,
            quiet: true,
            onPressed: onAddOwn,
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.categories.failed,
            style: styles.body.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.app.retry,
            onPressed: context.read<CategoriesCubit>().retry,
          ),
        ],
      ),
    );
  }
}
