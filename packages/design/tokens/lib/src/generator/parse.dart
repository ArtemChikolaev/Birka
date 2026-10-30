import 'package:design_tokens/src/generator/design_token.dart';

/// The `$extensions` key that holds Birka's own token settings.
const birkaExtension = 'io.github.artemchikolaev.birka';

final _alias = RegExp(r'^\{([^{}]+)\}$');
final _hex = RegExp(r'^#([0-9a-fA-F]{6})$');

const _weightKeywords = {
  'thin': 100,
  'hairline': 100,
  'extra-light': 200,
  'ultra-light': 200,
  'light': 300,
  'normal': 400,
  'regular': 400,
  'book': 400,
  'medium': 500,
  'semi-bold': 600,
  'demi-bold': 600,
  'bold': 700,
  'extra-bold': 800,
  'ultra-bold': 800,
  'black': 900,
  'heavy': 900,
  'extra-black': 950,
  'ultra-black': 950,
};

/// Parses a DTCG document into tokens, in document order, with every alias
/// resolved.
///
/// Supports the types Birka uses: `color` in sRGB, `dimension`, `duration`,
/// `number`, `fontFamily`, `fontWeight`, `cubicBezier`, `typography` and
/// outer `shadow`.
List<DesignToken> parseTokens(Map<String, Object?> document) {
  final raw = <String, _RawToken>{};
  _collect(document, const [], null, raw);
  return [
    for (final token in raw.values)
      DesignToken(
        path: token.path,
        type: token.type,
        value: _convert(
          token.name,
          token.type,
          _resolve(token.value, [token.name], raw),
        ),
        description: token.description,
        extensions: token.extensions,
      ),
  ];
}

final class _RawToken {
  const _RawToken(
    this.path,
    this.type,
    this.value,
    this.description,
    this.extensions,
  );

  final List<String> path;
  final String type;
  final Object? value;
  final String? description;
  final Map<String, Object?> extensions;

  String get name => path.join('.');
}

void _collect(
  Map<String, Object?> group,
  List<String> path,
  String? inheritedType,
  Map<String, _RawToken> raw,
) {
  final type = _typeOf(group, path) ?? inheritedType;
  for (final MapEntry(:key, :value) in group.entries) {
    if (key.startsWith(r'$')) continue;
    final childPath = [...path, key];
    final name = childPath.join('.');
    if (value is! Map<String, Object?>) {
      throw TokenFormatException('$name is neither a token nor a group');
    }
    if (!value.containsKey(r'$value')) {
      _collect(value, childPath, type, raw);
      continue;
    }
    final tokenType = _typeOf(value, childPath) ?? type;
    if (tokenType == null) {
      throw TokenFormatException('$name has no \$type');
    }
    raw[name] = _RawToken(
      childPath,
      tokenType,
      value[r'$value'],
      _descriptionOf(value, name),
      _extensionsOf(value),
    );
  }
}

String? _typeOf(Map<String, Object?> node, List<String> path) {
  final type = node[r'$type'];
  if (type is String?) return type;
  throw TokenFormatException('${path.join('.')} has a non-string type');
}

String? _descriptionOf(Map<String, Object?> token, String name) {
  final description = token[r'$description'];
  if (description is String?) return description;
  throw TokenFormatException('$name has a non-string description');
}

Map<String, Object?> _extensionsOf(Map<String, Object?> token) {
  final extensions = token[r'$extensions'];
  if (extensions is! Map<String, Object?>) return const {};
  final birka = extensions[birkaExtension];
  return birka is Map<String, Object?> ? birka : const {};
}

Object? _resolve(
  Object? value,
  List<String> chain,
  Map<String, _RawToken> raw,
) {
  if (value is String) {
    final match = _alias.firstMatch(value);
    if (match == null) return value;
    final target = match.group(1)!;
    if (chain.contains(target)) {
      throw TokenFormatException(
        'alias cycle: ${[...chain, target].join(' -> ')}',
      );
    }
    final token = raw[target];
    if (token == null) {
      throw TokenFormatException('${chain.first} refers to unknown $target');
    }
    return _resolve(token.value, [...chain, target], raw);
  }
  if (value is Map<String, Object?>) {
    return {
      for (final MapEntry(:key, value: item) in value.entries)
        key: _resolve(item, chain, raw),
    };
  }
  if (value is List<Object?>) {
    return [for (final item in value) _resolve(item, chain, raw)];
  }
  return value;
}

Object _convert(String name, String type, Object? value) => switch (type) {
  'color' => _color(name, value),
  'dimension' => _dimension(name, value),
  'duration' => _duration(name, value),
  'number' => _number(name, value),
  'fontFamily' => _fontFamily(name, value),
  'fontWeight' => _fontWeight(name, value),
  'cubicBezier' => _cubicBezier(name, value),
  'typography' => _typography(name, value),
  'shadow' => _shadow(name, value),
  _ => throw TokenFormatException('$name has an unsupported type: $type'),
};

