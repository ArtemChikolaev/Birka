import 'dart:io';

import 'package:birka_tools/check_deps.dart';

/// Checks package boundaries of the workspace in the current directory or
/// in the directory given as the only argument.
void main(List<String> args) {
  final root = Directory(args.isEmpty ? '.' : args.single);
  final violations = checkWorkspace(root);
  final onGitHub = Platform.environment['GITHUB_ACTIONS'] == 'true';
  for (final violation in violations) {
    // On GitHub Actions each violation becomes an annotation on the pubspec.
    stderr.writeln(
      onGitHub ? '::error file=${violation.file}::$violation' : '$violation',
    );
  }
  if (violations.isEmpty) {
    stdout.writeln('Package boundaries: OK');
  } else {
    stderr.writeln(
      '${violations.length} boundary violation(s); the rules are in '
      'docs/adr/0001-single-repository.md',
    );
    exitCode = 1;
  }
}
