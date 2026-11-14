import 'package:birka_web/pages/accounts_island.dart';
import 'package:birka_web/pages/ask_island.dart';
import 'package:birka_web/pages/backup_island.dart';
import 'package:birka_web/pages/categories_island.dart';
import 'package:birka_web/pages/debts_island.dart';
import 'package:birka_web/pages/help_island.dart';
import 'package:birka_web/pages/home_route.dart';
import 'package:birka_web/pages/import_island.dart';
import 'package:birka_web/pages/inbox_island.dart';
import 'package:birka_web/pages/more_island.dart';
import 'package:birka_web/pages/notifications_island.dart';
import 'package:birka_web/pages/operations_island.dart';
import 'package:birka_web/pages/overview_island.dart';
import 'package:birka_web/pages/page_frame.dart';
import 'package:birka_web/pages/payday_island.dart';
import 'package:birka_web/pages/reports_island.dart';
import 'package:birka_web/pages/schedules_island.dart';
import 'package:birka_web/pages/tags_island.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// The pages of the site. The router runs only when the build renders them to
/// HTML, so it never meets the `/Birka/` of the real address (ADR 0008).
class App extends StatelessComponent {
  /// Creates the site.
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(path: '/', builder: (_, _) => const HomeRoute()),
        Route(
          path: '/overview',
          title: 'Overview · Birka',
          builder: (_, _) =>
              const PageFrame(wide: true, child: OverviewIsland()),
        ),
        Route(
          path: '/operations',
          title: 'Operations · Birka',
          builder: (_, _) =>
              const PageFrame(wide: true, child: OperationsIsland()),
        ),
        Route(
          path: '/reports',
          title: 'Reports · Birka',
          builder: (_, _) =>
              const PageFrame(wide: true, child: ReportsIsland()),
        ),
        Route(
          path: '/more',
          title: 'More · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: MoreIsland()),
        ),
        Route(
          path: '/accounts',
          title: 'Accounts · Birka',
          builder: (_, _) =>
              const PageFrame(wide: true, child: AccountsIsland()),
        ),
        Route(
          path: '/categories',
          title: 'Categories · Birka',
          builder: (_, _) =>
              const PageFrame(wide: true, child: CategoriesIsland()),
        ),
        Route(
          path: '/import',
          title: 'Import · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: ImportIsland()),
        ),
        Route(
          path: '/inbox',
          title: 'Inbox · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: InboxIsland()),
        ),
        Route(
          path: '/schedules',
          title: 'Payments · Birka',
          builder: (_, _) =>
              const PageFrame(wide: true, child: SchedulesIsland()),
        ),
        Route(
          path: '/payday',
          title: 'Payday · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: PaydayIsland()),
        ),
        Route(
          path: '/ask',
          title: 'Ask · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: AskIsland()),
        ),
        Route(
          path: '/debts',
          title: 'Debts · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: DebtsIsland()),
        ),
        Route(
          path: '/tags',
          title: 'Tags · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: TagsIsland()),
        ),
        Route(
          path: '/notifications',
          title: 'Notifications · Birka',
          builder: (_, _) =>
              const PageFrame(wide: true, child: NotificationsIsland()),
        ),
        Route(
          path: '/data',
          title: 'Data · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: BackupIsland()),
        ),
        Route(
          path: '/help',
          title: 'Help · Birka',
          builder: (_, _) => const PageFrame(wide: true, child: HelpIsland()),
        ),
      ],
    );
  }
}
