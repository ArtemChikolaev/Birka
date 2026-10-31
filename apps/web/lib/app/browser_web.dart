import 'dart:async';
import 'dart:js_interop';

import 'package:birka_web/app/opened_database.dart';
import 'package:drift/wasm.dart';
import 'package:web/web.dart' as web;

/// Opens the database in the storage that Drift picks for this browser
/// (ADR 0009). The paths go through `<base href>`, because a worker resolves
/// a relative one against itself.
Future<OpenedDatabase> openLocalDatabase() async {
  final base = Uri.parse(web.document.baseURI);
  final opened = await WasmDatabase.open(
    databaseName: 'birka',
    sqlite3Uri: base.resolve('sqlite3.wasm'),
    driftWorkerUri: base.resolve('drift_worker.dart.js'),
  );
  final storage = opened.chosenImplementation;
  if (storage == WasmStorageImplementation.unsafeIndexedDb &&
      !await _holdTheOnlyTab()) {
    await opened.resolvedExecutor.close();
    throw const OpenInAnotherTab();
  }
  return OpenedDatabase(
    opened.resolvedExecutor,
    persists: storage != WasmStorageImplementation.inMemory,
  );
}

/// Takes a lock for as long as the tab lives, or says that another tab has it.
Future<bool> _holdTheOnlyTab() {
  final taken = Completer<bool>();
  JSPromise<JSAny?>? hold(web.Lock? lock) {
    taken.complete(lock != null);
    // The lock lasts until this promise settles, and this one never does.
    return lock == null ? null : Completer<JSAny?>().future.toJS;
  }

  unawaited(
    web.window.navigator.locks
        .request(
          'birka-database',
          web.LockOptions(ifAvailable: true),
          hold.toJS,
        )
        .toDart,
  );
  return taken.future;
}

/// Leaves a failure in the console, the only place to see it in the browser.
void logError(Object error, StackTrace stack) {
  web.console.error('$error\n$stack'.toJS);
}

/// The language of the browser, such as `ru`.
String get browserLanguage => web.window.navigator.language.split('-').first;

/// Tells the browser what the static page could not know at build time.
void describePage({required String language, required String title}) {
  web.document.documentElement?.setAttribute('lang', language);
  web.document.title = title;
}

/// The part of the address after `#`.
String get addressFragment => web.window.location.hash.replaceFirst('#', '');

/// Calls [listener] when the fragment changes, until the returned function is
/// called.
void Function() watchAddressFragment(void Function() listener) {
  final callback = ((web.Event _) => listener()).toJS;
  web.window.addEventListener('hashchange', callback);
  return () => web.window.removeEventListener('hashchange', callback);
}

/// Puts [fragment] on the current address, or takes the fragment off it when
/// it is empty, without a step in history.
void replaceAddressFragment(String fragment) {
  final location = web.window.location;
  final hash = fragment.isEmpty ? '' : '#$fragment';
  web.window.history.replaceState(
    null,
    '',
    '${location.pathname}${location.search}$hash',
  );
}

/// Does what the back button of the browser does.
void goBackInHistory() => web.window.history.back();

/// How far down the page is.
double get pageScroll => web.window.scrollY;

/// Moves the page so that it stands [top] pixels down.
void scrollPageTo(double top) => web.window.scrollTo(0.toJS, top);

/// Calls [listener] when the tab comes back into view, until the returned
/// function is called.
void Function() watchTabShown(void Function() listener) {
  final callback = ((web.Event _) {
    if (web.document.visibilityState == 'visible') listener();
  }).toJS;
  web.document.addEventListener('visibilitychange', callback);
  return () => web.document.removeEventListener('visibilitychange', callback);
}
