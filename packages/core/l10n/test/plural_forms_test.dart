@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

/// The plural forms that slang knows.
const _forms = {'zero', 'one', 'two', 'few', 'many', 'other'};

/// Every plural of [file] as its line and its forms with their texts.
Iterable<(int, Map<String, String>)> _plurals(File file) sync* {
  final lines = file.readAsLinesSync();
  for (final (index, line) in lines.indexed) {
    final key = RegExp(r'^(\s*)[^\s:#][^:]*:\s*$').firstMatch(line);
    if (key == null) continue;
    final indent = key.group(1)!.length;
    int? childIndent;
    final forms = <String, String>{};
    for (final next in lines.skip(index + 1)) {
      if (next.trim().isEmpty) continue;
      final nextIndent = next.length - next.trimLeft().length;
      if (nextIndent <= indent) break;
      childIndent ??= nextIndent;
      if (nextIndent != childIndent) continue;
      final form = RegExp(r'^\s*([A-Za-z]+):\s?(.*)$').firstMatch(next);
      if (form != null) forms[form.group(1)!] = form.group(2)!;
    }
    if (forms.isNotEmpty && _forms.containsAll(forms.keys)) {
      yield (index + 1, forms);
    }
  }
}

void main() {
  // slang reads 0 in Russian as `zero ?? other`, and `other` is the form of
  // two to four there: without `zero` a count of none says «0 операции».
  test('every Russian plural says none as it says five', () {
    final files = Directory('lib/i18n').listSync().whereType<File>().where(
      (file) => file.path.endsWith('_ru.i18n.yaml'),
    );
    final wrong = [
      for (final file in files)
        for (final (line, forms) in _plurals(file))
          if (forms.containsKey('many') && forms['zero'] != forms['many'])
            '${file.uri.pathSegments.last}:$line',
    ];
    expect(wrong, isEmpty);
  });
}
