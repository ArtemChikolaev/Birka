import 'dart:async';

import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/month_card.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:birka_web/pages/operation_views.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

/// The operations in the browser. The address `operations/#new` opens a new
/// operation, `operations/#<id>` the card of one, and `operations/#edit-<id>`
/// and `operations/#repeat-<id>` the form on it. In a wide window they open
/// beside the list, which otherwise shows what the month came to.
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
  ReportsCubit? _reports;

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
  bool get viewsBeside => true;

  @override
  void onTabShown() {
    unawaited(_operations?.calendarChecked());
    if (_reports case final reports? when !reports.isClosed) {
      unawaited(reports.calendarChecked());
    }
  }

  // The list stays with the page, so that a form does not lose its month, its
  // filter and its search.
  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<OperationsCubit>(
      create: (_) => _operations = getIt(),
      child: wide ? _besideList() : _inTurn(),
    );
  }

  /// A narrow window: the list, or a view in its place.
  Component _inTurn() {
    return switch (fragment) {
      '' => _list(),
      _new => quickAdd(null, closeForm),
      final view => operationView(view),
    };
  }

  /// A wide window: the list, and beside it what the month came to, or the
  /// card of the operation picked in the list, or a form.
  Component _besideList() {
    return BlocProvider<ReportsCubit>(
      create: (_) => _reports = getIt(),
      child: _list(
        picked: switch (fragment) {
          '' || _new => null,
          final view => operationOf(view),
        },
        side: switch (fragment) {
          '' => const MonthCard(reportHref: 'reports/'),
          _new => GlassPanel(
            key: ValueKey(fragment),
            child: quickAdd(null, closeForm),
          ),
          final view => GlassPanel(
            key: ValueKey(fragment),
            child: operationView(view, closes: true),
          ),
        },
      ),
    );
  }

  Component _list({String? picked, Component? side}) {
    return OperationsPage(
      addHref: '$address#$_new',
      hrefOf: (id) => '$address#$id',
      note: storageNote,
      picked: picked,
      side: side,
    );
  }
}
