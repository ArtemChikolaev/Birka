import 'dart:typed_data';

import 'package:import_common/src/data/pdf/pdf_document.dart';
import 'package:import_common/src/data/pdf/pdf_syntax.dart';
import 'package:meta/meta.dart';

/// A piece of text that a page shows at one place.
@immutable
final class PdfTextRun {
  /// Creates a run at [x] and [y], in points from the bottom left of the page.
  const PdfTextRun(this.x, this.y, this.text);

  /// How far from the left edge it starts.
  final double x;

  /// How high above the bottom edge its baseline is.
  final double y;

  /// The text.
  final String text;

  @override
  String toString() => '$x,$y: $text';
}

/// A line of a page: the runs at one height, from left to right.
@immutable
final class PdfLine {
  /// Creates a line.
  const PdfLine(this.page, this.y, this.runs);

  /// The page, from 0.
  final int page;

  /// The height of the line on the page.
  final double y;

  /// The runs, from left to right.
  final List<PdfTextRun> runs;

  /// The text of the runs, one space between them.
  String get text => runs.map((run) => run.text).join(' ');

  @override
  String toString() => '$page/$y: $text';
}

/// The lines of text of every page of [document], each page from its top.
///
/// Runs whose baselines are at most [tolerance] points apart make one line.
List<PdfLine> textLines(PdfDocument document, {double tolerance = 2}) {
  final lines = <PdfLine>[];
  for (final (index, page) in document.pages.indexed) {
    final runs = textRuns(document, page)..sort((a, b) => b.y.compareTo(a.y));
    var line = <PdfTextRun>[];
    void close() {
      if (line.isEmpty) return;
      line.sort((a, b) => a.x.compareTo(b.x));
      lines.add(PdfLine(index, line.first.y, List.unmodifiable(line)));
      line = <PdfTextRun>[];
    }

    for (final run in runs) {
      if (line.isNotEmpty && (line.first.y - run.y).abs() > tolerance) close();
      line.add(run);
    }
    close();
  }
  return lines;
}

/// The runs of text that [page] shows, in the order it shows them.
///
/// Text that follows other text without a move of its own joins it: the
/// widths of the glyphs are not read, so it cannot tell how far the first
/// went. Forms and inline images are left out.
List<PdfTextRun> textRuns(PdfDocument document, PdfPage page) {
  final fonts = document.dictionaryOf(page.resources['Font']) ?? const {};
  final cache = <String, _Font>{};
  final parser = PdfParser(document.contentOf(page));
  final operands = <Object?>[];
  final runs = <PdfTextRun>[];
  final saved = <_Matrix>[];
  var transform = _Matrix.identity;
  var text = _Matrix.identity;
  var line = _Matrix.identity;
  _Font? font;
  var leading = 0.0;
  var moved = true;

  double number(int index) {
    if (index < 0 || index >= operands.length) return 0;
    final value = operands[index];
    return value is num ? value.toDouble() : 0;
  }

  _Matrix matrix() => _Matrix(
    number(0),
    number(1),
    number(2),
    number(3),
    number(4),
    number(5),
  );

  void moveTo(double x, double y) {
    line = _Matrix.translation(x, y).times(line);
    text = line;
    moved = true;
  }

  void show(String shown) {
    if (shown.isEmpty) return;
    final at = text.times(transform);
    if (!moved && runs.isNotEmpty) {
      final last = runs.removeLast();
      runs.add(PdfTextRun(last.x, last.y, last.text + shown));
    } else {
      runs.add(PdfTextRun(at.e, at.f, shown));
    }
    moved = false;
  }

  String decoded(Object? string) =>
      string is PdfString ? (font ?? _Font.latin1).decode(string.bytes) : '';

  while (true) {
    final Object? token;
    try {
      if (parser.atEnd) break;
      token = parser.next();
    } on PdfException {
      break;
    }
    if (token is! PdfKeyword) {
      operands.add(token);
      continue;
    }
    switch (token.value) {
      case 'q':
        saved.add(transform);
      case 'Q':
        if (saved.isNotEmpty) transform = saved.removeLast();
      case 'cm':
        transform = matrix().times(transform);
      case 'BT':
        text = line = _Matrix.identity;
        moved = true;
      case 'Tf':
        final name = operands.isEmpty ? null : operands.first;
        if (name is PdfName) {
          font = cache[name.value] ??= _Font.of(document, fonts[name.value]);
        }
      case 'Tm':
        text = line = matrix();
        moved = true;
      case 'Td':
        moveTo(number(0), number(1));
      case 'TD':
        leading = -number(1);
        moveTo(number(0), number(1));
      case 'TL':
        leading = number(0);
      case 'T*':
        moveTo(0, -leading);
      case 'Tj':
        show(decoded(operands.lastOrNull));
      case "'":
        moveTo(0, -leading);
        show(decoded(operands.lastOrNull));
      case '"':
        moveTo(0, -leading);
        show(decoded(operands.lastOrNull));
      case 'TJ':
        final parts = operands.lastOrNull;
        if (parts is List<Object?>) {
          final shown = StringBuffer();
          for (final part in parts) {
            if (part is PdfString) shown.write(decoded(part));
            // A wide gap between glyphs stands for a space.
            if (part is num && part < -250) shown.write(' ');
          }
          show(shown.toString());
        }
      case 'BI':
        _skipInlineImage(parser);
    }
    operands.clear();
  }
  return runs;
}

