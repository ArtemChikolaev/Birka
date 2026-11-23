import 'dart:convert';
import 'dart:io';

import 'package:birka_tools/check_site.dart';
import 'package:html/parser.dart' as html;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

const _flows = <String, Future<void> Function(_Run)>{
  'category-limit': _categoryLimit,
  'currency-transfer': _currencyTransfer,
  'backup-roundtrip': _backupRoundtrip,
  'statement-reimport': _statementReimport,
};

/// Names accepted by the web verification command.
Iterable<String> get webFlowNames => _flows.keys;

/// Exercises a named flow on a static build served under its real base path.
Future<void> main(List<String> args) async {
  final width = args.length == 4 ? int.tryParse(args.last) : null;
  if (args.length < 3 ||
      args.length > 4 ||
      !_flows.containsKey(args[2]) ||
      (args.length == 4 && (width == null || width < 1 || width > 10000000))) {
    stderr.writeln(
      'Usage: make verify-web FLOW=<${webFlowNames.join('|')}> '
      '[WIDTH=<pixels>]',
    );
    exitCode = 64;
    return;
  }
  final site = Directory(args[0]);
  final base = args[1];
  final flow = args[2];
  final widths = width != null
      ? [width]
      : [390, if (flow == 'currency-transfer') 1440];
  final root = await Directory('build/verify-web').create(recursive: true);
  for (final width in widths) {
    final run = _Run(
      flow,
      base,
      width,
      await root.createTemp('$flow-${width}px-'),
    );
    stdout.writeln('Verification evidence: ${run.directory.path}');
    try {
      final index = File('${site.path}/index.html');
      if (index.existsSync()) {
        run.buildId = html
            .parse(await index.readAsString())
            .head
            ?.querySelector('meta[name="birka-build"]')
            ?.attributes['content'];
      }
      final problem = webBuildProblem(site, base: base);
      if (problem != null) throw StateError(problem);
      final server = await serveSite(site, base: base);
      try {
        run.origin = Uri.parse('http://localhost:${server.port}$base');
        await _flows[flow]!(run);
      } finally {
        await server.close(force: true);
      }
    } on Object catch (error) {
      run.writeReport(error: error);
      stderr.writeln(error);
      exitCode = 1;
      continue;
    }
    run.writeReport();
  }
}

const _limitNote = 'a[href="limits/#cafe"] .limit-note';
final _fixture = File('tools/fixtures/category-limit.json');

Future<void> _categoryLimit(_Run run) => run.visit((browser) async {
  await browser.restore(_fixture);
  await browser.open('overview/');
  await browser.click('a[href="limits/"]', 'All limits · 1');
  await browser.expect(_limitNote, '₽1,850 left');

  await browser.spend('1850', 'Cafe: ₽0 of ₽12,000 left');
  await browser.open('limits/');
  await browser.expect(_limitNote, '₽0 left');

  await browser.spend('1', 'Cafe: ₽1 over the limit');
  await browser.open('limits/');
  await browser.expect(_limitNote, '₽1 over the limit');
  await browser.reload();
  await browser.expect(_limitNote, '₽1 over the limit');
  stdout.writeln('category-limit: persisted ₽1 over the limit after reload');
});

Future<void> _currencyTransfer(_Run run) => run.visit((browser) async {
  await browser.restore(File('tools/fixtures/currency-transfer.json'));
  await browser.open('accounts/#rub');
  await browser.checkAccount('₽10,000', []);
  await browser.open('accounts/#usd');
  await browser.checkAccount(r'$20', []);

  await browser.newOperation();
  await browser.checkTransferLayout();
  await browser.click('.glass-segmented button', 'Transfer');
  await browser.click('.quick-add__targets button', 'Dollar card');
  await browser.click('.quick-add__line span', 'Leaves');
  await browser.typeAmount('1234.56');
  await browser.expect('.quick-add__line--active .amount', '₽1,234.56');
  await browser.click('.quick-add__line span', 'Arrives');
  await browser.typeAmount('12.34');
  await browser.expect('.quick-add__line--active .amount', r'$12.34');
  await browser.saveOperation('Dollar card');

  await browser.open('accounts/#rub');
  await browser.reload();
  await browser.checkAccount('₽8,765.44', ['−₽1,234.56']);
  await browser.open('accounts/#usd');
  await browser.reload();
  await browser.checkAccount(r'$32.34', [r'+$12.34']);
  await browser.click('.account__operations a');
  await browser.expect('.operation__title', 'Transfer');
  await browser.expect('.operation__summary .amount', r'₽1,234.56 → $12.34');
});

Future<void> _backupRoundtrip(_Run run) async {
  final downloads = await Directory.systemTemp.createTemp('birka-backup-');
  try {
    final copy = await run.visit((browser) async {
      await browser.restore(_fixture);
      await browser.spend('150', 'Cafe: ₽1,700 of ₽12,000 left');
      return browser.saveCopy(downloads);
    });
    // Start another Chrome only after the source browser and its profile close.
    await run.visit((browser) async {
      await browser.restore(copy);
      await browser.reload();
      await browser.open('accounts/#card');
      await browser.checkAccount('₽9,700', ['−₽10,150', '−₽150']);
      await browser.open('limits/');
      await browser.expect(_limitNote, '₽1,700 left');
    });
  } finally {
    await downloads.delete(recursive: true);
  }
}

