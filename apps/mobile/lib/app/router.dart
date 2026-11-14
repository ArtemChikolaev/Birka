import 'dart:async';

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/accounts_flutter.dart';
import 'package:ask_common/ask_common.dart' show AskAnswer, AskCubit, AskPlace;
import 'package:ask_flutter/ask_flutter.dart';
import 'package:backup_common/backup_common.dart'
    show BackupCubit, SettingsStore, demoStateIn;
import 'package:backup_flutter/backup_flutter.dart';
import 'package:birka_mobile/app/app_shell.dart';
import 'package:birka_mobile/app/more_page.dart';
import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/categories_flutter.dart';
import 'package:debts_common/debts_common.dart'
    show DebtFormCubit, DebtReturnCubit, DebtTermsCubit, DebtsCubit;
import 'package:debts_flutter/debts_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:help_common/help_common.dart' show HelpCubit, HelpLinks;
import 'package:help_flutter/help_flutter.dart';
import 'package:import_common/import_common.dart'
    show ImportCubit, StatementFiles;
import 'package:import_flutter/import_flutter.dart';
import 'package:inbox_common/inbox_common.dart'
    show InboxCubit, InboxSummaryCubit;
import 'package:inbox_flutter/inbox_flutter.dart';
import 'package:ledger/ledger.dart' show TagMarking;
import 'package:notifications_common/notifications_common.dart'
    show NoticePlace, NotificationsCubit, NotificationsSummaryCubit;
import 'package:notifications_flutter/notifications_flutter.dart';
import 'package:onboarding_common/onboarding_common.dart' show OnboardingCubit;
import 'package:onboarding_flutter/onboarding_flutter.dart';
import 'package:overview_common/overview_common.dart' show OverviewCubit;
import 'package:overview_flutter/overview_flutter.dart';
import 'package:reports_common/reports_common.dart' show ReportsCubit;
import 'package:reports_flutter/reports_flutter.dart';
import 'package:schedules_common/schedules_common.dart'
    show
        OperationScheduleCubit,
        RemindersCubit,
        ScheduleFormCubit,
        SchedulesCubit,
        SchedulesRepository,
        repeatNames;
import 'package:schedules_flutter/schedules_flutter.dart';
import 'package:settings_common/settings_common.dart' show SettingsCubit;
import 'package:settings_flutter/settings_flutter.dart'
    show showMonthStartSheet;
import 'package:tags_common/tags_common.dart'
    show
        OperationTagsCubit,
        TagFormCubit,
        TagPickerCubit,
        TagReportCubit,
        TagsCubit;
import 'package:tags_flutter/tags_flutter.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

/// The paths of the app.
abstract final class Paths {
  /// What a new device starts with.
  static const onboarding = '/onboarding';

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

  /// The page of account [id].
  static String account(String id) => '/accounts/$id';

  /// The form of account [id].
  static String editAccount(String id) => '/accounts/$id/edit';

  /// The list of categories.
  static const categories = '/categories';

  /// The data of this device: its copy, its export and its wipe.
  static const backup = '/backup';

  /// Help and feedback.
  static const help = '/help';

  /// What waits for a decision after an import.
  static const inbox = '/inbox';

  /// What Birka told the person (ADR 0026).
  static const notifications = '/notifications';

  /// Questions about money in words (ADR 0028).
  static const ask = '/ask';

  /// The operations an answer counted, under its plaque.
  static const askOperations = '/ask/operations';

  /// The form of a new category of [kind].
  static String newCategory(CategoryKind kind) =>
      '/categories/new?kind=${kind.name}';

  /// The form of category [id].
  static String category(String id) => '/categories/$id';

  /// The regular payments.
  static const schedules = '/schedules';

  /// The form of a new regular payment, which starts as the salary with
  /// [salary].
  static String newSchedule({bool salary = false, String? from}) => switch ((
    salary,
    from,
  )) {
    (true, _) => '/schedules/new?salary=1',
    (_, final from?) => '/schedules/new?from=$from',
    _ => '/schedules/new',
  };

  /// The form of regular payment [id].
  static String schedule(String id) => '/schedules/$id';

  /// The money until the salary.
  static const payday = '/payday';

  /// The метки and trips (ADR 0027).
  static const tags = '/tags';

  /// The form of a new метка, named [name] to begin with.
  static String newTag({String? name}) => name == null
      ? '/tags/new'
      : '/tags/new?name=${Uri.encodeQueryComponent(name)}';

  /// The report of метка [id].
  static String tag(String id) => '/tags/$id';

