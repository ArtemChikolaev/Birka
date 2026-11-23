import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../bin/verify_web.dart' as verifier;

Future<void> main() async {
  final lib = await Isolate.resolvePackageUri(
    Uri.parse('package:birka_tools/check_site.dart'),
  );
  final root = Directory.fromUri(lib!.resolve('../../'));
  final cards = Directory(
    p.join(root.path, '.agents/skills/verify-birka/references'),
  );
  String read(String path) => File(p.join(root.path, path)).readAsStringSync();

  Set<String> flows(String text, String host) => RegExp(
    'make verify-$host FLOW=([a-z0-9-]+)',
  ).allMatches(text).map((match) => match[1]!).toSet();

  String commands(String workflow, String job) {
    final config = loadYaml(read('.github/workflows/$workflow')) as YamlMap;
    final jobs = config['jobs'] as YamlMap;
    final steps = (jobs[job] as YamlMap)['steps'] as YamlList;
    return steps.whereType<YamlMap>().map((step) => step['run']).join('\n');
  }

  final map = File(p.join(cards.path, 'feature-map.md')).readAsStringSync();
  final readme = read('README.md');

  test('every web journey has a map entry, a README command and a CI run', () {
    final registered = verifier.webFlowNames.toSet();
    for (final source in {
      'feature map': map,
      'README': readme,
      'web CI': commands('ci.yml', 'web'),
    }.entries) {
      expect(flows(source.value, 'web'), registered, reason: source.key);
    }
  });

  test('the native journeys in CI match the map and the README', () {
    final native = flows(
      commands('verify-flutter.yml', 'category-limit'),
      'flutter',
    );
    expect(native, isNotEmpty);
    expect(flows(map, 'flutter'), native);
    expect(flows(readme, 'flutter'), native);
  });

  test(
    'journey cards link to existing files and cover the reference folder',
    () {
      final localLink = RegExp(r'\]\(([^)#\s]+)(?:#[^)]*)?\)');
      final mapTargets = localLink
          .allMatches(map)
          .map((match) => match[1])
          .toSet();
      for (final card in cards.listSync().whereType<File>()) {
        if (p.extension(card.path) != '.md') continue;
        final name = p.basename(card.path);
        if (name != 'feature-map.md') expect(mapTargets, contains(name));
        for (final match in localLink.allMatches(card.readAsStringSync())) {
          final target = match[1]!;
          if (Uri.parse(target).hasScheme) continue;
          expect(
            File(p.join(cards.path, target)).existsSync(),
            isTrue,
            reason: '$name links to $target',
          );
        }
      }
    },
  );
}
