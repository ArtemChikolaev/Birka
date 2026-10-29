/// Package boundary rules for the Birka workspace, described in ADR 0001.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Where a workspace package lives in the architecture.
enum Zone {
  /// An app host in `apps/`.
  host,

  /// A pure-Dart core package directly in `packages/`.
  core,

  /// A design system package in `packages/design/`.
  design,

  /// A feature layer in `packages/features/<feature>/<layer>/`.
  feature,

  /// Repository tooling in `tools/`.
  tooling,
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
    ['packages', 'design', _] => Zone.design,
    ['packages', 'features', _, _] => Zone.feature,
    ['packages', _] => Zone.core,
    ['tools'] => Zone.tooling,
    _ => null,
  };

  /// The feature of a feature layer, for example `budgets`.
  String? get feature => zone == Zone.feature ? _segments[2] : null;

  /// The last directory of [path]: `common`, `flutter`, `web` and so on.
  String get layer => _segments.last;

  /// Whether the package must not depend on Flutter or Jaspr.
  bool get isPureDart => switch (zone) {
    Zone.core => true,
    Zone.feature => layer == 'common',
    Zone.design => !const {'flutter', 'web', 'catalog'}.contains(layer),
    _ => false,
  };
}

/// A boundary rule broken by one package.
final class Violation {
  /// Creates a violation of [package] described by [message].
  const Violation(this.package, this.message);

  /// The package that breaks the rule.
  final WorkspacePackage package;

  /// What is wrong, phrased to follow the package name.
  final String message;

  /// The pubspec to point at in reports.
  String get file => '${package.path}/pubspec.yaml';

  @override
  String toString() => '${package.name} ($file) $message';
}

/// Reads the workspace at [root] and returns every broken boundary rule.
List<Violation> checkWorkspace(Directory root) {
  final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final members = pubspec['workspace'];
  if (members is! YamlList) return const [];
  return checkPackages([
    for (final member in members)
      WorkspacePackage.read(root, (member as String).replaceAll(r'\', '/')),
  ]);
}

/// Returns every broken boundary rule among [packages].
List<Violation> checkPackages(List<WorkspacePackage> packages) {
  final byName = {for (final package in packages) package.name: package};
  final violations = <Violation>[];
  for (final package in packages) {
    void report(String message) => violations.add(Violation(package, message));

    final zone = package.zone;
    if (zone == null) {
      report('is outside the known zones: apps/, packages/, tools/');
      continue;
    }
    for (final MapEntry(key: name, value: spec)
        in package.dependencies.entries) {
      if (_isFlutter(name) && package.isPureDart) {
        report('is pure Dart but depends on $name');
      }
      if (_isJaspr(name) && package.isPureDart) {
        report('is pure Dart but depends on $name');
      }
      if (_isFlutter(name) && package.layer == 'web') {
        report('is a web package but depends on $name');
      }
      if (_isJaspr(name) && package.layer == 'flutter') {
        report('is a Flutter package but depends on $name');
      }

      final target = byName[name];
      if (target == null) continue;
      if (spec is! Map || !spec.containsKey('path')) {
        report('must depend on $name through `path:`');
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
