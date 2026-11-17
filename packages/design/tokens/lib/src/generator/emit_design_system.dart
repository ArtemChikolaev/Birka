import 'dart:convert';

import 'package:design_tokens/src/generator/design_token.dart';
import 'package:design_tokens/src/generator/emit_css.dart';
import 'package:design_tokens/src/generator/emit_dart.dart';

/// The font files of the web kit that the design system carries, with the
/// family and the weights each one holds.
const _fonts = [
  ('Inter', 'Inter-latin.woff2', '100 900'),
  ('Inter', 'Inter-cyrillic.woff2', '100 900'),
  ('Manrope', 'Manrope-latin.woff2', '200 800'),
  ('Manrope', 'Manrope-cyrillic.woff2', '200 800'),
];

/// Where each token is used, for a token without a `$description`. Every
/// token needs a note: one or the other.
const _usage = {
  'color-background': 'The base of every screen, under the ambient glow.',
  'color-surface':
      'Fields, the track of a segmented switch and solid cards on the '
      'background.',
  'color-surface-raised':
      'Chips, quiet buttons and the empty track of a meter, one step above '
      'the surface.',
  'color-surface-selected':
      'The picked option of a segmented switch and a switch that is off.',
  'color-text':
      'Titles, amounts and body text on the background, the surfaces and '
      'glass; the fill of a selected chip.',
  'color-text-secondary':
      'Supporting text: chips, figures beside a name, the text of a notice.',
  'color-text-muted': 'Section labels, captions and the quiet notes of a row.',
  'color-text-subtle':
      'Hints, placeholders and unselected options; the dashed border of an '
      'empty chip. Never for text that must be read.',
  'color-accent':
      'Emerald, for accents only: the main button, the selected tab, links, '
      'income and progress that is fine.',
  'color-on-accent': 'Text and icons on color-accent, such as the main button.',
  'color-accent-highlight':
      'The light line along the top edge of the main button.',
  'color-accent-soft':
      'A tint of the accent behind a positive pill or a selected glyph.',
  'color-positive':
      'Money in and changes for the better: income, a rise of the capital.',
  'color-negative':
      'Money out over plan and changes for the worse: a fall, a limit that '
      'is over, deleting.',
  'color-hairline': 'Rules between rows and the border of segmented switches.',
  'color-glass-fill-top': 'The top of the gradient fill of glass.',
  'color-glass-fill-bottom': 'The bottom of the gradient fill of glass.',
  'color-glass-border': 'The hairline border of glass.',
  'color-glass-highlight': 'The light line along the top edge of glass.',
  'color-nav-fill': 'The fill of the floating tab bar.',
  'color-nav-highlight': 'The light top edge of the tab bar.',
  'color-nav-lowlight': 'The faint bottom edge of the tab bar.',
  'color-nav-bubble': 'The bubble under the selected tab.',
  'color-nav-bubble-highlight': 'The light top edge of the bubble.',
  'color-nav-label': 'The labels of tabs that are not selected.',
  'blur-control': 'The backdrop blur of small glass controls.',
  'blur-glass': 'The backdrop blur of glass cards and panels.',
  'blur-nav': 'The backdrop blur of the tab bar.',
  'saturation-glass':
      'How much glass boosts the colors behind it: 1.6 is 160 %.',
  'saturation-nav': 'How much the tab bar boosts the colors behind it.',
  'shadow-glass': 'Under glass cards and panels.',
  'shadow-nav': 'Under the floating tab bar.',
  'shadow-nav-bubble': 'Under the bubble of the selected tab.',
  'shadow-accent-glow': 'The emerald glow under the main button.',
  'duration-fast': 'Presses, switches and hovers.',
  'duration-base': 'Rows that open, chips that turn, most changes on screen.',
  'duration-slow': 'Fades between states and colors that change.',
  'easing-standard': 'Everything that moves, unless it springs or fades.',
  'radius-xs': 'Small badges and tags.',
  'radius-sm': 'Glyph badges of categories and small tiles.',
  'radius-md': 'Options inside a segmented switch, fields.',
  'radius-lg': 'Glass cards, panels and segmented switches.',
  'radius-xl': 'Account cards and sheets.',
  'radius-pill': 'Buttons, chips, pills, switches and meters.',
  'space-xxs': 'Inside pills and between a meter and its note.',
  'space-xs': 'Between an icon and its label, and between rows of a group.',
  'space-sm': 'Between the parts of a card.',
  'space-md': 'The padding of glass and the side margin of a phone screen.',
  'space-lg': 'Between the text and the actions of a notice; button padding.',
  'space-xl': 'Between the sections of a page.',
  'space-xxl': 'Above a page title and around large amounts.',
  'size-nav-bar': 'The height of the floating tab bar.',
  'font-weight-regular': 'Body text and captions.',
  'font-weight-medium': 'Rarely: a quieter emphasis than semibold.',
  'font-weight-semibold': 'Names in rows and strong body text.',
  'font-weight-bold': 'Section labels, tab labels and counts.',
  'font-weight-extrabold': 'Manrope titles and amounts.',
  'text-display': 'The capital on the overview: the largest amount.',
  'text-hero': 'The amount of a transaction and the hero of a sheet.',
  'text-title': 'Page titles.',
  'text-heading': 'Headings of cards and sheets.',
  'text-amount': 'Amounts on cards and in rows that lead.',
  'text-body': 'Running text and the values of rows.',
  'text-body-strong': 'Names in rows, the text of buttons and chips.',
  'text-caption': 'Notes under rows, figures beside a name, dates.',
  'text-tab': 'The labels of the tab bar.',
};

