import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A name such as `/Type`, without its slash.
@immutable
final class PdfName {
  /// Creates a name.
  const PdfName(this.value);

  /// The name.
  final String value;

  @override
  bool operator ==(Object other) => other is PdfName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '/$value';
}

/// A reference to an indirect object, such as `12 0 R`.
@immutable
final class PdfRef {
  /// Creates a reference.
  const PdfRef(this.number, this.generation);

  /// The number of the object.
  final int number;

  /// Its generation.
  final int generation;

  @override
  bool operator ==(Object other) =>
      other is PdfRef &&
      other.number == number &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(number, generation);

  @override
  String toString() => '$number $generation R';
}

/// A string as its bytes: what they mean depends on the font that shows them.
@immutable
final class PdfString {
  /// Creates a string.
  const PdfString(this.bytes);

  /// The bytes.
  final Uint8List bytes;

  /// The bytes as Latin-1 text, which is how names of things read.
  String get latin1Text => latin1.decode(bytes);
}

/// A stream: its dictionary and its bytes as the file stores them.
@immutable
final class PdfStream {
  /// Creates a stream.
  const PdfStream(this.dictionary, this.data);

  /// The dictionary.
  final Map<String, Object?> dictionary;

  /// The bytes, still in their filters.
  final Uint8List data;
}

/// A keyword: an operator of a page, such as `Tj`, or a word of the file
/// itself, such as `obj`.
@immutable
final class PdfKeyword {
  /// Creates a keyword.
  const PdfKeyword(this.value);

  /// The word.
  final String value;

  @override
  bool operator ==(Object other) => other is PdfKeyword && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// What is wrong in a file that claims to be a PDF.
final class PdfException implements Exception {
  /// Creates the failure.
  const PdfException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'PdfException: $message';
}

/// Reads the objects of a PDF from [bytes], from [position] on (ISO 32000-1,
/// section 7.3).
///
/// Numbers come back as `int` or `double`, `true`, `false` and `null` as
/// themselves, arrays as lists and dictionaries as maps by name.
final class PdfParser {
  /// Creates a parser.
  PdfParser(this.bytes, [this.position = 0]);

  /// What it reads.
  final Uint8List bytes;

  /// Where it reads next.
  int position;

  /// Whether nothing but spaces and comments is left.
  bool get atEnd {
    skipSpace();
    return position >= bytes.length;
  }

  /// Skips white space and comments.
  void skipSpace() {
    while (position < bytes.length) {
      final byte = bytes[position];
      if (isSpace(byte)) {
        position++;
      } else if (byte == _percent) {
        while (position < bytes.length &&
            bytes[position] != _lf &&
            bytes[position] != _cr) {
          position++;
        }
      } else {
        return;
      }
    }
  }

  /// The next object, or a [PdfKeyword] for a word that is not one.
  ///
  /// A number is followed by its generation and `R` in a reference, which
  /// comes back as a [PdfRef].
  Object? next() {
    skipSpace();
    if (position >= bytes.length) throw const PdfException('The file ends');
    final byte = bytes[position];
    switch (byte) {
      case _slash:
        return _name();
      case _openParen:
        return _literal();
      case _less:
        if (_at(position + 1) == _less) return _dictionary();
        return _hex();
      case _openBracket:
        return _array();
      case _closeBracket:
        position++;
        return const PdfKeyword(']');
      case _greater:
        if (_at(position + 1) == _greater) {
          position += 2;
          return const PdfKeyword('>>');
        }
        throw PdfException('A stray > at $position');
    }
    if (_isNumberStart(byte)) return _numberOrReference();
    final word = _word();
    return switch (word) {
      'true' => true,
      'false' => false,
      'null' => null,
      _ => PdfKeyword(word),
    };
  }

  /// Reads the keyword [word], or throws.
  void expect(String word) {
    final next = this.next();
    if (next != PdfKeyword(word)) {
      throw PdfException('Expected $word, found $next');
    }
  }

  int? _at(int index) => index < bytes.length ? bytes[index] : null;

  PdfName _name() {
    position++;
    final name = BytesBuilder(copy: false);
    while (position < bytes.length && _isRegular(bytes[position])) {
      final byte = bytes[position];
      if (byte == _hash && position + 2 < bytes.length) {
        final value = int.tryParse(
          String.fromCharCodes(bytes, position + 1, position + 3),
          radix: 16,
        );
        if (value != null) {
          name.addByte(value);
          position += 3;
          continue;
        }
      }
      name.addByte(byte);
      position++;
    }
    return PdfName(latin1.decode(name.takeBytes()));
  }

