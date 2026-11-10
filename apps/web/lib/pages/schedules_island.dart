import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_jaspr/schedules_jaspr.dart';

/// The regular payments of this browser (ADR 0023): the ones that wait, what
/// came every month, the next 30 days and every payment. The card of the
/// overview leads here, and the page has a way back of its own, so it stands
/// without the tabs of the site.
@client
class SchedulesIsland extends StatefulComponent {
  /// Creates the island.
  const SchedulesIsland({super.key});

  @override
  State<SchedulesIsland> createState() => _SchedulesIslandState();
}

class _SchedulesIslandState extends DataIslandState<SchedulesIsland> {
  SchedulesCubit? _schedules;

  @override
  SitePage get page => SitePage.overview;

  @override
  String get pageName => t.schedules.title;

  @override
  String get failure => t.schedules.failed;

  @override
  Component get header => GlassPageHeader(title: t.schedules.title);

  @override
  bool get standsAlone => true;

  @override
  void onTabShown() => _schedules?.calendarChecked();

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<SchedulesCubit>(
      create: (_) => _schedules = getIt(),
      child: SchedulesPage(
        backHref: 'overview/',
        addHref: 'schedules/#new',
        paydayHref: 'payday/',
        hrefOf: (id) => 'schedules/#$id',
        findHref: (id) => 'schedules/#from-$id',
      ),
    );
  }
}
