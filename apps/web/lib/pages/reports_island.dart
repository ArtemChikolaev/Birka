import 'dart:async';

import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/app/report_address.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';
import 'package:reports_jaspr/reports_jaspr.dart';

/// What a month took or brought, in the browser. The address `reports/#2026-10`
/// opens a month, as the card of the month on the operations does, and then
/// keeps no month, so that the page stays the page of the reports.
@client
class ReportsIsland extends StatefulComponent {
  /// Creates the island.
  const ReportsIsland({super.key});

  @override
  State<ReportsIsland> createState() => _ReportsIslandState();
}

class _ReportsIslandState extends DataIslandState<ReportsIsland> {
  ReportsCubit? _reports;

  /// The month that the address asked for.
  CivilDate? _asked;

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
  Future<void> prepare() async {
    _asked = reportMonthIn(fragment);
    if (_asked != null) closeForm();
  }

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<ReportsCubit>(
      create: (_) {
        final reports = _reports = getIt<ReportsCubit>();
        if (_asked case final asked?) {
          // The report counts its months from the day they start on, so the
          // month of that name.
          final start = reports.state.monthStart;
          unawaited(
            reports.monthChanged(
              CivilDate.onDay(asked.year, asked.month, start),
            ),
          );
        }
        return reports;
      },
      child: ReportsPage(note: storageNote, wide: wide),
    );
  }
}
