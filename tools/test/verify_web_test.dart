import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('a mismatched build base is reported before driving the app', () async {
    final work = await Directory.systemTemp.createTemp('birka-base-');
    addTearDown(() => work.delete(recursive: true));
    final site = await Directory(p.join(work.path, 'site')).create();
    await File(
      p.join(site.path, 'index.html'),
    ).writeAsString(
      '<base href="/Birka/"><meta name="birka-build" content="fixture-build">',
    );
    final result = await verify(site, work, '/');
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('built for "/Birka/"'));
    expect(result.stderr, contains('make build-web BASE=/'));
    final runs = Directory(p.join(work.path, 'build', 'verify-web'));
    final run = (await runs.list().toList()).single;
    final json = await File(p.join(run.path, 'report.json')).readAsString();
    final report = jsonDecode(json) as Map<String, Object?>;
    expect(report['status'], 'failed');
    expect(report['buildId'], 'fixture-build');
    expect(report['viewport'], isNull);
    expect(report['error'], contains('built for "/Birka/"'));
    expect(report['observations'], isEmpty);
    expect(File(p.join(run.path, 'failure.png')).existsSync(), isFalse);
  });

  test(
    'each transfer width gets a report even when the build is missing',
    () async {
      final work = await Directory.systemTemp.createTemp('birka-widths-');
      addTearDown(() => work.delete(recursive: true));
      final site = Directory(p.join(work.path, 'missing-site'));
      final runs = Directory(p.join(work.path, 'build', 'verify-web'));
      Future<List<int>> requestedWidths() async {
        final widths = <int>[];
        await for (final dir in runs.list()) {
          final file = File(p.join(dir.path, 'report.json'));
          final report =
              jsonDecode(await file.readAsString()) as Map<String, Object?>;
          widths.add(report['requestedWidth']! as int);
        }
        return widths;
      }

      final both = await verify(site, work, '/', flow: 'currency-transfer');
      expect(both.exitCode, isNot(0));
      expect(await requestedWidths(), unorderedEquals([390, 1440]));
      final one = await verify(
        site,
        work,
        '/',
        flow: 'currency-transfer',
        width: '901',
      );
      expect(one.exitCode, isNot(0));
      expect(await requestedWidths(), unorderedEquals([390, 1440, 901]));
    },
  );

  test(
    'an overlay blocks the restore click and leaves evidence from the tab',
    () async {
      final work = await Directory.systemTemp.createTemp('birka-evidence-');
      addTearDown(() => work.delete(recursive: true));
      final site = Directory(p.join(work.path, 'site'));
      await site.create();
      await File(
        p.join(site.path, 'index.html'),
      ).writeAsString('<base href="/Birka/">');
      for (final name in [
        'main.client.dart.js',
        'drift_worker.dart.js',
        'sqlite3.wasm',
      ]) {
        await File(p.join(site.path, name)).writeAsBytes([0]);
      }
      final data = await File(
        p.join(site.path, 'data', 'index.html'),
      ).create(recursive: true);
      await data.writeAsString('''
        <button onclick="this.textContent = 'Restore clicked'">Restore from a copy</button>
        <div style="position:fixed;inset:0;background:white">Covering panel</div>
      ''');

      final result = await verify(site, work, '/Birka/');
      expect(result.exitCode, isNot(0));
      final runs = Directory(p.join(work.path, 'build', 'verify-web'));
      final run = (await runs.list().toList()).single;
      final json = await File(p.join(run.path, 'report.json')).readAsString();
      final report = jsonDecode(json) as Map<String, Object?>;
      expect(report['status'], 'failed');
      expect(report['buildId'], isNull);
      expect(report['viewport'], {'width': 390, 'height': 844});
      expect(report['error'], contains('click Restore from a copy'));
      expect(report['error'], contains('Covering panel'));
      expect(report['error'], isNot(contains('Restore clicked')));
      final screenshot = File(p.join(run.path, 'failure.png'));
      expect(
        await screenshot.openRead(0, 8).expand((bytes) => bytes).toList(),
        [137, 80, 78, 71, 13, 10, 26, 10],
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<ProcessResult> verify(
  Directory site,
  Directory work,
  String base, {
  String flow = 'category-limit',
  String? width,
}) async {
  final lib = await Isolate.resolvePackageUri(
    Uri.parse('package:birka_tools/check_site.dart'),
  );
  final script = lib!.resolve('../bin/verify_web.dart').toFilePath();
  return Process.run(
    Platform.resolvedExecutable,
    [script, site.path, base, flow, ?width],
    workingDirectory: work.path,
  );
}
