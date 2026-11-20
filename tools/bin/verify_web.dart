import 'dart:convert';
import 'dart:io';

import 'package:birka_tools/check_site.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// Exercises a named flow on a static build served under its real base path.
Future<void> main(List<String> args) async {
  const flows = {
    'category-limit': _categoryLimit,
    'backup-roundtrip': _backupRoundtrip,
  };
  if (args.length != 3 || !flows.containsKey(args.last)) {
    stderr.writeln('Usage: make verify-web FLOW=<${flows.keys.join('|')}>');
    exitCode = 64;
    return;
  }
  final [path, base, flow] = args;
  if (!File('$path/index.html').existsSync()) {
    stderr.writeln('Build the site first with make build-web BASE=$base');
    exitCode = 1;
    return;
  }
  final server = await serveSite(Directory(path), base: base);
  try {
    final origin = Uri.parse('http://localhost:${server.port}$base');
    await flows[flow]!(origin);
  } finally {
    await server.close(force: true);
  }
}

const _limitNote = 'a[href="limits/#cafe"] .limit-note';
final _fixture = File('tools/fixtures/category-limit.json');

Future<void> _categoryLimit(Uri origin) => _visit(origin, 'category-limit', (
  browser,
) async {
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

Future<void> _backupRoundtrip(Uri origin) async {
  const flow = 'backup-roundtrip';
  final downloads = await Directory.systemTemp.createTemp('birka-backup-');
  try {
    final copy = await _visit(origin, flow, (browser) async {
      await browser.restore(_fixture);
      await browser.spend('150', 'Cafe: ₽1,700 of ₽12,000 left');
      return browser.saveCopy(downloads);
    });
    // Start another Chrome only after the source browser and its profile close.
    await _visit(origin, flow, (browser) async {
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

Future<T> _visit<T>(
  Uri origin,
  String flow,
  Future<T> Function(_Browser) visit,
) => withSiteTab((tab) async {
  final browser = _Browser(tab, origin, flow);
  await browser.prepare();
  return visit(browser);
});

final class _Browser {
  _Browser(this.tab, this.origin, this.flow);

  final WipConnection tab;
  final Uri origin;
  final String flow;

  Future<void> prepare() async {
    await tab.page.enable();
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
    throw StateError('$flow: no .birka download after saving the copy');
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
    await tab.page.navigate(origin.resolve(page).toString());
  }

  Future<void> spend(String amount, String preview) async {
    await open('operations/');
    await click('a[href="operations/#new"]');
    await click('.quick-add button', 'Cafe');
    for (final digit in amount.split('')) {
      await click('.quick-add button', digit);
    }
    await expect('.quick-add__limit', preview);
    await click('.quick-add button', 'Save · Cafe');
    await _wait(
      'saved expense of ₽$amount',
      "location.hash === '' && !document.querySelector('.quick-add')",
    );
  }

  Future<void> expect(String selector, String text) async {
    await _wait(text, _element(selector, text, click: false));
    stdout.writeln('Observed $text');
  }

  Future<void> click(String selector, [String? text]) =>
      _wait('click ${text ?? selector}', _element(selector, text, click: true));

  String _element(String selector, String? text, {required bool click}) =>
      '''
    (() => {
      const element = Array.from(document.querySelectorAll(${jsonEncode(selector)}))
        .find(e => e.checkVisibility() && (${!click} || !e.disabled) &&
          (${text == null} || e.innerText.trim().toLowerCase() === ${jsonEncode(text?.toLowerCase())}));
      if (!element) return false;
      ${click ? 'element.click();' : ''}
      return true;
    })()
  ''';

  Future<void> _wait(String step, String expression) async {
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 15)) {
      final result = await tab.runtime.evaluate(
        expression,
        returnByValue: true,
      );
      if (result.value == true) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final state = await tab.runtime.evaluate(
      r"location.href + '\n' + document.body.innerText.slice(-1600)",
      returnByValue: true,
    );
    throw StateError('$flow failed at "$step"\n${state.value}');
  }
}
