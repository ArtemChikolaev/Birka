import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/accounts_flutter.dart';
import 'package:birka_mobile/app/app_shell.dart';
import 'package:birka_mobile/app/more_page.dart';
import 'package:birka_mobile/app/placeholder_page.dart';
import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/categories_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

/// The paths of the app.
abstract final class Paths {
  /// The first screen.
  static const overview = '/overview';

  /// The list of operations.
  static const operations = '/operations';

  /// The card of operation [id].
  static String operation(String id) => '/operations/$id';

  /// The reports.
  static const reports = '/reports';

  /// Everything else.
  static const more = '/more';

  /// The sheet that adds an operation, over any tab.
  static const quickAdd = '/quick-add';

  /// The sheet with operation [id] to change.
  static String editOperation(String id) => '$quickAdd?edit=$id';

  /// The sheet with operation [id] to record once more.
  static String repeatOperation(String id) => '$quickAdd?repeat=$id';

  /// The list of accounts.
  static const accounts = '/accounts';

  /// The form of a new account.
  static const newAccount = '/accounts/new';

  /// The form of account [id].
  static String account(String id) => '/accounts/$id';

  /// The list of categories.
  static const categories = '/categories';

  /// The form of a new category of [kind].
  static String newCategory(CategoryKind kind) =>
      '/categories/new?kind=${kind.name}';

  /// The form of category [id].
  static String category(String id) => '/categories/$id';
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.operations,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<OperationsCubit>(),
                  child: OperationsPage(
                    onOpen: (id) => context.push(Paths.operation(id)),
                    onRepeat: (id) => context.push(Paths.repeatOperation(id)),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return BlocProvider(
                        create: (_) => getIt<OperationCubit>(param1: id),
                        child: OperationPage(
                          onClose: () => context.pop(),
                          onEdit: () => context.push(Paths.editOperation(id)),
                          onRepeat: () =>
                              context.push(Paths.repeatOperation(id)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
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
        path: Paths.categories,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CategoriesCubit>(),
          child: CategoriesPage(
            onBack: () => context.pop(),
            onAdd: (kind) => context.push(Paths.newCategory(kind)),
            onOpen: (id) => context.push(Paths.category(id)),
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) => _categoryFormPage(
              getIt,
              kind: CategoryKind.values
                  .asNameMap()[state.uri.queryParameters['kind']],
            ),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) => _categoryFormPage(
              getIt,
              categoryId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: Paths.quickAdd,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: BlocProvider(
            create: (_) =>
                getIt<QuickAddCubit>(param1: _quickAddSource(state.uri)),
            child: Builder(
              builder: (context) => QuickAddPage(
                onClose: () => context.pop(),
                onAddAccount: () => context.push<void>(Paths.newAccount),
                onAddCategories: () => context.push<void>(Paths.categories),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

QuickAddSource? _quickAddSource(Uri uri) {
  final edit = uri.queryParameters['edit'];
  if (edit != null) return QuickAddSource.edit(edit);
  final repeat = uri.queryParameters['repeat'];
  return repeat == null ? null : QuickAddSource.repeat(repeat);
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

Page<void> _categoryFormPage(
  GetIt getIt, {
  String? categoryId,
  CategoryKind? kind,
}) => MaterialPage(
  fullscreenDialog: true,
  child: BlocProvider(
    create: (_) => getIt<CategoryFormCubit>(param1: categoryId, param2: kind),
    child: Builder(
      builder: (context) => CategoryFormPage(onClose: () => context.pop()),
    ),
  ),
);
