import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_jaspr/schedules_jaspr.dart';

/// The regular payments of this browser (ADR 0023): the ones that wait, what
/// came every month, the next 30 days and every payment, and the form of a
/// payment at `#new`, `#salary`, `#from-<operation>` and `#<payment>`. The
/// card of the overview leads here, and the page has a way back of its own,
/// so it stands without the tabs of the site.
@client
class SchedulesIsland extends StatefulComponent {
  /// Creates the island.
  const SchedulesIsland({super.key});

  @override
  State<SchedulesIsland> createState() => _SchedulesIslandState();
}

class _SchedulesIslandState extends DataIslandState<SchedulesIsland> {
  static const _address = 'schedules/';
  static const _new = 'new';
  static const _salary = 'salary';
  static const _from = 'from-';

  SchedulesCubit? _schedules;

  /// What the list says once a form is done, such as a payment deleted.
  String? _said;

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
    return switch (fragment) {
      '' => _list(),
      _new => _form(null, null),
      _salary => _form(null, (salary: true, from: null)),
      final path when path.startsWith(_from) => _form(null, (
        salary: false,
        from: path.substring(_from.length),
      )),
      final id => _form(id, null),
    };
  }

  /// The list, which says what a form did once: back from another form by
  /// the browser, it says nothing.
  Component _list() {
    final said = _said;
    _said = null;
    return BlocProvider<SchedulesCubit>(
      create: (_) => _schedules = getIt(),
      child: SchedulesPage(
        said: said,
        backHref: 'overview/',
        addHref: '$_address#$_new',
        paydayHref: 'payday/',
        hrefOf: (id) => '$_address#$id',
        findHref: (id) => '$_address#$_from$id',
      ),
    );
  }

  Component _form(String? id, ({bool salary, String? from})? start) {
    return BlocProvider<ScheduleFormCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: id, param2: start),
      child: ScheduleFormPage(
        onClose: () {
          _said = null;
          closeForm();
        },
        onDone: (said) {
          _said = said;
          closeForm();
        },
      ),
    );
  }
}
