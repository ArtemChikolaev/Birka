import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:notifications_common/notifications_common.dart';
import 'package:notifications_jaspr/notifications_jaspr.dart';

/// The feed of what Birka told on this browser (ADR 0026), which the bell of
/// the overview opens. It has a way back of its own, so the page stands
/// without the tabs of the site.
@client
class NotificationsIsland extends StatefulComponent {
  /// Creates the island.
  const NotificationsIsland({super.key});

  @override
  State<NotificationsIsland> createState() => _NotificationsIslandState();
}

class _NotificationsIslandState extends DataIslandState<NotificationsIsland> {
  NotificationsCubit? _feed;

  @override
  SitePage get page => SitePage.overview;

  @override
  String get pageName => t.notifications.title;

  @override
  String get failure => t.notifications.failed;

  @override
  Component get header => GlassPageHeader(title: t.notifications.title);

  @override
  bool get standsAlone => true;

  @override
  void onTabShown() => _feed?.calendarChecked();

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<NotificationsCubit>(
      create: (_) => _feed = getIt(),
      child: NotificationsPage(
        wide: wide,
        backHref: 'overview/',
        hrefOf: (place, id) => switch (place) {
          NoticePlace.inbox => 'inbox/',
          NoticePlace.schedule when id != null => 'schedules/#$id',
          NoticePlace.schedules || NoticePlace.schedule => 'schedules/',
          NoticePlace.debt when id != null => 'debts/#$id',
          NoticePlace.debt => 'debts/',
        },
        onOpen: openSitePage,
      ),
    );
  }
}
