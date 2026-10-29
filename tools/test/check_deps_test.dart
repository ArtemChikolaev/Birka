import 'dart:io';

import 'package:birka_tools/check_deps.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const flutterSdk = {'sdk': 'flutter'};

Map<String, String> local(String path) => {'path': path};

WorkspacePackage package(
  String path,
  String name, [
  Map<String, Object?> dependencies = const {},
]) => WorkspacePackage(name: name, path: path, dependencies: dependencies);

List<String> check(List<WorkspacePackage> packages) => [
  for (final violation in checkPackages(packages)) violation.message,
];

void main() {
  final money = package('packages/money', 'money', {'meta': '^1.17.0'});

  test('a workspace that follows the rules has no violations', () {
    final packages = [
      money,
      package('packages/domain', 'domain', {'money': local('../money')}),
      package('packages/design/tokens', 'design_tokens'),
      package('packages/design/flutter', 'design_flutter', {
        'flutter': flutterSdk,
        'design_tokens': local('../tokens'),
      }),
      package('packages/features/budgets/common', 'budgets_common', {
        'domain': local('../../../domain'),
        'bloc': '^9.2.1',
      }),
      package('packages/features/budgets/flutter', 'budgets_flutter', {
        'budgets_common': local('../common'),
        'design_flutter': local('../../../design/flutter'),
        'flutter_bloc': '^9.1.1',
      }),
      package('packages/features/budgets/web', 'budgets_web', {
        'budgets_common': local('../common'),
        'jaspr_bloc': '^1.0.1',
      }),
      package('apps/mobile', 'birka_mobile', {
        'flutter': flutterSdk,
        'budgets_flutter': local('../../packages/features/budgets/flutter'),
      }),
      package('apps/web', 'birka_web', {'jaspr': '^0.22.3'}),
      package('tools', 'birka_tools', {'yaml': '^3.1.3'}),
    ];

    expect(check(packages), isEmpty);
  });

  test('core, common and token packages stay pure Dart', () {
    expect(
      check([
        package('packages/money', 'money', {'flutter': flutterSdk}),
        package('packages/features/a/common', 'a_common', {'jaspr': '^0.22.3'}),
        package('packages/design/tokens', 'design_tokens', {
          'flutter_test': flutterSdk,
        }),
      ]),
      [
        'is pure Dart but depends on flutter',
        'is pure Dart but depends on jaspr',
        'is pure Dart but depends on flutter_test',
      ],
    );
  });

  test('web packages avoid Flutter and Flutter packages avoid Jaspr', () {
    expect(
      check([
        package('packages/features/a/web', 'a_web', {'flutter_bloc': '^9.1.1'}),
        package('packages/design/flutter', 'design_flutter', {
          'jaspr': '^0.22.3',
        }),
        package('apps/web', 'birka_web', {'flutter': flutterSdk}),
      ]),
      [
        'is a web package but depends on flutter_bloc',
        'is a Flutter package but depends on jaspr',
        'is a web package but depends on flutter',
      ],
    );
  });

  test('a feature does not depend on another feature', () {
    expect(
      check([
        package('packages/features/a/common', 'a_common'),
        package('packages/features/b/common', 'b_common', {
          'a_common': local('../../a/common'),
        }),
      ]),
      ['depends on another feature: a_common'],
    );
  });

  test('the design system knows nothing about the core or features', () {
    expect(
      check([
        money,
        package('packages/design/flutter', 'design_flutter', {
          'money': local('../../money'),
        }),
      ]),
      ['is part of the design system but depends on money'],
    );
  });

  test('the core does not depend on features or the design system', () {
    expect(
      check([
        package('packages/design/tokens', 'design_tokens'),
        package('packages/domain', 'domain', {
          'design_tokens': local('../design/tokens'),
        }),
      ]),
      ['is a core package but depends on design_tokens'],
    );
  });

  test('nothing depends on an app host', () {
    expect(
      check([
        package('apps/mobile', 'birka_mobile'),
        package('packages/domain', 'domain', {
          'birka_mobile': local('../../apps/mobile'),
        }),
      ]),
      ['depends on the app host birka_mobile'],
    );
  });

  test('workspace dependencies go through path:', () {
    expect(
      check([
        money,
        package('packages/domain', 'domain', {'money': 'any'}),
      ]),
      ['must depend on money through `path:`'],
    );
  });

  test('a package outside the zones is reported', () {
    expect(
      check([package('lib/misc', 'misc')]),
      ['is outside the known zones: apps/, packages/, tools/'],
    );
  });

  test('reads the workspace from disk', () {
    final root = Directory.systemTemp.createTempSync('check_deps_');
    addTearDown(() => root.deleteSync(recursive: true));
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: workspace
workspace:
  - packages/money
''');
    final moneyDir = Directory(p.join(root.path, 'packages', 'money'))
      ..createSync(recursive: true);
    File(p.join(moneyDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: money
dependencies:
  meta: ^1.17.0
dev_dependencies:
  flutter_test:
    sdk: flutter
''');

    final violations = checkWorkspace(root);

    const expected =
        'money (packages/money/pubspec.yaml) '
        'is pure Dart but depends on flutter_test';
    expect(violations.map((violation) => violation.toString()), [expected]);
  });
}
