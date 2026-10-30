import 'dart:convert';
import 'dart:io';

import 'package:design_tokens/src/generator/design_token.dart';
import 'package:design_tokens/src/generator/emit_css.dart';
import 'package:design_tokens/src/generator/emit_dart.dart';
import 'package:design_tokens/src/generator/parse.dart';
import 'package:path/path.dart' as p;

/// Where the Dart constants go, relative to the package root.
const dartOutput = 'lib/src/tokens.g.dart';

/// Where the CSS goes, relative to the package root.
const cssOutput = 'lib/css/tokens.css';

/// Reads every `tokens/*.tokens.json` under the package [root] into one
/// document. A top-level group may live in one file only.
Map<String, Object?> readTokenDocument(Directory root) {
  final files =
      Directory(p.join(root.path, 'tokens'))
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.tokens.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final document = <String, Object?>{};
  for (final file in files) {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map<String, Object?>) {
      throw TokenFormatException('${p.basename(file.path)} is not an object');
    }
    for (final MapEntry(:key, :value) in json.entries) {
      if (document.containsKey(key)) {
        throw TokenFormatException('group $key is in more than one file');
      }
      document[key] = value;
    }
  }
  return document;
}

/// Generates the Dart and CSS outputs from the token files under [root].
///
/// Writes them, or with [check] writes nothing and returns the outputs that
/// are out of date.
Future<List<String>> generate(Directory root, {bool check = false}) async {
  final tokens = parseTokens(readTokenDocument(root));
  final outputs = {
    dartOutput: await formatDart(emitDart(tokens)),
    cssOutput: emitCss(tokens),
  };
  final stale = <String>[];
  for (final MapEntry(key: path, value: content) in outputs.entries) {
    final file = File(p.join(root.path, path));
    if (!check) {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    } else if (!file.existsSync() || file.readAsStringSync() != content) {
      stale.add(path);
    }
  }
  return stale;
}

/// Formats Dart [source] with `dart format`, the way the analyze step
/// expects it.
Future<String> formatDart(String source) async {
  final directory = Directory.systemTemp.createTempSync('design_tokens_');
  try {
    final file = File(p.join(directory.path, 'tokens.g.dart'))
      ..writeAsStringSync(source);
    final result = await Process.run(Platform.resolvedExecutable, [
      'format',
      file.path,
    ]);
    if (result.exitCode != 0) {
      throw ProcessException(
        Platform.resolvedExecutable,
        ['format'],
        '${result.stderr}',
        result.exitCode,
      );
    }
    return file.readAsStringSync();
  } finally {
    directory.deleteSync(recursive: true);
  }
}
