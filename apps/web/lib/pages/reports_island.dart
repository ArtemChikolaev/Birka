import 'dart:async';

import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';
import 'package:reports_jaspr/reports_jaspr.dart';

/// What a month took or brought, in the browser.
@client
class ReportsIsland extends StatefulComponent {
  /// Creates the island.
  const ReportsIsland({super.key});

  @override
  State<ReportsIsland> createState() => _ReportsIslandState();
}

class _ReportsIslandState extends DataIslandState<ReportsIsland> {
  ReportsCubit? _reports;

  @override
  SitePage get page => SitePage.reports;

  @override
  String get pageName => t.app.reports;

  @override
  String get failure => t.reports.failed;

  @override
  Component get header => GlassPageHeader(title: t.app.reports);

  @override
  void onTabShown() => unawaited(_reports?.calendarChecked());

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<ReportsCubit>(
      create: (_) => _reports = getIt(),
      child: ReportsPage(note: storageNote),
    );
  }
}