Future<void> _statementReimport(_Run run) => run.visit((browser) async {
  await browser.restore(_fixture);
  final csv = File('tools/fixtures/statement-reimport.csv');
  const amounts = ['−₽10,150', '−₽250', '+₽1,000'];
  await browser.planImport(csv);
  await browser.click('button', 'Import 2 operations');
  await browser.expect('.import-done__title', 'Added 2 operations');
  await browser.open('accounts/#card');
  await browser.checkAccount('₽10,600', amounts);

  await browser.planImport(csv);
  await browser.expect('h2', '2 operations are already in the ledger');
  await browser.expect('button:disabled', 'Nothing to add');
  await browser.open('accounts/#card');
  await browser.reload();
  await browser.checkAccount('₽10,600', amounts);
});

/// One report covers a whole journey, including both profiles of a restore.
final class _Run {
  _Run(this.flow, this.base, this.width, this.directory);

  final String flow;
  final String base;
  final int width;
  final Directory directory;
  String? buildId;
  Map<String, int>? viewport;
  late final Uri origin;
  final observations = <Map<String, String>>[];

  void writeReport({Object? error}) {
    final report = {
      'flow': flow,
      'base': base,
      'buildId': buildId,
      'requestedWidth': width,
      'viewport': viewport,
      'status': error == null ? 'passed' : 'failed',
      'observations': observations,
      if (error != null) 'error': error.toString(),
    };
    File('${directory.path}/report.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
  }

  Future<T> visit<T>(Future<T> Function(_Browser) journey) =>
      withSiteTab((tab) async {
        try {
          final browser = _Browser(tab, this);
          await browser.prepare();
          return await journey(browser);
        } on Object {
          await captureFailure(tab);
          rethrow;
        }
      });

  // The failing tab is available only until withSiteTab closes its profile.
  Future<void> captureFailure(WipConnection tab) async {
    try {
      final image = await tab.page
          .sendCommand('Page.captureScreenshot')
          .timeout(const Duration(seconds: 5));
      final png = base64Decode(image.result!['data'] as String);
      await File('${directory.path}/failure.png').writeAsBytes(png);
    } on Object catch (error) {
      stderr.writeln('Could not capture the failing page: $error');
    }
  }
}

final class _Browser {
  _Browser(this.tab, this.run);

  final WipConnection tab;
  final _Run run;

  Future<void> prepare() async {
    await tab.page.enable();
    const height = 844;
    await tab.sendCommand('Emulation.setDeviceMetricsOverride', {
      'width': run.width,
      'height': height,
      'deviceScaleFactor': 1,
      'mobile': false,
    });
    final size = await tab.runtime.evaluate(
      '[innerWidth, innerHeight]',
      returnByValue: true,
    );
    if (size.value case [final int width, final int actualHeight]) {
      run.viewport = {'width': width, 'height': actualHeight};
    }
    if (run.viewport?['width'] != run.width ||
        run.viewport?['height'] != height) {
      throw StateError(
        'Requested ${run.width} × $height, Chrome reported ${size.value}',
      );
    }
    // Keep the civil day in the fixture's month while timers and animations
    // still advance normally. This is confined to the temporary tab.
    await tab.page.sendCommand(
      'Page.addScriptToEvaluateOnNewDocument',
      params: {
        'source': '''
        localStorage.setItem('birka-language', 'en');
        const NativeDate = Date;
        const offset = new NativeDate(2026, 10, 18, 12) - NativeDate.now();
        window.Date = class extends NativeDate {
          constructor(...args) { super(...(args.length ? args : [Date.now()])); }
          static now() { return NativeDate.now() + offset; }
        };
      ''',
      },
    );
  }

  Future<void> restore(File file) async {
    await open('data/');
    await chooseFile('Restore from a copy', file);
    await click('button', 'Replace the records');
    await _wait(
      'restored synthetic ledger',
      "document.body.innerText.includes('Records restored from the copy')",
    );
  }

  Future<void> chooseFile(String label, File file) async {
    await tab.page.sendCommand(
      'Page.setInterceptFileChooserDialog',
      params: {'enabled': true},
    );
    await click('button', label);
    await _wait(
      'file chooser for $label',
      "!!document.querySelector('input[type=file]')",
    );
    final input = await tab.runtime.evaluate(
      "document.querySelector('input[type=file]')",
    );
    await tab.dom.sendCommand(
      'DOM.setFileInputFiles',
      params: {
        'objectId': input.objectId,
        'files': [file.absolute.path],
      },
    );
  }

