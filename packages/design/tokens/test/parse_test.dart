import 'package:design_tokens/src/generator/design_token.dart';
import 'package:design_tokens/src/generator/parse.dart';
import 'package:test/test.dart';

Map<String, Object?> srgb(
  List<num> components, {
  num alpha = 1,
  String? hex,
}) => {
  'colorSpace': 'srgb',
  'components': components,
  'alpha': alpha,
  'hex': ?hex,
};

Object valueOf(Map<String, Object?> document, String name) =>
    parseTokens(document).singleWhere((token) => token.name == name).value;

Matcher throwsFormat(String fragment) => throwsA(
  isA<TokenFormatException>().having(
    (e) => e.message,
    'message',
    contains(fragment),
  ),
);

void main() {
  group('color', () {
    test('becomes an ARGB value', () {
      final document = {
        'color': {
          r'$type': 'color',
          'accent': {
            r'$value': srgb([0.2392, 0.8627, 0.5922], hex: '#3ddc97'),
          },
        },
      };

      expect(valueOf(document, 'color.accent'), 0xFF3DDC97);
    });

    test('alpha becomes the alpha channel', () {
      final document = {
        'soft': {
          r'$type': 'color',
          r'$value': srgb([1, 1, 1], alpha: 0.14),
        },
      };

      expect(valueOf(document, 'soft'), 0x24FFFFFF);
    });

    test('a hex that disagrees with the components is rejected', () {
      final document = {
        'wrong': {
          r'$type': 'color',
          r'$value': srgb([1, 1, 1], hex: '#000000'),
        },
      };

      expect(() => parseTokens(document), throwsFormat('does not match'));
    });

    test('only sRGB is supported', () {
      final document = {
        'p3': {
          r'$type': 'color',
          r'$value': {
            'colorSpace': 'display-p3',
            'components': [1, 0, 0],
          },
        },
      };

      expect(() => parseTokens(document), throwsFormat('srgb'));
    });
  });

  group('structure', () {
    test(r'a token inherits $type from its groups', () {
      final document = {
        'space': {
          r'$type': 'dimension',
          'inner': {
            'md': {
              r'$value': {'value': 16, 'unit': 'px'},
            },
          },
        },
      };

      expect(valueOf(document, 'space.inner.md'), 16);
    });

    test(r'a token without a $type is rejected', () {
      final document = {
        'loose': {r'$value': 1},
      };

      expect(() => parseTokens(document), throwsFormat('no'));
    });

    test('a description must be a string', () {
      final document = {
        'n': {r'$type': 'number', r'$value': 1, r'$description': 2},
      };

      expect(() => parseTokens(document), throwsFormat('description'));
    });

    test('aliases resolve through a chain', () {
      final document = {
        'radius': {
          r'$type': 'dimension',
          'base': {
            r'$value': {'value': 12, 'unit': 'px'},
          },
          'card': {r'$value': '{radius.base}'},
          'sheet': {r'$value': '{radius.card}'},
        },
      };

      expect(valueOf(document, 'radius.sheet'), 12);
    });

    test('an alias cycle is reported', () {
      final document = {
        'a': {r'$type': 'number', r'$value': '{b}'},
        'b': {r'$type': 'number', r'$value': '{a}'},
      };

      expect(() => parseTokens(document), throwsFormat('alias cycle'));
    });

    test('an alias to an unknown token is reported', () {
      final document = {
        'a': {r'$type': 'number', r'$value': '{missing}'},
      };

      expect(() => parseTokens(document), throwsFormat('unknown missing'));
    });
  });

  group('units', () {
    test('rem becomes pixels', () {
      final document = {
        'gap': {
          r'$type': 'dimension',
          r'$value': {'value': 1.5, 'unit': 'rem'},
        },
      };

      expect(valueOf(document, 'gap'), 24);
    });

    test('seconds become milliseconds', () {
      final document = {
        'slow': {
          r'$type': 'duration',
          r'$value': {'value': 0.5, 'unit': 's'},
        },
      };

      expect(valueOf(document, 'slow'), 500);
    });

    test('font weights accept keywords', () {
      final document = {
        'w': {r'$type': 'fontWeight', r'$value': 'semi-bold'},
      };

      expect(valueOf(document, 'w'), 600);
    });

    test('a cubic bezier keeps x within 0 and 1', () {
      final document = {
        'e': {
          r'$type': 'cubicBezier',
          r'$value': [1.2, 0, 0, 1],
        },
      };

      expect(() => parseTokens(document), throwsFormat('x in 0..1'));
    });
  });

  group('shadow', () {
    Map<String, Object?> layer({Object? inset}) => {
      'color': srgb([0, 0, 0], alpha: 0.4),
      'offsetX': {'value': 0, 'unit': 'px'},
      'offsetY': {'value': 10, 'unit': 'px'},
      'blur': {'value': 28, 'unit': 'px'},
      'spread': {'value': 0, 'unit': 'px'},
      'inset': ?inset,
    };

    test('becomes a list of layers from one object or a list', () {
      final one = valueOf({
        's': {r'$type': 'shadow', r'$value': layer()},
      }, 's');
      final two = valueOf({
        's': {
          r'$type': 'shadow',
          r'$value': [layer(), layer()],
        },
      }, 's');

      expect((one as List<ShadowValue>).single.offsetY, 10);
      expect(one.single.blur, 28);
      expect(one.single.color, 0x66000000);
      expect(two as List<ShadowValue>, hasLength(2));
    });

    test('resolves an alias to a color', () {
      final value = valueOf({
        'black': {
          r'$type': 'color',
          r'$value': srgb([0, 0, 0]),
        },
        's': {
          r'$type': 'shadow',
          r'$value': {...layer(), 'color': '{black}'},
        },
      }, 's');

      expect((value as List<ShadowValue>).single.color, 0xFF000000);
    });

    test('inset layers are rejected', () {
      final document = {
        's': {r'$type': 'shadow', r'$value': layer(inset: true)},
      };

      expect(() => parseTokens(document), throwsFormat('inset'));
    });
  });

  test('typography resolves its aliases and keeps extensions', () {
    final document = {
      'font': {
        'display': {
          r'$type': 'fontFamily',
          r'$value': ['Manrope', 'sans-serif'],
        },
      },
      'text': {
        'label': {
          r'$type': 'typography',
          r'$value': {
            'fontFamily': '{font.display}',
            'fontSize': {'value': 12, 'unit': 'px'},
            'fontWeight': 700,
            'letterSpacing': {'value': 0.96, 'unit': 'px'},
            'lineHeight': 1.2,
          },
          r'$extensions': {
            birkaExtension: {'uppercase': true},
          },
        },
      },
    };

    final token = parseTokens(document).last;
    final text = token.value as TypographyValue;

    expect(text.families, ['Manrope', 'sans-serif']);
    expect(text.size, 12);
    expect(text.weight, 700);
    expect(text.letterSpacing, 0.96);
    expect(text.lineHeight, 1.2);
    expect(token.extensions, {'uppercase': true});
  });
}
