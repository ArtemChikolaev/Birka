import 'dart:async';

import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:overview_common/overview_common.dart';
import 'package:overview_jaspr/overview_jaspr.dart';

/// The first screen with data: the capital, the accounts and what the month
/// has cost.
@client
class OverviewIsland extends StatefulComponent {
  /// Creates the island.
  const OverviewIsland({super.key});

  @override
  State<OverviewIsland> createState() => _OverviewIslandState();
}

class _OverviewIslandState extends DataIslandState<OverviewIsland> {
  OverviewCubit? _overview;

  @override
  SitePage get page => SitePage.overview;

  @override
  String get pageName => t.app.overview;

  @override
  String get failure => t.overview.failed;

  @override
  Component get header => GlassPageHeader(title: t.app.overview);

  @override
  void onTabShown() => unawaited(_overview?.calendarChecked());

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<OverviewCubit>(
      create: (_) => _overview = getIt(),
      child: OverviewPage(
        addAccountHref: 'accounts/#new',
        accountsHref: 'accounts/',
        hrefOfAccount: (id) => 'accounts/#$id',
        note: storageNote,
      ),
    );
  }
}
