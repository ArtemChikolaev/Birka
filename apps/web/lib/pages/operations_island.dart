import 'dart:async';

import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:birka_web/pages/operation_views.dart';
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

class _OperationsIslandState extends DataIslandState<OperationsIsland>
    with OperationViews {
  static const _new = 'new';

  OperationsCubit? _operations;

  @override
  String get address => 'operations/';

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
      child: switch (fragment) {
        '' => OperationsPage(
          addHref: '$address#$_new',
          hrefOf: (id) => '$address#$id',
          note: storageNote,
        ),
        _new => quickAdd(null, closeForm),
        final view => operationView(view),
      },
    );
  }
}
