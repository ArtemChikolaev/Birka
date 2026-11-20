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
    ).writeAsString('<base href="/Birka/">');
    final result = await verify(site, work, '/');
    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('built for "/Birka/"'));
    expect(result.stderr, contains('make build-web BASE=/'));
    final runs = Directory(p.join(work.path, 'build', 'verify-web'));
    final run = (await runs.list().toList()).single;
    final json = await File(p.join(run.path, 'report.json')).readAsString();
    final report = jsonDecode(json) as Map<String, Object?>;
    expect(report['status'], 'failed');
    expect(report['error'], contains('built for "/Birka/"'));
    expect(report['observations'], isEmpty);
    expect(File(p.join(run.path, 'failure.png')).existsSync(), isFalse);
  });

  test(
    'a failed journey leaves its report and screenshot before Chrome closes',
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
      await data.writeAsString('<h1>Restore button is missing</h1>');

      final result = await verify(site, work, '/Birka/');
      expect(result.exitCode, isNot(0));
      final runs = Directory(p.join(work.path, 'build', 'verify-web'));
      final run = (await runs.list().toList()).single;
      final json = await File(p.join(run.path, 'report.json')).readAsString();
      final report = jsonDecode(json) as Map<String, Object?>;
      expect(report['status'], 'failed');
      expect(report['error'], contains('click Restore from a copy'));
      expect(report['error'], contains('Restore button is missing'));
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
  String base,
) async {
  final lib = await Isolate.resolvePackageUri(
    Uri.parse('package:birka_tools/check_site.dart'),
  );
  final script = lib!.resolve('../bin/verify_web.dart').toFilePath();
  return Process.run(
    Platform.resolvedExecutable,
    [script, site.path, base, 'category-limit'],
    workingDirectory: work.path,
  );
}
