import 'dart:io';

import 'package:birka_tools/check_site.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory site;

  /// Writes a file of the site.
  void write(String path, String content) {
    File(p.join(site.path, path))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  /// Writes a page with [body], and [script] run on its load.
  void page(String path, {String body = '', String script = ''}) => write(
    '${path}index.html',
    '''
    <!doctype html>
    <html>
      <head>
        <title>Page</title>
        <link rel="icon" href="data:,">
        <script>$script</script>
      </head>
      <body>$body</body>
    </html>
    ''',
  );

  /// Serves the site under `/Birka/` and opens all of its pages.
  Future<List<SiteProblem>> check() => checkSite(site, base: '/Birka/');

  setUp(() => site = Directory.systemTemp.createTempSync('birka-site'));
  tearDown(() => site.deleteSync(recursive: true));

  group('pagesOf', () {
    test('finds every page, the first one first', () {
      page('');
      page('reports/');
      page('accounts/');
      write('main.js', '');
      write('packages/design_tokens/fonts.css', '');

      expect(pagesOf(site), ['', 'accounts/', 'reports/']);
    });
  });

  group('serveSite', () {
    late HttpServer server;
    late HttpClient client;

    setUp(() async {
      page('');
      page('reports/');
      write('sqlite3.wasm', 'wasm');
      server = await serveSite(site, base: '/Birka/');
      client = HttpClient();
    });
    tearDown(() async {
      client.close();
      await server.close();
    });

    Future<HttpClientResponse> get(String path) async {
      final request = await client.get('localhost', server.port, path);
      return request.close();
    }

    test('answers under the base', () async {
      expect((await get('/Birka/')).statusCode, 200);
      expect((await get('/Birka/reports/')).statusCode, 200);
    });

    test('answers nothing outside it', () async {
      expect((await get('/')).statusCode, 404);
      expect((await get('/reports/')).statusCode, 404);
      expect((await get('/Birkaa/')).statusCode, 404);
    });

    test('names the type of WebAssembly, which a browser insists on', () async {
      final response = await get('/Birka/sqlite3.wasm');

      expect(response.headers.contentType?.mimeType, 'application/wasm');
    });
  });

  group('checkSite', () {
    test('passes quiet pages', () async {
      page('');
      page('reports/', body: '<h1>Reports</h1>');

      expect(await check(), isEmpty);
    });

    test('says when a site has no pages', () async {
      expect(await check(), hasLength(1));
    });

    test('reports an error in the console on its page', () async {
      page('');
      page('reports/', script: r'console.error("Error while\nbuilding\nbs");');

      final problems = await check();

      expect(problems.map((problem) => problem.page), ['reports/']);
      expect(problems.single.message, 'Error while building');
    });

    test('reports what nobody caught', () async {
      page('', script: 'throw new TypeError("not a subtype");');

      final problems = await check();

      expect(problems.single.message, contains('not a subtype'));
    });

    test('reports a file that the page cannot find', () async {
      page('', body: '<img src="missing.png">');

      final problems = await check();

      expect(problems.single.message, contains('404'));
    });

    test('leaves alone a file of another host', () async {
      page('', body: '<img src="http://localhost:9/rates.png">');

      expect(await check(), isEmpty);
    });

    test('leaves warnings alone', () async {
      page('', script: 'console.warn("old"); console.log("fine");');

      expect(await check(), isEmpty);
    });

    test('looks at the pages without shared workers too', () async {
      page(
        '',
        script: '''
          if (!('SharedWorker' in window)) console.error('no shared workers');
        ''',
      );

      final problems = await check();

      expect(problems.single.message, 'no shared workers');
    });

    test('does not carry a report over to the next page', () async {
      page('', script: 'console.error("broken");');
      page('reports/');

      final problems = await check();

      expect(problems.map((problem) => problem.page), ['']);
    });

    test('waits for what a page requests after its load', () async {
      page(
        '',
        script: '''
          addEventListener('load', () => setTimeout(() => {
            const script = document.createElement('script');
            script.src = 'part.js';
            document.head.append(script);
          }, 300));
        ''',
      );
      write('part.js', 'console.error("a part failed");');

      final problems = await check();

      expect(problems.single.message, 'a part failed');
    });

    test('reports a placeholder that nothing replaced', () async {
      page('', body: '<div class="birka-placeholder"></div>');
      final server = await serveSite(site, base: '/Birka/');
      addTearDown(server.close);

      final problems = await checkPages(
        Uri.parse('http://localhost:${server.port}/Birka/'),
        pagesOf(site),
        patience: const Duration(seconds: 2),
      );

      expect(problems.single.message, contains('did not finish'));
    });
  });
}