  PdfString _literal() {
    position++;
    final text = BytesBuilder(copy: false);
    var depth = 1;
    while (position < bytes.length) {
      final byte = bytes[position++];
      if (byte == _backslash) {
        if (position >= bytes.length) break;
        final escaped = bytes[position++];
        switch (escaped) {
          case 0x6e: // n
            text.addByte(_lf);
          case 0x72: // r
            text.addByte(_cr);
          case 0x74: // t
            text.addByte(0x09);
          case 0x62: // b
            text.addByte(0x08);
          case 0x66: // f
            text.addByte(0x0c);
          case _cr:
            if (_at(position) == _lf) position++;
          case _lf:
            break;
          case >= 0x30 && <= 0x37:
            var value = escaped - 0x30;
            for (var digit = 0; digit < 2; digit++) {
              final next = _at(position);
              if (next == null || next < 0x30 || next > 0x37) break;
              value = value * 8 + next - 0x30;
              position++;
            }
            text.addByte(value & 0xff);
          default:
            text.addByte(escaped);
        }
      } else if (byte == _openParen) {
        depth++;
        text.addByte(byte);
      } else if (byte == _closeParen) {
        depth--;
        if (depth == 0) return PdfString(text.takeBytes());
        text.addByte(byte);
      } else if (byte == _cr) {
        // A line end in a string reads as LF, whatever it was.
        if (_at(position) == _lf) position++;
        text.addByte(_lf);
      } else {
        text.addByte(byte);
      }
    }
    throw const PdfException('A string does not end');
  }

  PdfString _hex() {
    position++;
    final text = BytesBuilder(copy: false);
    int? high;
    while (position < bytes.length) {
      final byte = bytes[position++];
      if (byte == _greater) {
        if (high != null) text.addByte(high << 4);
        return PdfString(text.takeBytes());
      }
      final digit = _hexDigit(byte);
      if (digit == null) continue;
      if (high == null) {
        high = digit;
      } else {
        text.addByte(high << 4 | digit);
        high = null;
      }
    }
    throw const PdfException('A hex string does not end');
  }

  List<Object?> _array() {
    position++;
    final items = <Object?>[];
    while (true) {
      final item = next();
      if (item == const PdfKeyword(']')) return items;
      items.add(item);
    }
  }

  Map<String, Object?> _dictionary() {
    position += 2;
    final entries = <String, Object?>{};
    while (true) {
      final key = next();
      if (key == const PdfKeyword('>>')) return entries;
      if (key is! PdfName) throw PdfException('A key $key is not a name');
      entries[key.value] = next();
    }
  }

  Object _numberOrReference() {
    final start = position;
    final first = _number();
    if (first is! int || first < 0) return first;
    final afterFirst = position;
    skipSpace();
    if (position < bytes.length && _isDigit(bytes[position])) {
      final generation = _number();
      skipSpace();
      if (generation is int &&
          _at(position) == 0x52 && // R
          !_isRegular(_at(position + 1) ?? _space)) {
        position++;
        return PdfRef(first, generation);
      }
    }
    position = afterFirst;
    assert(position > start, 'A number moves on');
    return first;
  }

  num _number() {
    final start = position;
    if (bytes[position] == 0x2b || bytes[position] == 0x2d) position++;
    var dot = false;
    while (position < bytes.length) {
      final byte = bytes[position];
      if (_isDigit(byte)) {
        position++;
      } else if (byte == 0x2e && !dot) {
        dot = true;
        position++;
      } else {
        break;
      }
    }
    final text = String.fromCharCodes(bytes, start, position);
    final value = dot ? double.tryParse(text) : int.tryParse(text);
    if (value != null) return value;
    if (text == '-' || text == '+' || text == '.' || text == '-.') return 0;
    return double.tryParse(text) ?? (throw PdfException('Not a number: $text'));
  }

  String _word() {
    final start = position;
    while (position < bytes.length && _isRegular(bytes[position])) {
      position++;
    }
    if (position == start) {
      throw PdfException('An unknown byte ${bytes[position]} at $position');
    }
    return latin1.decode(bytes.sublist(start, position));
  }

  /// Whether [byte] is white space in a PDF.
  static bool isSpace(int byte) =>
      byte == _space ||
      byte == _lf ||
      byte == _cr ||
      byte == 0x09 ||
      byte == 0x0c ||
      byte == 0x00;

  static bool _isDelimiter(int byte) =>
      byte == _openParen ||
      byte == _closeParen ||
      byte == _less ||
      byte == _greater ||
      byte == _openBracket ||
      byte == _closeBracket ||
      byte == 0x7b ||
      byte == 0x7d ||
      byte == _slash ||
      byte == _percent;

  static bool _isRegular(int byte) => !isSpace(byte) && !_isDelimiter(byte);

  static bool _isDigit(int byte) => byte >= 0x30 && byte <= 0x39;

  static bool _isNumberStart(int byte) =>
      _isDigit(byte) || byte == 0x2b || byte == 0x2d || byte == 0x2e;

  static int? _hexDigit(int byte) => switch (byte) {
    >= 0x30 && <= 0x39 => byte - 0x30,
    >= 0x41 && <= 0x46 => byte - 0x37,
    >= 0x61 && <= 0x66 => byte - 0x57,
    _ => null,
  };

  static const _space = 0x20;
  static const _lf = 0x0a;
  static const _cr = 0x0d;
  static const _percent = 0x25;
  static const _slash = 0x2f;
  static const _openParen = 0x28;
  static const _closeParen = 0x29;
  static const _backslash = 0x5c;
  static const _less = 0x3c;
  static const _greater = 0x3e;
  static const _openBracket = 0x5b;
  static const _closeBracket = 0x5d;
  static const _hash = 0x23;
}
