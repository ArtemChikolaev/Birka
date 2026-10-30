import 'package:design_tokens/src/generator/emit_css.dart';
import 'package:design_tokens/src/generator/emit_dart.dart';
import 'package:design_tokens/src/generator/parse.dart';
import 'package:test/test.dart';

void main() {
  final tokens = parseTokens({
    'color': {
      r'$type': 'color',
      'accent': {
        r'$description':
            'The color of actions: buttons, links and the selected tab. '
            'Text on it uses onAccent.',
        r'$value': {
          'colorSpace': 'srgb',
          'components': [0.2392, 0.8627, 0.5922],
        },
      },
      'glass': {
        'fillTop': {
          r'$value': {
            'colorSpace': 'srgb',
            'components': [1, 1, 1],
            'alpha': 0.1,
          },
        },
      },
    },
    'radius': {
      'lg': {
        r'$type': 'dimension',
        r'$value': {'value': 22, 'unit': 'px'},
      },
    },
    'duration': {
      'fast': {
        r'$type': 'duration',
        r'$value': {'value': 150, 'unit': 'ms'},
      },
    },
    'easing': {
      'spring': {
        r'$type': 'cubicBezier',
        r'$value': [0.34, 1.56, 0.64, 1],
      },
    },
    'font': {
      'text': {
        r'$type': 'fontFamily',
        r'$value': ['Inter', 'system-ui', 'Open Sans'],
      },
    },
    'shadow': {
      'nav': {
        r'$type': 'shadow',
        r'$value': {
          'color': {
            'colorSpace': 'srgb',
            'components': [0, 0, 0],
            'alpha': 0.55,
          },
          'offsetX': {'value': 0, 'unit': 'px'},
          'offsetY': {'value': 12, 'unit': 'px'},
          'blur': {'value': 32, 'unit': 'px'},
          'spread': {'value': 0, 'unit': 'px'},
        },
      },
    },
    'text': {
      'label': {
        r'$type': 'typography',
        r'$value': {
          'fontFamily': '{font.text}',
          'fontSize': {'value': 12, 'unit': 'px'},
          'fontWeight': 700,
          'letterSpacing': {'value': 0.96, 'unit': 'px'},
          'lineHeight': 1.2,
        },
        r'$extensions': {
          birkaExtension: {'uppercase': true, 'tabular': true},
        },
      },
    },
  });

  test('Dart output declares a constant per token', () {
    final dart = emitDart(tokens);

    expect(dart, contains('static const int colorAccent = 0xFF3DDC97;'));
    expect(dart, contains('static const int colorGlassFillTop = 0x1AFFFFFF;'));
    expect(dart, contains('static const double radiusLg = 22;'));
    expect(dart, contains('static const int durationFastMs = 150;'));
    expect(
      dart,
      contains(
        'static const List<double> easingSpring = [0.34, 1.56, 0.64, 1];',
      ),
    );
    expect(dart, contains("['Inter', 'system-ui', 'Open Sans']"));
    expect(
      dart,
      contains(
        // Wrapped at 80 columns, the line length of the analyzer.
        '  /// The color of actions: buttons, links and the selected tab. '
        'Text on it uses\n'
        '  /// onAccent.\n'
        '  ///\n'
        '  /// `color.accent` as ARGB.\n',
      ),
    );
    expect(dart, contains('uppercase: true, tabular: true)'));
    expect(
      dart,
      contains(
        'static const List<ShadowToken> shadowNav = '
        '[ShadowToken(color: 0x8C000000, offsetX: 0, offsetY: 12, blur: 32, '
        'spread: 0)];',
      ),
    );
  });

  test('CSS output has custom properties and a class per text style', () {
    final css = emitCss(tokens);

    expect(
      css,
      contains(
        '  /* The color of actions: buttons, links and the selected tab. '
        'Text on it uses onAccent. */\n'
        '  --color-accent: #3ddc97;\n',
      ),
    );
    expect(css, contains('--color-glass-fill-top: rgb(255 255 255 / 0.1);'));
    expect(css, contains('--radius-lg: 22px;'));
    expect(css, contains('--duration-fast: 150ms;'));
    expect(
      css,
      contains('--easing-spring: cubic-bezier(0.34, 1.56, 0.64, 1);'),
    );
    expect(css, contains('--font-text: Inter, system-ui, "Open Sans";'));
    expect(css, contains('--shadow-nav: 0px 12px 32px 0px rgb(0 0 0 / 0.55);'));
    expect(css, contains('.text-label {'));
    expect(css, contains('  text-transform: uppercase;'));
    expect(css, contains('  font-variant-numeric: tabular-nums;'));
  });
}