/// Renders [tokens] as the `tokens.json` of the Design System artifact
/// (docs/design/system): lists of named tokens with a usage note each, one
/// dark theme, and the type styles with the font files of the web kit.
String emitDesignSystem(List<DesignToken> tokens) {
  final colors = <Map<String, Object?>>[];
  final families = <String, Object?>{};
  final styles = <String, List<Map<String, Object?>>>{
    'Display': [],
    'Text': [],
  };
  final other = <String, List<Map<String, Object?>>>{};
  for (final token in tokens) {
    final name = cssName(token);
    switch (token.type) {
      case 'color':
        colors.add(_entry(token, _hex(token.value as int)));
      case 'fontFamily':
        families[token.path.last] = (token.value as List<String>).join(', ');
      case 'typography':
        final text = token.value as TypographyValue;
        final display = text.families.first == 'Manrope';
        styles[display ? 'Display' : 'Text']!.add({
          'name': name,
          'family': display ? 'display' : 'text',
          'fontSize': '${formatNumber(text.size)}px',
          'lineHeight': text.lineHeight,
          'fontWeight': text.weight,
          'letterSpacing': '${formatNumber(text.letterSpacing)}px',
          'usage': [
            _usageOf(token),
            if (token.extensions['uppercase'] == true) 'Set in capitals.',
            if (token.extensions['tabular'] == true) 'Tabular figures.',
          ].join(' '),
        });
      default:
        other
            .putIfAbsent(_family(token), () => [])
            .add(_entry(token, _value(token)));
    }
  }
  final document = {
    'name': 'Birka',
    'version': 1,
    'meta': {
      'source': 'packages/design/tokens/tokens/*.tokens.json',
      'generated': 'make tokens',
    },
    'color': {
      'themes': [
        {'id': 'dark', 'name': 'Dark'},
      ],
      'tokens': colors,
    },
    'type': {
      'fonts': [
        for (final (family, file, weight) in _fonts)
          {'family': family, 'file': 'fonts/$file', 'weight': weight},
      ],
      'families': families,
      'groups': [
        for (final MapEntry(:key, :value) in styles.entries)
          {
            'name': key,
            'family': key == 'Display' ? 'display' : 'text',
            'styles': value,
          },
      ],
    },
    for (final key in ['spacing', 'radius', 'shadow'])
      if (other.remove(key) case final list?) key: {'tokens': list},
    for (final MapEntry(:key, :value) in other.entries) key: {'tokens': value},
  };
  return '${const JsonEncoder.withIndent('  ').convert(document)}\n';
}

Map<String, Object?> _entry(DesignToken token, Object value) => {
  'name': cssName(token),
  'value': value,
  'usage': _usageOf(token),
};

String _usageOf(DesignToken token) {
  final name = cssName(token);
  if (token.description case final description?) return description;
  if (_usage[name] case final usage?) return usage;
  if (token.path case ['color', 'palette', final color]) {
    return const {
          'green',
          'amber',
          'sky',
          'violet',
          'rose',
          'orange',
          'cyan',
        }.contains(color)
        ? 'A color of categories, on their glyph badges and in charts.'
        : 'A raw value of the palette: reach it through a role token.';
  }
  if (token.path case ['color', 'art', _]) {
    return 'The glow of the abstract art of an account card in this color.';
  }
  throw TokenFormatException('$name needs a usage note for the design system');
}

String _family(DesignToken token) => switch (token.path.first) {
  'space' => 'spacing',
  'radius' => 'radius',
  'shadow' => 'shadow',
  'font' => 'fontWeight',
  final group => group,
};

Object _value(DesignToken token) => switch (token.type) {
  'dimension' => '${formatNumber(token.value as double)}px',
  'duration' => '${token.value}ms',
  'number' => token.value as double,
  'fontWeight' => token.value as int,
  'cubicBezier' =>
    'cubic-bezier('
        '${(token.value as List<double>).map(formatNumber).join(', ')})',
  'shadow' =>
    (token.value as List<ShadowValue>)
        .map(
          (layer) =>
              '${formatNumber(layer.offsetX)}px '
              '${formatNumber(layer.offsetY)}px '
              '${formatNumber(layer.blur)}px ${formatNumber(layer.spread)}px '
              '${_hex(layer.color)}',
        )
        .join(', '),
  final type => throw TokenFormatException('no design system value for $type'),
};

/// The color as `#rrggbb`, or `#rrggbbaa` when it is see-through.
String _hex(int argb) {
  final alpha = argb >>> 24;
  final channels = [argb >> 16 & 0xFF, argb >> 8 & 0xFF, argb & 0xFF];
  if (alpha != 0xFF) channels.add(alpha);
  return '#${channels.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
}
