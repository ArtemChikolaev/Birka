import 'package:birka_web/app/opened_database.dart';

/// The islands stop at `kIsWeb` on the VM, so nothing here ever runs.
Never _unavailable() => throw UnsupportedError('This needs a browser.');

/// See `browser_web.dart`.
Future<OpenedDatabase> openLocalDatabase() => _unavailable();

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

/// Whether another page of the site led here.
bool get cameFromSite => _unavailable();

/// See `browser_web.dart`.
double get pageScroll => _unavailable();

/// See `browser_web.dart`.
void scrollPageTo(double top) => _unavailable();

/// See `browser_web.dart`.
void Function() watchTabShown(void Function() listener) => _unavailable();

/// See `browser_web.dart`.
bool? get amountsHidden => _unavailable();

/// See `browser_web.dart`.
void keepAmountsHidden({required bool hidden}) => _unavailable();

/// See `browser_web.dart`.
String? keptValue(String key) => _unavailable();

/// See `browser_web.dart`.
void keepValue(String key, String value) => _unavailable();
