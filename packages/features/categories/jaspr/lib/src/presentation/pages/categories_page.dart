import 'package:categories_common/categories_common.dart';
import 'package:categories_jaspr/src/presentation/components/category_look.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The categories of one kind, with their subcategories under them.
///
/// It needs a [CategoriesCubit] above it.
class CategoriesPage extends StatelessComponent {
  /// Creates the page.
  const CategoriesPage({
    required this.backHref,
    required this.addHrefOf,
    required this.hrefOf,
    this.note,
    super.key,
  });

  /// Where the button that goes back leads.
  final String backHref;

  /// Where a new category of this kind opens.
  final String Function(CategoryKind kind) addHrefOf;

  /// Where the category with this id opens.
  final String Function(String id) hrefOf;

  /// A quiet line under the list, such as where the data lives.
  final String? note;

  @override
  Component build(BuildContext context) {
    final note = this.note;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) => BirkaColumn(
        children: [
          GlassPageHeader(
            backHref: backHref,
            backLabel: t.categories.back,
            addHref: addHrefOf(state.kind),
            addLabel: t.categories.add,
          ),
          h1(classes: 'text-title categories__heading', [
            .text(t.categories.title),
          ]),
          GlassSegmented<CategoryKind>(
            segments: {
              CategoryKind.expense: t.categories.expense,
              CategoryKind.income: t.categories.income,
            },
            selected: state.kind,
            onChanged: context.read<CategoriesCubit>().kindChanged,
          ),
          ...switch (state) {
            CategoriesLoading() => const <Component>[],
            CategoriesFailed() => [
              GlassNotice(
                text: t.categories.failed,
                actions: [
                  BirkaButton(
                    label: t.app.retry,
                    onPressed: context.read<CategoriesCubit>().retry,
                  ),
                ],
              ),
            ],
            CategoriesLoaded(:final overview) when overview.isEmpty => [
              GlassNotice(
                title: t.categories.emptyTitle,
                text: t.categories.emptyHint,
                actions: [
                  BirkaButton(
                    label: t.categories.addPresets,
                    onPressed: context.read<CategoriesCubit>().addPresets,
                  ),
                  BirkaButton(
                    label: t.categories.addOwn,
                    quiet: true,
                    href: addHrefOf(state.kind),
                  ),
                ],
              ),
            ],
            CategoriesLoaded(:final overview) => _content(overview),
          },
          if (note != null && state is CategoriesLoaded)
            p(classes: 'text-caption categories__note', [.text(note)]),
        ],
      ),
    );
  }

  List<Component> _content(CategoriesOverview overview) {
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
                href: hrefOf(group.category.id),
              ),
              for (final child in group.children)
                GlassListRow(
                  title: child.name,
                  leading: categoryBadge(child, size: 28),
                  href: hrefOf(child.id),
                  indented: true,
                ),
            ],
          ],
        ),
      if (overview.archived.isNotEmpty)
        div(classes: 'categories__archive', [
          SectionLabel(t.categories.archive),
          GlassListGroup(
            children: [
              for (final category in overview.archived)
                GlassListRow(
                  title: category.name,
                  leading: categoryBadge(category),
                  href: hrefOf(category.id),
                ),
            ],
          ),
        ]),
    ];
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.categories__heading').styles(raw: {'margin': '0'}),
    css('.categories__archive').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.categories__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
  ];
}
