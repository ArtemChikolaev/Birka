import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_jaspr/schedules_jaspr.dart';

/// The money until the salary on this browser (ADR 0023): how much a day may
/// take, what becomes of it at the usual pace, and what it counts. The card
/// of the overview and the side of the payments lead here, and the page has
/// a way back of its own, so it stands without the tabs of the site.
@client
class PaydayIsland extends StatefulComponent {
  /// Creates the island.
  const PaydayIsland({super.key});

  @override
  State<PaydayIsland> createState() => _PaydayIslandState();
}

class _PaydayIslandState extends DataIslandState<PaydayIsland> {
  SchedulesCubit? _schedules;

  @override
  SitePage get page => SitePage.overview;

  @override
  String get pageName => t.schedules.paydayTitle;

  @override
  String get failure => t.schedules.failed;

  @override
  Component get header => GlassPageHeader(title: t.schedules.paydayTitle);

  @override
  bool get standsAlone => true;

  @override
  void onTabShown() => _schedules?.calendarChecked();

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<SchedulesCubit>(
      create: (_) => _schedules = getIt(),
      child: PaydayPage(
        backHref: 'overview/',
        salaryHref: (id) => 'schedules/#$id',
        addSalaryHref: 'schedules/#salary',
      ),
    );
  }
}
