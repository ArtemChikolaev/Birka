import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:birka_web/app/flush_after_commit.dart';
import 'package:birka_web/app/opened_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

const _databaseName = 'birka';

/// Opens the database in the storage that Drift picks for this browser, or in
/// the page where there are no shared workers (ADR 0009). The paths go through
/// `<base href>`, because a worker resolves a relative one against itself.
Future<OpenedDatabase> openLocalDatabase() async {
  final base = Uri.parse(web.document.baseURI);
  final sqlite3Uri = base.resolve('sqlite3.wasm');
  final sharedWorkers = globalContext.has('SharedWorker');
  if (!sharedWorkers) {
    if (!await _holdTheOnlyTab()) throw const OpenInAnotherTab();
    final executor = await _openInThePage(sqlite3Uri);
    if (executor != null) return OpenedDatabase(executor, persists: true);
  }
  final opened = await WasmDatabase.open(
    databaseName: _databaseName,
    sqlite3Uri: sqlite3Uri,
    driftWorkerUri: base.resolve('drift_worker.dart.js'),
  );
  final storage = opened.chosenImplementation;
  if (sharedWorkers &&
      storage == WasmStorageImplementation.unsafeIndexedDb &&
      !await _holdTheOnlyTab()) {
    await opened.resolvedExecutor.close();
    throw const OpenInAnotherTab();
  }
  _letGoWhenLeaving(opened.resolvedExecutor);
  return OpenedDatabase(
    opened.resolvedExecutor,
    persists: storage != WasmStorageImplementation.inMemory,
  );
}

/// A page that leaves can stay alive for a while, frozen, with its transaction
/// still open in the worker, where every other page waits for it. Its Web Lock
/// lives as long, so the worker cannot see it go (ADR 0015). So a leaving page
/// closes its connection, which rolls that transaction back at once, and a page
/// that the back button brings back loads again.
void _letGoWhenLeaving(QueryExecutor executor) {
  web.window.addEventListener(
    'pagehide',
    ((web.Event _) => unawaited(executor.close())).toJS,
  );
  web.window.addEventListener(
    'pageshow',
    ((web.PageTransitionEvent event) {
      if (event.persisted) web.window.location.reload();
    }).toJS,
  );
}

/// Opens the storage that a dedicated worker of Drift would use, in this page.
/// That worker dies with the page and takes unfinished writes along, while here
/// a write can wait for them. Without IndexedDB there is no such storage.
Future<QueryExecutor?> _openInThePage(Uri sqlite3Uri) async {
  final IndexedDbFileSystem files;
  try {
    files = await IndexedDbFileSystem.open(dbName: _databaseName);
  } on Object {
    return null;
  }
  final sqlite3 = await WasmSqlite3.loadFromUrl(sqlite3Uri)
    ..registerVirtualFileSystem(files, makeDefault: true);
  return WasmDatabase(
    sqlite3: sqlite3,
    path: '/database',
    fileSystem: files,
  ).interceptWith(FlushAfterCommit(files.flush));
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

/// Whether another page of the site led here, so that it stands one step back
/// in the history. A link opened in a new tab has nothing to step back to, and
/// a reload from a script names the page itself.
bool get cameFromSite {
  final referrer = web.document.referrer;
  return web.window.history.length > 1 &&
      referrer.startsWith(web.document.baseURI) &&
      Uri.parse(referrer).path != web.window.location.pathname;
}

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

const _amountsHiddenKey = 'birka-amounts-hidden';

/// Whether the amounts are hidden, or `null` before this tab has decided. It
/// lasts as long as the tab, as it lasts as long as the app on a phone, and it
/// carries from page to page. A browser that refuses the storage only loses
/// that.
bool? get amountsHidden {
  try {
    final kept = web.window.sessionStorage.getItem(_amountsHiddenKey);
    return kept == null ? null : kept == '1';
  } on Object {
    return null;
  }
}

/// Remembers whether the amounts are hidden, for as long as the tab lives.
void keepAmountsHidden({required bool hidden}) {
  try {
    web.window.sessionStorage.setItem(_amountsHiddenKey, hidden ? '1' : '0');
  } on Object {
    return;
  }
}

/// What this browser keeps under [key]. A browser that refuses the storage
/// keeps nothing, and the page goes on with the defaults.
String? keptValue(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } on Object {
    return null;
  }
}

/// Keeps [value] under [key] in this browser, between visits.
void keepValue(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } on Object {
    return;
  }
}