  /// The form of метка [id].
  static String editTag(String id) => '/tags/$id/edit';

  /// The debts between the person and others (ADR 0029).
  static const debts = '/debts';

  /// The form of a new debt.
  static const newDebt = '/debts/new';

  /// The card of debt [id].
  static String debt(String id) => '/debts/$id';

  /// The form of a return of debt [id].
  static String debtReturn(String id) => '/debts/$id/return';

  /// The form of more money on debt [id].
  static String debtMore(String id) => '/debts/$id/more';

  /// The form of the terms of debt [id].
  static String editDebt(String id) => '/debts/$id/edit';
}

/// Says that an account opens from its card, which grows into the page of the
/// account (ADR 0017).
const _fromCard = 'card';

/// Builds the router: the tabs keep their state in a shell, and everything
/// else opens over them. Pages get their cubits from [getIt], and only a new
/// device has [onboarding], which outlives a router (ADR 0013).
GoRouter buildRouter(
  GetIt getIt, {
  String initialLocation = Paths.overview,
  OnboardingCubit? onboarding,
  ValueChanged<bool>? onDemoChanged,
}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      if (onboarding != null)
        GoRoute(
          path: Paths.onboarding,
          parentNavigatorKey: rootKey,
          builder: (context, state) => BlocProvider.value(
            value: onboarding,
            child: OnboardingPage(onFinished: () => context.go(Paths.overview)),
          ),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.overview,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => getIt<OverviewCubit>()),
                    BlocProvider(create: (_) => getIt<InboxSummaryCubit>()),
                    BlocProvider(create: (_) => getIt<SchedulesCubit>()),
                    BlocProvider(
                      create: (_) => getIt<NotificationsSummaryCubit>(),
                    ),
                  ],
                  child: OverviewPage(
                    onAddAccount: () => context.push(Paths.newAccount),
                    onAccounts: () => context.push(Paths.accounts),
                    onOpenAccount: (id) =>
                        context.push(Paths.account(id), extra: _fromCard),
                    ask: AskButton(onOpen: () => context.push(Paths.ask)),
                    bell: NotificationsBell(
                      onOpen: () => context.push(Paths.notifications),
                    ),
                    notice: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SpendingCard(
                          onOpenPlan: () => context.push(Paths.payday),
                          onOpenList: () => context.push(Paths.schedules),
                        ),
                        InboxCard(onOpen: () => context.push(Paths.inbox)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.operations,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<OperationsCubit>(),
                  child: OperationsPage(
                    onOpen: (id) => context.push(Paths.operation(id)),
                    onOpenDebt: (id) => context.push(Paths.debt(id)),
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
                          tags: BlocProvider(
                            create: (_) =>
                                getIt<OperationTagsCubit>(param1: id),
                            child: OperationTagsRow(
                              onOpen: (tag) => context.push(Paths.tag(tag)),
                              onPick: (context, picked) =>
                                  _pickTags(context, getIt, picked),
                            ),
                          ),
                          schedule: BlocProvider(
                            create: (_) =>
                                getIt<OperationScheduleCubit>(param1: id),
                            child: OperationScheduleRow(
                              onMake: () =>
                                  context.push(Paths.newSchedule(from: id)),
                              onOpen: (schedule) =>
                                  context.push(Paths.schedule(schedule)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.reports,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<ReportsCubit>(),
                  child: const ReportsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Paths.more,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => getIt<SettingsCubit>()),
                    BlocProvider(create: (_) => getIt<InboxSummaryCubit>()),
                    BlocProvider(create: (_) => getIt<RemindersCubit>()),
                    BlocProvider(create: (_) => getIt<DebtsCubit>()),
                  ],
                  child: MorePage(
                    links: getIt<HelpLinks>(),
                    onImport: (context) => showImportSheet(
                      context,
                      cubit: getIt.call<ImportCubit>,
                      files: getIt<StatementFiles>(),
                      onInbox: () => context.push(Paths.inbox),
                      onSchedules: () => context.push(Paths.schedules),
                      repeats: () => repeatNames(getIt<SchedulesRepository>()),
                    ),
                  ),
                ),
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
            onOpenCard: (id) =>
                context.push(Paths.account(id), extra: _fromCard),
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
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              final page = BlocProvider(
                create: (_) => getIt<AccountCubit>(param1: id),
                child: AccountPage(
                  onBack: () => context.pop(),
                  onEdit: () => context.push(Paths.editAccount(id)),
                  onOpen: (operation) =>
                      context.push(Paths.operation(operation)),
                  onOpenDebt: (debt) => context.push(Paths.debt(debt)),
                  onRepeat: (operation) =>
                      context.push(Paths.repeatOperation(operation)),
                ),
              );
              // A card grows into the page of its account, while a row slides
              // the page in as any page deeper in.
              return state.extra == _fromCard
                  ? BirkaZoomPage<void>(
                      key: state.pageKey,
                      tag: id,
                      child: page,
                    )
                  : MaterialPage<void>(key: state.pageKey, child: page);
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootKey,
                pageBuilder: (context, state) =>
                    _formPage(getIt, state.pathParameters['id']),
              ),
            ],
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
        path: Paths.backup,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<BackupCubit>(),
          child: BackupPage(
            onBack: () => context.pop(),
            demo: demoStateIn(getIt<SettingsStore>()).isOn,
            onDemoChanged: onDemoChanged,
          ),
        ),
      ),
      GoRoute(
        path: Paths.help,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<HelpCubit>(),
          child: HelpPage(onBack: () => context.pop()),
        ),
      ),
      GoRoute(
        path: Paths.ask,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AskCubit>(),
          child: AskPage(
            onBack: () => context.pop(),
            onShowOperations: (answer, title) => context.push(
              Paths.askOperations,
              extra: _focusOf(answer, title),
            ),
            onOpenPlace: (place) => _openPlace(context, getIt, place),
            onOpenHelp: () => context.push(Paths.help),
            onOpenOperation: (id) => context.push(Paths.operation(id)),
            onOpenTag: (id) => context.push(Paths.tag(id)),
            // What can be spent today and the next payments are the card of
            // the overview.
            fact: (context, fact) => BlocProvider(
              create: (_) => getIt<SchedulesCubit>(),
              child: SpendingCard(
                onOpenPlan: () => context.push(Paths.payday),
                onOpenList: () => context.push(Paths.schedules),
              ),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'operations',
            parentNavigatorKey: rootKey,
            builder: (context, state) => Scaffold(
              backgroundColor: Colors.transparent,
              body: AmbientBackground(
                child: BlocProvider(
                  create: (_) => getIt<OperationsCubit>(
                    param1: state.extra is OperationsFocus
                        ? state.extra! as OperationsFocus
                        : null,
                  ),
                  child: OperationsPage(
                    onOpen: (id) => context.push(Paths.operation(id)),
                    onOpenDebt: (id) => context.push(Paths.debt(id)),
                    onRepeat: (id) => context.push(Paths.repeatOperation(id)),
                    onBack: () => context.pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Paths.schedules,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SchedulesCubit>(),
          child: SchedulesPage(
            onBack: () => context.pop(),
            onAdd: () => context.push(Paths.newSchedule()),
            onOpen: (id) => context.push(Paths.schedule(id)),
            onFind: (id) => context.push(Paths.newSchedule(from: id)),
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) => _scheduleFormPage(
              getIt,
              salary: state.uri.queryParameters['salary'] == '1',
              from: state.uri.queryParameters['from'],
            ),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) =>
                _scheduleFormPage(getIt, id: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: Paths.tags,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<TagsCubit>(),
          child: TagsPage(
            onBack: () => context.pop(),
            onAdd: () => context.push(Paths.newTag()),
            onOpen: (id) => context.push(Paths.tag(id)),
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) =>
                _tagFormPage(getIt, name: state.uri.queryParameters['name']),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => getIt<TagReportCubit>(param1: id),
                  ),
                  BlocProvider(
                    create: (_) => getIt<TagOperationsCubit>(param1: id),
                  ),
                ],
                child: TagReportPage(
                  onBack: () => context.pop(),
                  onEdit: () => context.push(Paths.editTag(id)),
                  operations: TagOperations(
                    onOpen: (operation) =>
                        context.push(Paths.operation(operation)),
                    onOpenDebt: (debt) => context.push(Paths.debt(debt)),
                    onRepeat: (operation) =>
                        context.push(Paths.repeatOperation(operation)),
                  ),
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootKey,
                pageBuilder: (context, state) =>
                    _tagFormPage(getIt, id: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Paths.debts,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<DebtsCubit>(),
          child: DebtsPage(
            onBack: () => context.pop(),
            onAdd: () => context.push(Paths.newDebt),
            onOpen: (id) => context.push(Paths.debt(id)),
          ),
        ),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootKey,
            pageBuilder: (context, state) => _debtFormPage(getIt),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return BlocProvider(
                create: (_) => getIt<DebtsCubit>(),
                child: DebtPage(
                  id: id,
                  onBack: () => context.pop(),
                  onEdit: () => context.push(Paths.editDebt(id)),
                  onReturn: () => context.push(Paths.debtReturn(id)),
                  onMore: () => context.push(Paths.debtMore(id)),
                  onOpenStep: (operation) =>
                      context.push(Paths.operation(operation)),
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'return',
                parentNavigatorKey: rootKey,
                pageBuilder: (context, state) => BirkaSheetPage(
                  child: BlocProvider(
                    create: (_) => getIt<DebtReturnCubit>(
                      param1: state.pathParameters['id'],
                    ),
                    child: Builder(
                      builder: (context) =>
                          DebtReturnPage(onClose: () => context.pop()),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: 'more',
                parentNavigatorKey: rootKey,
                pageBuilder: (context, state) =>
                    _debtFormPage(getIt, id: state.pathParameters['id']),
              ),
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootKey,
                pageBuilder: (context, state) => BirkaSheetPage(
                  child: BlocProvider(
                    create: (_) => getIt<DebtTermsCubit>(
                      param1: state.pathParameters['id'],
                    ),
                    child: Builder(
                      builder: (context) =>
                          DebtTermsPage(onClose: () => context.pop()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Paths.payday,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SchedulesCubit>(),
          child: PaydayPage(
            onBack: () => context.pop(),
            onOpenSalary: (id) => context.push(Paths.schedule(id)),
            onAddSalary: () => context.push(Paths.newSchedule(salary: true)),
            onMonthStart: () => unawaited(_pickMonthStart(context, getIt)),
          ),
        ),
      ),
      GoRoute(
        path: Paths.inbox,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<InboxCubit>(),
          child: InboxPage(
            onBack: () => context.pop(),
            // The form gives the category it made, which the operations get.
            onNewCategory: (kind) =>
                context.push<Category>(Paths.newCategory(kind)),
            // A statement imported here comes into this inbox at once.
            onImport: () => unawaited(
              showImportSheet(
                context,
                cubit: getIt.call<ImportCubit>,
                files: getIt<StatementFiles>(),
                onSchedules: () => context.push(Paths.schedules),
                repeats: () => repeatNames(getIt<SchedulesRepository>()),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: Paths.notifications,
        parentNavigatorKey: rootKey,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<NotificationsCubit>(),
          child: NotificationsPage(
            onBack: () => context.pop(),
            onOpen: (place, id) => context.push(switch (place) {
              NoticePlace.schedules => Paths.schedules,
              NoticePlace.schedule when id != null => Paths.schedule(id),
              NoticePlace.schedule => Paths.schedules,
              NoticePlace.inbox => Paths.inbox,
              NoticePlace.debt when id != null => Paths.debt(id),
              NoticePlace.debt => Paths.debts,
            }),
          ),
        ),
      ),
      GoRoute(
        path: Paths.quickAdd,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => BirkaSheetPage(
          child: BlocProvider(
            create: (_) =>
                getIt<QuickAddCubit>(param1: _quickAddSource(state.uri)),
            child: Builder(
              builder: (context) => QuickAddPage(
                onClose: () => context.pop(),
                onAddAccount: () => context.push<void>(Paths.newAccount),
                onAddCategories: () => context.push<void>(Paths.categories),
                onPickTags: (context, picked) =>
                    _pickTags(context, getIt, picked),
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

/// A new account opens as a sheet, and a change of one fades in over its
/// page, where the card stays in place (ADR 0017).
Page<void> _formPage(GetIt getIt, String? accountId) {
  final form = BlocProvider(
    create: (_) => getIt<AccountFormCubit>(param1: accountId),
    child: Builder(
      builder: (context) => AccountFormPage(onClose: () => context.pop()),
    ),
  );
  return accountId == null
      ? BirkaSheetPage(child: form)
      : BirkaFadePage(child: form);
}

/// The form of a category; a new one closes with the category it made, for
/// whatever pushed it to make one.
Page<Category> _categoryFormPage(
  GetIt getIt, {
  String? categoryId,
  CategoryKind? kind,
}) => BirkaSheetPage(
  child: BlocProvider(
    create: (_) => getIt<CategoryFormCubit>(param1: categoryId, param2: kind),
    child: Builder(
      builder: (context) => CategoryFormPage(
        onClose: () => context.pop(),
        onSaved: (category) => context.pop(category),
      ),
    ),
  ),
);

/// The form of a regular payment, as a sheet (ADR 0023): payment [id], or a
/// new one, which starts as the salary with [salary].
Page<void> _scheduleFormPage(
  GetIt getIt, {
  String? id,
  bool salary = false,
  String? from,
}) => BirkaSheetPage(
  child: BlocProvider(
    create: (_) => getIt<ScheduleFormCubit>(
      param1: id,
      param2: (salary: salary, from: from),
    ),
    child: Builder(
      builder: (context) => ScheduleFormPage(
        onClose: () => context.pop(),
        onEnableReminders: () => unawaited(_enableReminders(context, getIt)),
      ),
    ),
  ),
);

/// The form of a метка, as a sheet (ADR 0027): метка [id], or a new one
/// named [name]. It closes with what it saved, for whatever pushed it.
Page<TagMarking?> _tagFormPage(GetIt getIt, {String? id, String? name}) =>
    BirkaSheetPage(
      child: BlocProvider(
        create: (_) => getIt<TagFormCubit>(param1: id, param2: name),
        child: Builder(
          builder: (context) => TagFormPage(onClose: context.pop),
        ),
      ),
    );

/// The form of a new debt, or of more money on debt [id] (ADR 0029).
Page<String?> _debtFormPage(GetIt getIt, {String? id}) => BirkaSheetPage(
  child: BlocProvider(
    create: (_) => getIt<DebtFormCubit>(param1: id),
    child: Builder(
      builder: (context) => DebtFormPage(onClose: context.pop),
    ),
  ),
);

/// Lets the person pick the метки of an operation, starting from [picked]
/// (ADR 0027). A метка made from the search of the picker opens its form
/// over it, and comes back picked.
Future<Set<String>> _pickTags(
  BuildContext context,
  GetIt getIt,
  Set<String> picked,
) => showTagPicker(
  context,
  cubit: getIt<TagPickerCubit>(param1: picked),
  onCreate: (context, name) async {
    final made = await context.push<TagMarking>(Paths.newTag(name: name));
    return made?.tag.id;
  },
);

/// Asks which day the months start on, from the page of the money until the
/// salary, and keeps it as the settings do: it is one setting (ADR 0024).
Future<void> _pickMonthStart(BuildContext context, GetIt getIt) async {
  final settings = getIt<SettingsCubit>();
  try {
    final day = await showMonthStartSheet(
      context,
      selected: settings.state.monthStart,
    );
    if (day != null) await settings.monthStartChanged(day);
  } finally {
    await settings.close();
  }
}

/// Turns the reminders on from the form of a payment whose reminders are
/// off, as «Ещё» does (ADR 0025).
Future<void> _enableReminders(BuildContext context, GetIt getIt) async {
  final reminders = getIt<RemindersCubit>();
  try {
    // The settings and the payments come in while the phone answers.
    await reminders.accessChecked();
    if (context.mounted) await turnRemindersOn(context, reminders);
  } finally {
    await reminders.close();
  }
}

/// The operations that [answer] counted, under the plaque [title], from the
/// day of the first of them to the day of the last: the list comes back to
/// the month of the last one once the plaque goes, whatever day the months
/// of the question start on.
OperationsFocus _focusOf(AskAnswer answer, String title) {
  final days = [
    for (final operation in answer.operations) operation.transaction.occurredOn,
  ]..sort();
  return OperationsFocus(
    title: title,
    ids: {for (final operation in answer.operations) operation.transaction.id},
    first: days.first,
    last: days.last,
  );
}

/// Opens the screen of [place] from «Спросить»: a tab in place of it, the
/// import in its sheet, and any other screen over it.
void _openPlace(BuildContext context, GetIt getIt, AskPlace place) {
  final path = switch (place) {
    AskPlace.payday => Paths.payday,
    AskPlace.schedules => Paths.schedules,
    AskPlace.tags => Paths.tags,
    AskPlace.accounts => Paths.accounts,
    AskPlace.categories => Paths.categories,
    AskPlace.inbox => Paths.inbox,
    AskPlace.backup => Paths.backup,
    AskPlace.help => Paths.help,
    AskPlace.notifications => Paths.notifications,
    AskPlace.reports => Paths.reports,
    AskPlace.settings => Paths.more,
    AskPlace.imports => null,
  };
  if (path == null) {
    unawaited(
      showImportSheet(
        context,
        cubit: getIt.call<ImportCubit>,
        files: getIt<StatementFiles>(),
        onSchedules: () => context.push(Paths.schedules),
        repeats: () => repeatNames(getIt<SchedulesRepository>()),
      ),
    );
  } else if (path == Paths.reports || path == Paths.more) {
    context.go(path);
  } else {
    unawaited(context.push(path));
  }
}
