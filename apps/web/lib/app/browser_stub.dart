import 'dart:typed_data';

import 'package:backup_common/backup_common.dart';
import 'package:birka_web/app/opened_database.dart';
import 'package:help_common/help_common.dart';
import 'package:import_common/import_common.dart';

/// The islands stop at `kIsWeb` on the VM, so nothing here ever runs.
Never _unavailable() => throw UnsupportedError('This needs a browser.');

/// See `browser_web.dart`.
Future<OpenedDatabase> openLocalDatabase(String name) => _unavailable();

/// See `browser_web.dart`.
void logError(Object error, StackTrace stack) => _unavailable();

/// See `browser_web.dart`.
String get browserLanguage => _unavailable();

/// See `browser_web.dart`.
void describePage({required String language, required String title}) =>
    _unavailable();

/// See `browser_web.dart`.
String get addressFragment => _unavailable();

/// See `browser_web.dart`.
void Function() watchAddressFragment(void Function() listener) =>
    _unavailable();

/// See `browser_web.dart`.
void replaceAddressFragment(String fragment) => _unavailable();

/// See `browser_web.dart`.
void goBackInHistory() => _unavailable();

/// See `browser_web.dart`.
void openSitePage(String path) => _unavailable();

/// Whether another page of the site led here.
bool get cameFromSite => _unavailable();

/// See `browser_web.dart`.
double get pageScroll => _unavailable();

/// See `browser_web.dart`.
void scrollPageTo(double top) => _unavailable();

/// See `browser_web.dart`.
void Function() watchTabShown(void Function() listener) => _unavailable();

/// See `browser_web.dart`.
bool get wideScreen => _unavailable();

/// See `browser_web.dart`.
void Function() watchWideScreen(
  void Function({required bool wide}) listener,
) => _unavailable();

/// See `browser_web.dart`.
bool? get amountsHidden => _unavailable();

/// See `browser_web.dart`.
void keepAmountsHidden({required bool hidden}) => _unavailable();

/// See `browser_web.dart`.
void reportError(Object error, StackTrace stack) => _unavailable();

/// See `browser_web.dart`.
void sayOnNextPage(String text) => _unavailable();

/// See `browser_web.dart`.
String? takeSaid() => _unavailable();

/// See `browser_web.dart`.
String? keptValue(String key) => _unavailable();

/// See `browser_web.dart`.
void keepValue(String key, String value) => _unavailable();

/// See `browser_web.dart`.
final class BrowserBackupFiles implements BackupFiles {
  /// See `browser_web.dart`.
  const BrowserBackupFiles();

  @override
  Future<bool> save({
    required String name,
    required String type,
    required Uint8List bytes,
  }) => _unavailable();

  @override
  Future<ChosenFile?> open() => _unavailable();
}

/// See `browser_web.dart`.
final class BrowserStatementFiles implements StatementFiles {
  /// See `browser_web.dart`.
  const BrowserStatementFiles();

  @override
  Future<ChosenStatement?> choose() => _unavailable();
}

/// See `browser_web.dart`.
final class BrowserHelpLinks implements HelpLinks {
  /// See `browser_web.dart`.
  const BrowserHelpLinks();

  @override
  Future<bool> mail(Uri letter) => _unavailable();

  @override
  Future<bool> open(Uri page) => _unavailable();

  @override
  Future<void> copy(String text) => _unavailable();
}

/// See `browser_web.dart`.
AppAbout get browserAbout => _unavailable();
