import 'dart:convert';
import 'dart:io';

import 'package:birka_tools/check_site.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

/// Exercises a named flow on a static build served under its real base path.
Future<void> main(List<String> args) async {
  if (args.length != 3 || args.last != 'category-limit') {
    stderr.writeln('Usage: make verify-web FLOW=category-limit');
    exitCode = 64;
    return;
  }
  final [path, base, _] = args;
  if (!File('$path/index.html').existsSync()) {
    stderr.writeln('Build the site first with make build-web BASE=$base');
    exitCode = 1;
    return;
  }
  final server = await serveSite(Directory(path), base: base);
  try {
    final origin = Uri.parse('http://localhost:${server.port}$base');
    await withSiteTab((tab) => _CategoryLimit(tab, origin).run());
  } finally {
    await server.close(force: true);
  }
}

final class _CategoryLimit {
  _CategoryLimit(this.tab, this.origin);

  final WipConnection tab;
  final Uri origin;
  static const note = 'a[href="limits/#cafe"] .limit-note';

  Future<void> run() async {
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
    await _open('data/');
    await tab.page.sendCommand(
      'Page.setInterceptFileChooserDialog',
      params: {'enabled': true},
    );
    await _click('button', 'Restore from a copy');
    await _wait(
      'restore file chooser',
      "!!document.querySelector('input[type=file]')",
    );
    final input = await tab.runtime.evaluate(
      "document.querySelector('input[type=file]')",
    );
    await tab.dom.sendCommand(
      'DOM.setFileInputFiles',
      params: {
        'objectId': input.objectId,
        'files': [File('tools/fixtures/category-limit.json').absolute.path],
      },
    );
    await _click('button', 'Replace the records');
    await _wait(
      'restored synthetic ledger',
      "document.body.innerText.includes('Records restored from the copy')",
    );
    await _open('overview/');
    await _click('a[href="limits/"]', 'All limits · 1');
    await _expect(note, '₽1,850 left');

    await _spend('1850', 'Cafe: ₽0 of ₽12,000 left');
    await _open('limits/');
    await _expect(note, '₽0 left');

    await _spend('1', 'Cafe: ₽1 over the limit');
    await _open('limits/');
    await _expect(note, '₽1 over the limit');
    // Wait for a new document so the existing row cannot satisfy the reload.
    await tab.runtime.evaluate('window.beforeLimitReload = true');
    await tab.page.reload(ignoreCache: true);
    await _wait(
      'new document after reload',
      'window.beforeLimitReload !== true',
    );
    await _expect(note, '₽1 over the limit');
    stdout.writeln('category-limit: persisted ₽1 over the limit after reload');
  }

  Future<void> _open(String page) async {
    await tab.page.navigate(origin.resolve(page).toString());
  }

  Future<void> _spend(String amount, String preview) async {
    await _open('operations/');
    await _click('a[href="operations/#new"]');
    await _click('.quick-add button', 'Cafe');
    for (final digit in amount.split('')) {
      await _click('.quick-add button', digit);
    }
    await _expect('.quick-add__limit', preview);
    await _click('.quick-add button', 'Save · Cafe');
    await _wait(
      'saved expense of ₽$amount',
      "location.hash === '' && !document.querySelector('.quick-add')",
    );
  }

  Future<void> _expect(String selector, String text) async {
    await _wait(text, _element(selector, text, click: false));
    stdout.writeln('Observed $text');
  }

  Future<void> _click(String selector, [String? text]) =>
      _wait('click ${text ?? selector}', _element(selector, text, click: true));

  String _element(String selector, String? text, {required bool click}) =>
      '''
    (() => {
      const element = Array.from(document.querySelectorAll(${jsonEncode(selector)}))
        .find(e => e.checkVisibility() && !e.disabled &&
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
    throw StateError('category-limit failed at "$step"\n${state.value}');
  }
}
