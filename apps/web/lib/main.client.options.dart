// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:birka_web/components/capital_preview.dart'
    deferred as _capital_preview;
import 'package:birka_web/pages/accounts_island.dart'
    deferred as _accounts_island;
import 'package:birka_web/pages/backup_island.dart' deferred as _backup_island;
import 'package:birka_web/pages/categories_island.dart'
    deferred as _categories_island;
import 'package:birka_web/pages/help_island.dart' deferred as _help_island;
import 'package:birka_web/pages/import_island.dart' deferred as _import_island;
import 'package:birka_web/pages/inbox_island.dart' deferred as _inbox_island;
import 'package:birka_web/pages/more_island.dart' deferred as _more_island;
import 'package:birka_web/pages/notifications_island.dart'
    deferred as _notifications_island;
import 'package:birka_web/pages/operations_island.dart'
    deferred as _operations_island;
import 'package:birka_web/pages/overview_island.dart'
    deferred as _overview_island;
import 'package:birka_web/pages/payday_island.dart' deferred as _payday_island;
import 'package:birka_web/pages/reports_island.dart'
    deferred as _reports_island;
import 'package:birka_web/pages/schedules_island.dart'
    deferred as _schedules_island;
import 'package:birka_web/pages/tags_island.dart' deferred as _tags_island;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'capital_preview': ClientLoader(
      (p) => _capital_preview.CapitalPreview(),
      loader: _capital_preview.loadLibrary,
    ),
    'accounts_island': ClientLoader(
      (p) => _accounts_island.AccountsIsland(),
      loader: _accounts_island.loadLibrary,
    ),
    'backup_island': ClientLoader(
      (p) => _backup_island.BackupIsland(),
      loader: _backup_island.loadLibrary,
    ),
    'categories_island': ClientLoader(
      (p) => _categories_island.CategoriesIsland(),
      loader: _categories_island.loadLibrary,
    ),
    'help_island': ClientLoader(
      (p) => _help_island.HelpIsland(),
      loader: _help_island.loadLibrary,
    ),
    'import_island': ClientLoader(
      (p) => _import_island.ImportIsland(),
      loader: _import_island.loadLibrary,
    ),
    'inbox_island': ClientLoader(
      (p) => _inbox_island.InboxIsland(),
      loader: _inbox_island.loadLibrary,
    ),
    'more_island': ClientLoader(
      (p) => _more_island.MoreIsland(),
      loader: _more_island.loadLibrary,
    ),
    'notifications_island': ClientLoader(
      (p) => _notifications_island.NotificationsIsland(),
      loader: _notifications_island.loadLibrary,
    ),
    'operations_island': ClientLoader(
      (p) => _operations_island.OperationsIsland(),
      loader: _operations_island.loadLibrary,
    ),
    'overview_island': ClientLoader(
      (p) => _overview_island.OverviewIsland(),
      loader: _overview_island.loadLibrary,
    ),
    'payday_island': ClientLoader(
      (p) => _payday_island.PaydayIsland(),
      loader: _payday_island.loadLibrary,
    ),
    'reports_island': ClientLoader(
      (p) => _reports_island.ReportsIsland(),
      loader: _reports_island.loadLibrary,
    ),
    'schedules_island': ClientLoader(
      (p) => _schedules_island.SchedulesIsland(),
      loader: _schedules_island.loadLibrary,
    ),
    'tags_island': ClientLoader(
      (p) => _tags_island.TagsIsland(),
      loader: _tags_island.loadLibrary,
    ),
  },
);
