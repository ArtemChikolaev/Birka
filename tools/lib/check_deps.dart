/// Package boundary rules for the Birka workspace, described in ADR 0001 and
/// ADR 0006.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Where a workspace package lives in the architecture.
enum Zone {
  /// An app host in `apps/`.
  host,

  /// A pure-Dart package in `packages/core/` that several features share.
  core,

  /// A design system package in `packages/design/`.
  design,

  /// A feature layer in `packages/features/<feature>/<layer>/`.
  feature,

  /// Repository tooling in `tools/`.
  tooling,
}

/// The UI framework a package is written for.
enum Framework {
  /// Flutter: the mobile host, `flutter/` layers and the catalog.
  flutter('Flutter'),

  /// Jaspr: the web host and `jaspr/` layers.
  jaspr('Jaspr')
  ;

  const Framework(this.label);

  /// How reports name the framework.
  final String label;
}

/// A workspace package, as the boundary rules see it.
final class WorkspacePackage {
  /// Creates a package description; [path] is relative to the workspace
  /// root and uses `/` separators.
  WorkspacePackage({
    required this.name,
    required this.path,
    this.dependencies = const {},
  });

  /// Reads the `pubspec.yaml` of the package at [path] inside [root].
  factory WorkspacePackage.read(Directory root, String path) {
    final file = File(p.join(root.path, path, 'pubspec.yaml'));
    final pubspec = loadYaml(file.readAsStringSync()) as YamlMap;
    final dependencies = <String, Object?>{};
    for (final section in ['dependencies', 'dev_dependencies']) {
      final entries = pubspec[section];
      if (entries is! YamlMap) continue;
      for (final MapEntry(:key, :value) in entries.entries) {
        dependencies[key as String] = value;
      }
    }
    return WorkspacePackage(
      name: pubspec['name'] as String,
      path: p.posix.normalize(path),
      dependencies: dependencies,
    );
  }

  /// The package name from `pubspec.yaml`.
  final String name;

  /// The package directory relative to the workspace root.
  final String path;

  /// Regular and dev dependencies: a name mapped to its pubspec entry,
  /// either a version constraint or a map such as `{path: ../money}`.
  final Map<String, Object?> dependencies;

  List<String> get _segments => path.split('/');

  /// The zone this package belongs to, or `null` if it is in none.
  Zone? get zone => switch (_segments) {
    ['apps', _] => Zone.host,
    ['packages', 'core', _] => Zone.core,
    ['packages', 'design', _] => Zone.design,
    ['packages', 'features', _, _] => Zone.feature,
    ['tools'] => Zone.tooling,
    _ => null,
  };

  /// The feature of a feature layer, for example `budgets`.
  String? get feature => zone == Zone.feature ? _segments[2] : null;

  /// The last directory of [path]: `common`, `flutter`, `jaspr` and so on.
  String get layer => _segments.last;

  /// The UI framework of the package, or `null` for pure Dart and tooling.
  Framework? get framework => switch ((zone, layer)) {
    (Zone.host, 'mobile') => Framework.flutter,
    (Zone.host, 'web') => Framework.jaspr,
    (Zone.feature || Zone.design, 'flutter' || 'catalog') => Framework.flutter,
    (Zone.feature || Zone.design, 'jaspr') => Framework.jaspr,
    _ => null,
  };

  /// Whether the package must not depend on Flutter or Jaspr.
  bool get isPureDart => switch (zone) {
    Zone.core => true,
    Zone.feature || Zone.design => framework == null,
    _ => false,
  };
}

/// A boundary rule broken by one package.
final class Violation {
  /// Creates a violation of [package] described by [message].
  const Violation(this.package, this.message, {String? file}) : _file = file;

  /// The package that breaks the rule.
  final WorkspacePackage package;

  /// What is wrong, phrased to follow the package name.
  final String message;

  /// The file to point at in reports, by default the pubspec.
  String get file => _file ?? '${package.path}/pubspec.yaml';
  final String? _file;

  @override
  String toString() => '${package.name} ($file) $message';
}