int _color(String name, Object? value) {
  if (value is! Map<String, Object?>) {
    throw TokenFormatException('$name: a color is an object with components');
  }
  if (value['colorSpace'] != 'srgb') {
    throw TokenFormatException('$name: only the srgb color space is supported');
  }
  final components = value['components'];
  if (components is! List<Object?> ||
      components.length != 3 ||
      components.any((c) => c is! num || c < 0 || c > 1)) {
    throw TokenFormatException(
      '$name: srgb needs three components from 0 to 1',
    );
  }
  final alpha = value['alpha'] ?? 1;
  if (alpha is! num || alpha < 0 || alpha > 1) {
    throw TokenFormatException('$name: alpha must be from 0 to 1');
  }
  final channels = [
    for (final component in components.cast<num>()) (component * 255).round(),
  ];
  final hex = value['hex'];
  if (hex != null) {
    final digits = hex is String ? _hex.firstMatch(hex)?.group(1) : null;
    if (digits == null) {
      throw TokenFormatException('$name: hex must look like #rrggbb');
    }
    for (var i = 0; i < 3; i++) {
      final fromHex = int.parse(digits.substring(i * 2, i * 2 + 2), radix: 16);
      if ((fromHex - channels[i]).abs() > 1) {
        throw TokenFormatException('$name: $hex does not match $components');
      }
    }
  }
  return ((alpha * 255).round() << 24) |
      (channels[0] << 16) |
      (channels[1] << 8) |
      channels[2];
}

double _dimension(String name, Object? value) {
  if (value is Map<String, Object?>) {
    final amount = value['value'];
    if (amount is num) {
      switch (value['unit']) {
        case 'px':
          return amount.toDouble();
        case 'rem':
          return amount * 16;
      }
    }
  }
  throw TokenFormatException('$name: a dimension is {value, unit: px or rem}');
}

int _duration(String name, Object? value) {
  if (value is Map<String, Object?>) {
    final amount = value['value'];
    if (amount is num) {
      switch (value['unit']) {
        case 'ms':
          return amount.round();
        case 's':
          return (amount * 1000).round();
      }
    }
  }
  throw TokenFormatException('$name: a duration is {value, unit: ms or s}');
}

double _number(String name, Object? value) {
  if (value is num) return value.toDouble();
  throw TokenFormatException('$name: expected a number');
}

List<String> _fontFamily(String name, Object? value) {
  if (value is String) return [value];
  if (value is List<Object?> &&
      value.isNotEmpty &&
      value.every((v) => v is String)) {
    return value.cast<String>();
  }
  throw TokenFormatException(
    '$name: a font family is a name or a list of names',
  );
}

int _fontWeight(String name, Object? value) {
  if (value is num && value >= 1 && value <= 1000) return value.round();
  final keyword = value is String ? _weightKeywords[value] : null;
  if (keyword != null) return keyword;
  throw TokenFormatException('$name: a font weight is 1 to 1000 or a keyword');
}

List<double> _cubicBezier(String name, Object? value) {
  if (value is List<Object?> &&
      value.length == 4 &&
      value.every((v) => v is num)) {
    final points = [for (final v in value.cast<num>()) v.toDouble()];
    if (points[0] >= 0 && points[0] <= 1 && points[2] >= 0 && points[2] <= 1) {
      return points;
    }
  }
  throw TokenFormatException(
    '$name: a cubic bezier is [x1, y1, x2, y2] with x in 0..1',
  );
}

List<ShadowValue> _shadow(String name, Object? value) {
  final layers = value is List<Object?> ? value : [value];
  return [for (final layer in layers) _shadowLayer(name, layer)];
}

ShadowValue _shadowLayer(String name, Object? value) {
  if (value is! Map<String, Object?>) {
    throw TokenFormatException(
      '$name: a shadow is an object or a list of them',
    );
  }
  if (value['inset'] == true) {
    throw TokenFormatException('$name: inset shadows are not supported');
  }
  return ShadowValue(
    color: _color('$name.color', value['color']),
    offsetX: _dimension('$name.offsetX', value['offsetX']),
    offsetY: _dimension('$name.offsetY', value['offsetY']),
    blur: _dimension('$name.blur', value['blur']),
    spread: _dimension('$name.spread', value['spread']),
  );
}

TypographyValue _typography(String name, Object? value) {
  if (value is! Map<String, Object?>) {
    throw TokenFormatException('$name: typography is an object');
  }
  return TypographyValue(
    families: _fontFamily('$name.fontFamily', value['fontFamily']),
    size: _dimension('$name.fontSize', value['fontSize']),
    weight: _fontWeight('$name.fontWeight', value['fontWeight']),
    letterSpacing: _dimension('$name.letterSpacing', value['letterSpacing']),
    lineHeight: _number('$name.lineHeight', value['lineHeight']),
  );
}