/// Moves [parser] past the data of an inline image, up to and with `EI`.
void _skipInlineImage(PdfParser parser) {
  final bytes = parser.bytes;
  var at = parser.position;
  while (at + 2 < bytes.length &&
      !(bytes[at] == 0x49 && bytes[at + 1] == 0x44)) {
    at++;
  }
  at += 2;
  while (at + 2 < bytes.length) {
    if (PdfParser.isSpace(bytes[at]) &&
        bytes[at + 1] == 0x45 &&
        bytes[at + 2] == 0x49 &&
        (at + 3 >= bytes.length || PdfParser.isSpace(bytes[at + 3]))) {
      parser.position = at + 3;
      return;
    }
    at++;
  }
  parser.position = bytes.length;
}

/// How a font turns the bytes of a string into text: two bytes for each
/// code in a composite font, one in a simple font, and its map to Unicode.
final class _Font {
  _Font({required this.twoBytes, required this.unicode});

  factory _Font.of(PdfDocument document, Object? reference) {
    final dictionary = document.dictionaryOf(reference) ?? const {};
    final unicode = <int, String>{};
    final map = document.resolve(dictionary['ToUnicode']);
    if (map is PdfStream) {
      try {
        _readCmap(document.bytesOf(map), unicode);
      } on PdfException {
        unicode.clear();
      }
    }
    return _Font(
      twoBytes: dictionary['Subtype'] == const PdfName('Type0'),
      unicode: unicode,
    );
  }

  /// A simple font without a map: each byte is the character of its code.
  static final latin1 = _Font(twoBytes: false, unicode: const {});

  static final _unknown = String.fromCharCode(0xfffd);

  final bool twoBytes;
  final Map<int, String> unicode;

  String decode(Uint8List bytes) {
    final text = StringBuffer();
    if (twoBytes) {
      for (var index = 0; index + 1 < bytes.length; index += 2) {
        text.write(unicode[bytes[index] << 8 | bytes[index + 1]] ?? _unknown);
      }
    } else {
      for (final byte in bytes) {
        text.write(unicode[byte] ?? String.fromCharCode(byte));
      }
    }
    return text.toString();
  }
}

/// Reads the `bfchar` and `bfrange` mappings of a ToUnicode CMap into
/// [unicode].
void _readCmap(Uint8List bytes, Map<int, String> unicode) {
  final parser = PdfParser(bytes);
  while (!parser.atEnd) {
    final token = parser.next();
    if (token == const PdfKeyword('beginbfchar')) {
      while (true) {
        final source = parser.next();
        if (source == const PdfKeyword('endbfchar')) break;
        final target = parser.next();
        if (source is PdfString && target is PdfString) {
          unicode[_code(source.bytes)] = _utf16(target.bytes);
        }
      }
    } else if (token == const PdfKeyword('beginbfrange')) {
      while (true) {
        final low = parser.next();
        if (low == const PdfKeyword('endbfrange')) break;
        final high = parser.next();
        final target = parser.next();
        if (low is! PdfString || high is! PdfString) continue;
        final first = _code(low.bytes);
        final last = _code(high.bytes);
        if (last < first || last - first > 0xffff) continue;
        if (target is List<Object?>) {
          for (var code = first; code <= last; code++) {
            final item = code - first < target.length
                ? target[code - first]
                : null;
            if (item is PdfString) unicode[code] = _utf16(item.bytes);
          }
        } else if (target is PdfString && target.bytes.isNotEmpty) {
          final units = _units(target.bytes);
          for (var code = first; code <= last; code++) {
            // The last unit counts up through the range.
            final shifted = [
              ...units.take(units.length - 1),
              units.last + code - first,
            ];
            unicode[code] = String.fromCharCodes(shifted);
          }
        }
      }
    }
  }
}

int _code(Uint8List bytes) {
  var code = 0;
  for (final byte in bytes) {
    code = code << 8 | byte;
  }
  return code;
}

List<int> _units(Uint8List bytes) => [
  for (var index = 0; index + 1 < bytes.length; index += 2)
    bytes[index] << 8 | bytes[index + 1],
];

String _utf16(Uint8List bytes) => String.fromCharCodes(_units(bytes));

/// An affine transform of PDF: `[a b c d e f]` for row vectors.
@immutable
final class _Matrix {
  const _Matrix(this.a, this.b, this.c, this.d, this.e, this.f);

  const _Matrix.translation(double x, double y) : this(1, 0, 0, 1, x, y);

  static const identity = _Matrix(1, 0, 0, 1, 0, 0);

  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  /// This transform and then [other].
  _Matrix times(_Matrix other) => _Matrix(
    a * other.a + b * other.c,
    a * other.b + b * other.d,
    c * other.a + d * other.c,
    c * other.b + d * other.d,
    e * other.a + f * other.c + other.e,
    e * other.b + f * other.d + other.f,
  );
}