/// Reads the workspace at [root] and returns every broken boundary rule.
List<Violation> checkWorkspace(Directory root) {
  final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final members = pubspec['workspace'];
  if (members is! YamlList) return const [];
  final packages = [
    for (final member in members)
      WorkspacePackage.read(root, (member as String).replaceAll(r'\', '/')),
  ];
  return [
    ...checkPackages(packages),
    for (final package in packages)
      if (package.zone == Zone.feature && package.layer == 'common')
        ...checkLayers(root, package),
  ];
}

/// The layers of a `common` package and the layers each may not import:
/// `presentation → domain ← data` (ADR 0006).
const _forbiddenLayers = {
  'domain': {'data', 'presentation', 'di'},
  'presentation': {'data', 'di'},
  'data': {'presentation', 'di'},
};

/// Packages that only `data` and `di` may import.
const _storagePackages = {'database', 'drift'};

final _packageImport = RegExp(
  r"^\s*import\s+'package:([a-z0-9_]+)/([^']*)'",
  multiLine: true,
);

/// Returns the imports in the `common` [package] at [root] that go against
/// the direction of its layers.
List<Violation> checkLayers(Directory root, WorkspacePackage package) {
  final source = Directory(p.join(root.path, package.path, 'lib', 'src'));
  if (!source.existsSync()) return const [];
  final violations = <Violation>[];
  final files = source.listSync(recursive: true).whereType<File>();
  for (final file in files.where((file) => file.path.endsWith('.dart'))) {
    final path = p.relative(file.path, from: source.path);
    final layer = p.split(path).first;
    final forbidden = _forbiddenLayers[layer];
    if (forbidden == null) continue;
    final location = p.posix.joinAll([
      ...p.split(package.path),
      'lib',
      'src',
      ...p.split(path),
    ]);
    for (final match in _packageImport.allMatches(file.readAsStringSync())) {
      final imported = match[1]!;
      final target = p.posix.split(match[2]!);
      final importsForbiddenLayer =
          imported == package.name &&
          target.length > 2 &&
          target[0] == 'src' &&
          forbidden.contains(target[1]);
      if (importsForbiddenLayer) {
        violations.add(
          Violation(
            package,
            'has $layer code that imports its ${target[1]} layer: $location',
            file: location,
          ),
        );
      } else if (layer != 'data' && _storagePackages.contains(imported)) {
        violations.add(
          Violation(
            package,
            'has $layer code that imports package:$imported: $location',
            file: location,
          ),
        );
      }
    }
  }
  return violations;
}

/// Returns every broken boundary rule among [packages].
List<Violation> checkPackages(List<WorkspacePackage> packages) {
  final byName = {for (final package in packages) package.name: package};
  final violations = <Violation>[];
  for (final package in packages) {
    void report(String message) => violations.add(Violation(package, message));

    final zone = package.zone;
    if (zone == null) {
      report(
        'is outside the known zones: apps/, packages/core/, '
        'packages/design/, packages/features/, tools/',
      );
      continue;
    }
    final framework = package.framework;
    for (final MapEntry(key: name, value: spec)
        in package.dependencies.entries) {
      if ((_isFlutter(name) || _isJaspr(name)) && package.isPureDart) {
        report('is pure Dart but depends on $name');
      }
      if (_isFlutter(name) && framework == Framework.jaspr) {
        report('is a Jaspr package but depends on $name');
      }
      if (_isJaspr(name) && framework == Framework.flutter) {
        report('is a Flutter package but depends on $name');
      }

      final target = byName[name];
      if (target == null) continue;
      if (spec is! Map || !spec.containsKey('path')) {
        report('must depend on $name through `path:`');
      }
      final targetFramework = target.framework;
      if (targetFramework != null && package.isPureDart) {
        report('is pure Dart but depends on $name');
      }
      if (targetFramework != null &&
          framework != null &&
          targetFramework != framework) {
        report(
          'is a ${framework.label} package but depends on the '
          '${targetFramework.label} package $name',
        );
      }
      final targetZone = target.zone;
      if (targetZone == Zone.host) {
        report('depends on the app host $name');
      }
      if (zone == Zone.core &&
          (targetZone == Zone.feature || targetZone == Zone.design)) {
        report('is a core package but depends on $name');
      }
      if (zone == Zone.design && targetZone != Zone.design) {
        report('is part of the design system but depends on $name');
      }
      if (zone == Zone.feature &&
          targetZone == Zone.feature &&
          target.feature != package.feature) {
        report('depends on another feature: $name');
      }
    }
  }
  return violations;
}

bool _isFlutter(String name) =>
    name == 'flutter' || name.startsWith('flutter_');

bool _isJaspr(String name) => name == 'jaspr' || name.startsWith('jaspr_');
