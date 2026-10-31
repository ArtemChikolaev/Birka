import 'dart:async';

import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

/// The operations in the browser. The address `operations/#new` opens a new
/// operation, `operations/#<id>` the card of one, and `operations/#edit-<id>`
/// and `operations/#repeat-<id>` the form on it.
@client
class OperationsIsland extends StatefulComponent {
  /// Creates the island.
  const OperationsIsland({super.key});

  @override
  State<OperationsIsland> createState() => _OperationsIslandState();
}

class _OperationsIslandState extends DataIslandState<OperationsIsland> {
  static const _list = 'operations/';
  static const _new = 'new';
  static const _edit = 'edit-';
  static const _repeat = 'repeat-';

  OperationsCubit? _operations;

  @override
  SitePage get page => SitePage.operations;

  @override
  String get pageName => t.app.operations;

  @override
  String get failure => t.transactions.failedToReadOperations;

  @override
  Component get header => GlassPageHeader(title: t.app.operations);

  @override
  void onTabShown() => unawaited(_operations?.calendarChecked());

  // The list stays with the page, so that a form does not lose its month, its
  // filter and its search.
  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<OperationsCubit>(
      create: (_) => _operations = getIt(),
      child: fragment.isEmpty
          ? OperationsPage(
              addHref: '$_list#$_new',
              hrefOf: (id) => '$_list#$id',
              note: storageNote,
            )
          : _form(),
    );
  }

  Component _form() {
    final fragment = this.fragment;
    if (fragment == _new) return _quickAdd(null, closeForm);
    if (fragment.startsWith(_edit)) {
      final id = fragment.substring(_edit.length);
      return _quickAdd(QuickAddSource.edit(id), () => closeForm(id));
    }
    if (fragment.startsWith(_repeat)) {
      final id = fragment.substring(_repeat.length);
      return _quickAdd(QuickAddSource.repeat(id), () => closeForm(id));
    }
    return BlocProvider<OperationCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: fragment),
      child: OperationPage(
        onClose: closeForm,
        editHref: '$_list#$_edit$fragment',
        repeatHref: '$_list#$_repeat$fragment',
      ),
    );
  }

  Component _quickAdd(QuickAddSource? source, VoidCallback onClose) {
    return BlocProvider<QuickAddCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: source),
      child: QuickAddPage(
        onClose: onClose,
        addAccountHref: 'accounts/#new',
        addCategoriesHref: 'categories/',
      ),
    );
  }
}
