import 'package:drift/drift.dart';

/// The local database, once the browser has opened it.
final class OpenedDatabase {
  /// Creates the result. Without [persists] the data lives only in memory.
  const OpenedDatabase(this.executor, {required this.persists});

  /// The connection.
  final QueryExecutor executor;

  /// Whether the data outlives the tab.
  final bool persists;
}

/// Another tab holds the database, and a second one could overwrite its data.
final class OpenInAnotherTab implements Exception {
  /// Creates the exception.
  const OpenInAnotherTab();
}
