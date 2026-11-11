import 'package:categories_common/categories_common.dart';
import 'package:categories_jaspr/src/presentation/components/category_look.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The categories of one kind, with their subcategories under them. On a
/// wide page a [side] stands beside the list, such as how the page works or
/// the form of the [picked] category.
///
/// It needs a [CategoriesCubit] above it.
class CategoriesPage extends StatelessComponent {
  /// Creates the page.
  const CategoriesPage({
    required this.addHrefOf,
    required this.hrefOf,
    this.note,
    this.side,
    this.picked,
    super.key,
  });

  /// Where a new category of this kind opens.
  final String Function(CategoryKind kind) addHrefOf;

  /// Where the category with this id opens.
  final String Function(String id) hrefOf;

  /// A quiet line under the list, such as where the data lives.
  final String? note;

  /// What stands beside the list on a wide page.
  final Component? side;

  /// The category whose form is open beside the list.
  final String? picked;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final header = GlassPageHeader(
          title: t.categories.title,
          trailing: GlassIconButton(
            glyph: BirkaGlyph.plus,
            label: t.categories.add,
            href: addHrefOf(state.kind),
          ),
        );
        final side = this.side;
        if (side == null) {
          return BirkaColumn(children: [header, ..._list(context, state)]);
        }
        return BirkaColumn(
          children: [
            header,
            BirkaSplit(
              asideWidth: 400,
              main: _list(context, state),
              aside: [side],
            ),
          ],
        );
      },
    );
  }

  /// The switch of the kind and the categories under it.
  List<Component> _list(BuildContext context, CategoriesState state) {
    final note = this.note;
    return [
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
    ];
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
                picked: group.category.id == picked,
              ),
              for (final child in group.children)
                GlassListRow(
                  title: child.name,
                  leading: categoryBadge(child, size: 28),
                  href: hrefOf(child.id),
                  indented: true,
                  picked: child.id == picked,
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
                  picked: category.id == picked,
                ),
            ],
          ),
        ]),
    ];
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
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