  Future<File> saveCopy(Directory downloads) async {
    await open('data/');
    await tab.sendCommand('Browser.setDownloadBehavior', {
      'behavior': 'allow',
      'downloadPath': downloads.path,
    });
    await click('button', 'Save a copy');
    // Chrome drops the .crdownload suffix when the write is complete.
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 15)) {
      final files = await downloads
          .list()
          .where((entry) => entry.path.endsWith('.birka'))
          .toList();
      if (files.isNotEmpty) return File(files.single.path);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('${run.flow}: no .birka download after saving the copy');
  }

  Future<void> planImport(File csv) async {
    await open('import/');
    await chooseFile('Choose a file', csv);
    await click('button', 'Next: the columns');
    await click('button', 'Next: the account');
    await click('.import-accounts .glass-option__name', 'Test card');
    await click('button', 'Next: duplicates');
  }

  Future<void> checkAccount(String balance, List<String> amounts) async {
    await expect('.account-card .amount', balance);
    const rows = '.account__operations a .amount';
    for (final amount in amounts) {
      await expect(rows, amount);
    }
    await _wait(
      '${amounts.length} operation rows',
      'document.querySelectorAll(${jsonEncode(rows)}).length'
          ' === ${amounts.length}',
    );
  }

  Future<void> reload() async {
    // Wait for a new document so the existing row cannot satisfy the reload.
    await tab.runtime.evaluate('window.beforeJourneyReload = true');
    await tab.page.reload(ignoreCache: true);
    await _wait(
      'new document after reload',
      'window.beforeJourneyReload !== true',
    );
  }

  Future<void> open(String page) async {
    await tab.page.navigate(run.origin.resolve(page).toString());
  }

  Future<void> spend(String amount, String preview) async {
    await newOperation();
    await click('.quick-add button', 'Cafe');
    await typeAmount(amount);
    await expect('.quick-add__limit', preview);
    await saveOperation('Cafe');
  }

  Future<void> newOperation() async {
    await open('operations/');
    await click('a[href="operations/#new"]');
  }

  Future<void> checkTransferLayout() async {
    // ADR 0008 puts the form beside the list from 901 CSS pixels.
    final wide = run.width >= 901;
    final layout = wide ? 'form beside the list' : 'form in place of the list';
    await _wait(layout, '''
      (() => {
        const form = document.querySelector('.quick-add');
        const list = document.querySelector('.operations__tools');
        if (!form?.checkVisibility()) return false;
        const beside = list?.checkVisibility() &&
          list.getBoundingClientRect().right <= form.getBoundingClientRect().left;
        if (${wide ? '!beside' : 'list?.checkVisibility()'}) return false;
        return {page: location.pathname + location.hash, text: '$layout'};
      })()
    ''');
  }

  Future<void> typeAmount(String amount) async {
    for (final key in amount.split('')) {
      await click('.glass-keypad button', key);
    }
  }

  Future<void> saveOperation(String target) async {
    await click('.quick-add button', 'Save · $target');
    await _wait(
      'saved operation for $target',
      "location.hash === '' && !document.querySelector('.quick-add')",
    );
  }

  Future<void> expect(String selector, String text) =>
      _wait(text, _element(selector, text, click: false));

  Future<void> click(String selector, [String? text]) =>
      _wait('click ${text ?? selector}', _element(selector, text, click: true));

  String _element(String selector, String? text, {required bool click}) =>
      '''
    (() => {
      const element = Array.from(document.querySelectorAll(${jsonEncode(selector)}))
        .find(e => e.checkVisibility() && (${!click} || !e.disabled) &&
          (${text == null} || e.innerText.trim().toLowerCase() === ${jsonEncode(text?.toLowerCase())}));
      if (!element) return false;
      if ($click) {
        element.scrollIntoView({block: 'center', inline: 'center', behavior: 'instant'});
        const box = element.getBoundingClientRect();
        // A sticky bar can cover the center but leave an edge reachable.
        for (const [fx, fy] of [[.5,.5], [.25,.5], [.75,.5], [.5,.25], [.5,.75]]) {
          const x = box.left + box.width * fx, y = box.top + box.height * fy;
          if (element.contains(document.elementFromPoint(x, y))) return {x, y};
        }
        return false;
      }
      return {page: location.pathname + location.hash, text: element.innerText.trim()};
    })()
  ''';

  Future<void> _wait(String step, String expression) async {
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 15)) {
      final result = await tab.runtime.evaluate(
        expression,
        returnByValue: true,
      );
      if (result.value case {'x': final num x, 'y': final num y}) {
        for (final type in ['mousePressed', 'mouseReleased']) {
          await tab.sendCommand('Input.dispatchMouseEvent', {
            'type': type,
            'x': x,
            'y': y,
            'button': 'left',
            'buttons': type == 'mousePressed' ? 1 : 0,
            'clickCount': 1,
          });
        }
        return;
      }
      if (result.value == true) return;
      if (result.value case {
        'page': final String page,
        'text': final String text,
      }) {
        run.observations.add({'page': page, 'text': text});
        stdout.writeln('Observed $text');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final state = await tab.runtime.evaluate(
      r"location.href + '\n' + document.body.innerText.slice(-1600)",
      returnByValue: true,
    );
    throw StateError('${run.flow} failed at "$step"\n${state.value}');
  }
}
