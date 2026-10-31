// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:birka_web/components/capital_preview.dart'
    deferred as _capital_preview;
import 'package:birka_web/pages/accounts_island.dart'
    deferred as _accounts_island;
import 'package:birka_web/pages/categories_island.dart'
    deferred as _categories_island;
import 'package:birka_web/pages/operations_island.dart'
    deferred as _operations_island;
import 'package:birka_web/pages/overview_island.dart'
    deferred as _overview_island;

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
    'categories_island': ClientLoader(
      (p) => _categories_island.CategoriesIsland(),
      loader: _categories_island.loadLibrary,
    ),
    'operations_island': ClientLoader(
      (p) => _operations_island.OperationsIsland(),
      loader: _operations_island.loadLibrary,
    ),
    'overview_island': ClientLoader(
      (p) => _overview_island.OverviewIsland(),
      loader: _overview_island.loadLibrary,
    ),
  },
);
