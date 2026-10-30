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
                  CategoriesLoaded(:final overview) => _content(
                    context,
                    overview,
                  ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, CategoriesOverview overview) {
    final colors = BirkaColors.of(context);
    return [
      if (overview.groups.isNotEmpty)
        GlassListGroup(
          children: [
            for (final group in overview.groups) ...[
              GlassListRow(
                title: group.category.name,
                subtitle: group.children.isEmpty
                    ? null
                    : t.categories.subcategories(n: group.children.length),
                leading: categoryBadge(group.category),
                onTap: () => onOpen(group.category.id),
              ),
              for (final child in group.children)
                Padding(
                  padding: const EdgeInsets.only(left: BirkaTokens.spaceXl),
                  child: GlassListRow(
                    title: child.name,
                    leading: categoryBadge(child, size: 28),
                    onTap: () => onOpen(child.id),
                  ),
                ),
            ],
          ],
        ),
      if (overview.archived.isNotEmpty) ...[
        const SizedBox(height: BirkaTokens.spaceLg),
        SectionLabel(t.categories.archive, color: colors.textSubtle),
        const SizedBox(height: BirkaTokens.spaceXs),
        GlassListGroup(
          children: [
            for (final category in overview.archived)
              GlassListRow(
                title: category.name,
                leading: categoryBadge(category),
                onTap: () => onOpen(category.id),
              ),
          ],
        ),
      ],
    ];
  }
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
            label: t.categories.retry,
            onPressed: context.read<CategoriesCubit>().retry,
          ),
        ],
      ),
    );
  }
}
