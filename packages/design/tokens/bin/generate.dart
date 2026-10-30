import 'dart:io';
import 'dart:isolate';

import 'package:design_tokens/src/generator/generator.dart';

/// Regenerates the Dart constants and the CSS from `tokens/*.tokens.json`.
///
/// With `--check`, writes nothing and fails when an output is out of date.
Future<void> main(List<String> args) async {
  final check = args.contains('--check');
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:design_tokens/design_tokens.dart'),
  );
  if (library == null) {
    stderr.writeln('Cannot find the design_tokens package.');
    exitCode = 2;
    return;
  }
  final stale = await generate(
    Directory.fromUri(library.resolve('..')),
    check: check,
  );
  if (!check) {
    stdout.writeln('Generated $dartOutput and $cssOutput.');
  } else if (stale.isEmpty) {
    stdout.writeln('Design tokens are up to date.');
  } else {
    stderr.writeln('Out of date: ${stale.join(', ')}. Run `make tokens`.');
    exitCode = 1;
  }
}
