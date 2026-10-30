import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/accounts_flutter.dart';
import 'package:birka_mobile/app/app_shell.dart';
import 'package:birka_mobile/app/more_page.dart';
import 'package:birka_mobile/app/placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

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

  /// The list of accounts.
  static const accounts = '/accounts';

  /// The form of a new account.
  static const newAccount = '/accounts/new';

  /// The form of account [id].
  static String account(String id) => '/accounts/$id';
}

/// Builds the router: the tabs keep their state in a shell, and everything
/// else opens over them. Pages get their cubits from [getIt].
GoRouter buildRouter(GetIt getIt) {
  final rootKey = GlobalKey<NavigatorState>();
  StatefulShellBranch tab(String path, String Function() title) =>
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: path,
            builder: (context, state) => PlaceholderPage(title: title()),
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
          tab(Paths.overview, () => t.app.overview),
          tab(Paths.operations, () => t.app.operations),
          tab(Paths.reports, () => t.app.reports),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.more,
                builder: (context, state) => const MorePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Paths.accounts,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AccountsCubit>(),
          child: AccountsPage(
            onBack: () => context.pop(),
            onAdd: () => context.push(Paths.newAccount),
            onOpen: (id) => context.push(Paths.account(id)),
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) => _formPage(getIt, null),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) =>
                _formPage(getIt, state.pathParameters['id']),
          ),
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

Page<void> _formPage(GetIt getIt, String? accountId) => MaterialPage(
  fullscreenDialog: true,
  child: BlocProvider(
    create: (_) => getIt<AccountFormCubit>(param1: accountId),
    child: Builder(
      builder: (context) => AccountFormPage(onClose: () => context.pop()),
    ),
  ),
);
