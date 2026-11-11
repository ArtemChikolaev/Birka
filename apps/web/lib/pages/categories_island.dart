import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:categories_common/categories_common.dart';
import 'package:categories_jaspr/categories_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The categories in the browser. The address `categories/#new-income` opens
/// a new category of that kind and `categories/#<id>` an existing one. In a
/// wide window they open beside the list, which otherwise says how the page
/// works.
@client
class CategoriesIsland extends StatefulComponent {
  /// Creates the island.
  const CategoriesIsland({super.key});

  @override
  State<CategoriesIsland> createState() => _CategoriesIslandState();
}

class _CategoriesIslandState extends DataIslandState<CategoriesIsland> {
  static const _list = 'categories/';

  static final Map<String, CategoryKind> _newKinds = {
    for (final kind in CategoryKind.values) 'new-${kind.name}': kind,
  };

  static String _addHrefOf(CategoryKind kind) => '$_list#new-${kind.name}';

  @override
  SitePage get page => SitePage.more;

  @override
  String get pageName => t.categories.title;

  @override
  String get failure => t.categories.failed;

  @override
  Component get header => GlassPageHeader(title: t.categories.title);

  @override
  bool get viewsBeside => true;

  // The list stays with the page, so that a form does not lose its tab.
  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<CategoriesCubit>(
      create: (_) => getIt(),
      child: switch ((wide, fragment)) {
        (false, '') => _categories(),
        (false, _) => _form(),
        (true, '') => _categories(
          side: GlassSteps(
            title: t.categories.howTitle,
            points: t.categories.how,
          ),
        ),
        (true, _) => _categories(
          picked: _newKinds.containsKey(fragment) ? null : fragment,
          side: GlassPanel(key: ValueKey(fragment), child: _form()),
        ),
      },
    );
  }

  Component _categories({String? picked, Component? side}) {
    return CategoriesPage(
      addHrefOf: _addHrefOf,
      hrefOf: (id) => '$_list#$id',
      note: storageNote,
      picked: picked,
      side: side,
    );
  }

  Component _form() {
    final kind = _newKinds[fragment];
    final id = kind == null ? fragment : null;
    return BlocProvider<CategoryFormCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: id, param2: kind),
      child: CategoryFormPage(onClose: closeForm),
    );
  }
}
