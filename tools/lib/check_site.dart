/// Opens every page of the built site in Chrome, the only place where its
/// islands run. dart2js splits them into parts when it builds, so a change in
/// one island can break another one, and no test on the VM sees that
/// (ADR 0008).
library;

import 'dart:async';
import 'dart:io';

import 'package:browser_launcher/browser_launcher.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// What went wrong on a page of the site.
final class SiteProblem {
  /// Creates a problem of [page], which is empty for the first page.
  const SiteProblem(this.page, this.message);

  /// The path of the page under the base of the site.
  final String page;

  /// What happened.
  final String message;

  @override
  String toString() => '/$page: $message';
}

/// The first build problem that would prevent the web journeys from starting.
/// The caller can run this before opening a port or starting Chrome.
String? webBuildProblem(Directory site, {required String base}) {
  final uri = Uri.tryParse(base);
  if (uri?.path != base ||
      !base.startsWith('/') ||
      !base.endsWith('/') ||
      base.startsWith('//')) {
    return 'Use a base path with a leading and trailing slash, such as BASE=/Birka/';
  }
  final rebuild = 'Run make build-web BASE=$base';
  final index = File(p.join(site.path, 'index.html'));
  if (!index.existsSync()) return 'Missing ${index.path}. $rebuild';
  final document = html.parse(index.readAsStringSync());
  final builtBase = document.head
      ?.querySelector('base[href]')
      ?.attributes['href'];
  if (builtBase == null) {
    return 'Missing <base href> in ${index.path}. $rebuild';
  }
  if (base != builtBase) {
    return 'Site built for "$builtBase" but verification uses "$base". '
        '$rebuild or repeat verification with BASE=$builtBase';
  }
  const runtimeFiles = [
    'main.client.dart.js',
    'drift_worker.dart.js',
    'sqlite3.wasm',
  ];
  for (final name in runtimeFiles) {
    final file = File(p.join(site.path, name));
    if (!file.existsSync() || file.lengthSync() == 0) {
      return 'Missing or empty ${file.path}. $rebuild';
    }
  }
  return null;
}

/// The pages of the site in [site]: every `index.html`, the first page first.
List<String> pagesOf(Directory site) {
  final folders = [
    for (final file in site.listSync(recursive: true).whereType<File>())
      if (p.basename(file.path) == 'index.html')
        p.relative(file.parent.path, from: site.path),
  ]..sort();
  return [for (final folder in folders) folder == '.' ? '' : '$folder/'];
}

/// Serves [site] on a free port, under [base] as GitHub Pages does: nothing
/// answers outside it.
Future<HttpServer> serveSite(Directory site, {required String base}) {
  final files = createStaticHandler(site.path, defaultDocument: 'index.html');
  final prefix = base.replaceAll(RegExp(r'^/|/$'), '');
  return shelf_io.serve(
    (request) {
      if (prefix.isEmpty) return files(request);
      final path = request.url.path;
      return path == prefix || path.startsWith('$prefix/')
          ? files(request.change(path: prefix))
          : Response.notFound('');
    },
    'localhost',
    0,
  );
}

/// Opens [pages] of the site at [origin] in a new headless Chrome and returns
/// what they reported. A page has [patience] to finish, and [beforePage] runs
/// before anything else on each of them.
Future<List<SiteProblem>> checkPages(
  Uri origin,
  List<String> pages, {
  Duration patience = const Duration(seconds: 30),
  String? beforePage,
}) async {
  return withSiteTab((connection) async {
    final reports = <String>[];
    final listening = [
      connection.runtime.onConsoleAPICalled
          .where((event) => event.type == 'error')
          .listen((event) => reports.add(_textOf(event))),
      connection.runtime.onExceptionThrown.listen(
        (event) => reports.add(_textOfException(event.exceptionDetails)),
      ),
      connection.log.onEntryAdded
          .where((entry) => entry.level == 'error' && _isOurs(entry, origin))
          .listen((entry) => reports.add('${entry.text} ${entry.url ?? ''}')),
    ];
    await connection.runtime.enable();
    await connection.log.enable();
    await connection.page.enable();
    if (beforePage != null) {
      await connection.page.sendCommand(
        'Page.addScriptToEvaluateOnNewDocument',
        params: {'source': beforePage},
      );
    }

    final problems = <SiteProblem>[];
    for (final page in pages) {
      reports.clear();
      await connection.page.navigate(origin.resolve(page).toString());
      final finished = await _finished(connection, patience);
      problems.addAll([
        if (!finished)
          SiteProblem(page, 'did not finish in ${patience.inSeconds} seconds'),
        for (final report in reports) SiteProblem(page, _short(report)),
      ]);
    }
    await Future.wait(listening.map((listener) => listener.cancel()));
    return problems;
  });
}

/// Runs [visit] in a fresh headless browser with its own profile.
Future<T> withSiteTab<T>(Future<T> Function(WipConnection) visit) async {
  final chrome = await Chrome.startWithDebugPort(const [
    'about:blank',
  ], headless: true);
  try {
    final tab = await chrome.chromeConnection.getTab(
      (tab) => tab.type == 'page',
      retryFor: const Duration(seconds: 5),
    );
    final connection = await tab!.connect();
    try {
      return await visit(connection);
    } finally {
      await connection.close();
    }
  } finally {
    await chrome.close();
  }
}

/// Serves the site built in [site] under [base] and opens all of its pages.
Future<List<SiteProblem>> checkSite(
  Directory site, {
  required String base,
}) async {
  final pages = pagesOf(site);
  if (pages.isEmpty) return const [SiteProblem('', 'the site has no pages')];
  final server = await serveSite(site, base: base);
  try {
    final origin = Uri.parse('http://localhost:${server.port}$base');
    final problems = await checkPages(origin, pages);
    if (problems.isNotEmpty) return problems;
    // Without shared workers the database opens in the page (ADR 0009), which
    // this Chrome would otherwise never show.
    return await checkPages(
      origin,
      pages,
      beforePage: 'delete window.SharedWorker;',
    );
  } finally {
    await server.close();
  }
}

/// A page has finished when its document has loaded, its island has replaced
/// the placeholder of the build, and nothing new has been requested for a
/// while: an island reports its failure right after its parts arrive.
Future<bool> _finished(WipConnection tab, Duration patience) async {
  const calm = 3;
  const look = Duration(milliseconds: 250);
  final deadline = DateTime.now().add(patience);
  var requests = -1;
  var calmLooks = 0;
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(look);
    final seen = await tab.runtime.evaluate('''
      document.readyState === 'complete' &&
          !document.querySelector('.birka-placeholder')
        ? performance.getEntriesByType('resource').length
        : -1
    ''', returnByValue: true);
    final now = seen.value! as int;
    calmLooks = now >= 0 && now == requests ? calmLooks + 1 : 0;
    requests = now;
    if (calmLooks == calm) return true;
  }
  return false;
}

/// Whether [entry] speaks of the site itself. The site reads exchange rates
/// from another host, which may be down while the site is fine.
bool _isOurs(LogEntry entry, Uri origin) =>
    !(entry.url?.startsWith('http') ?? false) ||
    entry.url!.startsWith(origin.origin);

String _textOf(ConsoleAPIEvent event) =>
    event.args.map((arg) => arg.value ?? arg.description).join(' ');

String _textOfException(ExceptionDetails details) =>
    details.exception?.description ?? details.text;

/// The first lines of [report], which say what happened: the rest is a stack
/// in minified names.
String _short(String report) {
  final lines = report.split('\n').map((line) => line.trim());
  return lines.where((line) => line.isNotEmpty).take(2).join(' ');
}
