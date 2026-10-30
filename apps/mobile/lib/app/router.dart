import 'package:birka_mobile/app/app_shell.dart';
import 'package:birka_mobile/app/placeholder_page.dart';
import 'package:birka_mobile/app/strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The paths of the app.
abstract final class Paths {
  /// The first screen.
  static const overview = '/overview';

  /// The list of operations.
  static const operations = '/operations';

  /// The reports.
  static const reports = '/reports';

  /// Everything else.
  static const more = '/more';

  /// The sheet that adds an operation, over any tab.
  static const quickAdd = '/quick-add';
}

/// Builds the router: the tabs keep their state in a shell, and quick add
/// opens over them.
GoRouter buildRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  StatefulShellBranch tab(String path, String title) => StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (context, state) => PlaceholderPage(title: title),
      ),
    ],
  );
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Paths.overview,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          tab(Paths.overview, Strings.overview),
          tab(Paths.operations, Strings.operations),
          tab(Paths.reports, Strings.reports),
          tab(Paths.more, Strings.more),
        ],
      ),
      GoRoute(
        path: Paths.quickAdd,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: QuickAddPlaceholder(),
        ),
      ),
    ],
  );
}
