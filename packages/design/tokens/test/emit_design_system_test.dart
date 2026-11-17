import 'dart:convert';
import 'dart:io';

import 'package:design_tokens/src/generator/design_token.dart';
import 'package:design_tokens/src/generator/emit_design_system.dart';
import 'package:design_tokens/src/generator/generator.dart';
import 'package:design_tokens/src/generator/parse.dart';
import 'package:test/test.dart';

void main() {
  final tokens = parseTokens(readTokenDocument(Directory.current));
  final system = jsonDecode(emitDesignSystem(tokens)) as Map<String, Object?>;

  List<Map<String, Object?>> family(String name) => [
    for (final token in (system[name]! as Map)['tokens'] as List)
      token as Map<String, Object?>,
  ];

  test('every token of every family has a name, a value and a note', () {
    for (final name in ['color', 'spacing', 'radius', 'shadow', 'duration']) {
      for (final token in family(name)) {
        expect(token['name'], isA<String>());
        expect(token['value'], isNotNull, reason: '${token['name']}');
        expect(token['usage'], isNotEmpty, reason: '${token['name']}');
      }
    }
  });

  test('colors are hex, with the alpha when they are see-through', () {
    final colors = {
      for (final token in family('color')) token['name']: token['value'],
    };

    expect(colors['color-accent'], '#3ddc97');
    expect(colors['color-hairline'], '#ffffff17');
    expect((system['color']! as Map)['themes'], [
      {'id': 'dark', 'name': 'Dark'},
    ]);
  });

  test('type styles are named like the classes of the CSS', () {
    final type = system['type']! as Map<String, Object?>;
    final styles = [
      for (final group in type['groups']! as List)
        for (final style in (group as Map)['styles'] as List) style as Map,
    ];

    expect(styles.map((style) => style['name']), contains('text-label'));
    expect(
      styles.firstWhere((style) => style['name'] == 'text-display'),
      containsPair('fontSize', '46px'),
    );
    expect(type['families'], containsPair('display', startsWith('Manrope')));
  });

  test('a token without a note is refused', () {
    final bare = parseTokens({
      'color': {
        'mystery': {
          r'$type': 'color',
          r'$value': {
            'colorSpace': 'srgb',
            'components': [1, 0, 0],
          },
        },
      },
    });

    expect(
      () => emitDesignSystem(bare),
      throwsA(isA<TokenFormatException>()),
    );
  });
}
