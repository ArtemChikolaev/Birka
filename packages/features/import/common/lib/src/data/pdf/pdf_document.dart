import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:import_common/src/data/pdf/pdf_syntax.dart';

/// Where an object of a PDF lives.
final class _Location {
  const _Location.inFile(this.offset) : stream = null, index = null;

  const _Location.inStream(int this.stream, int this.index) : offset = null;

  final int? offset;
  final int? stream;
  final int? index;
}

/// A page of a PDF: what it draws and the fonts it draws with.
final class PdfPage {
  /// Creates a page.
  const PdfPage(this.dictionary, this.resources);

  /// The dictionary of the page.
  final Map<String, Object?> dictionary;

  /// Its resources, which it can take from the pages above it.
  final Map<String, Object?> resources;
}

/// The objects of a PDF made by a program, such as a statement of a bank: a
/// cross-reference table or stream with its earlier versions, objects in the
/// file or in object streams, and streams in Flate (ISO 32000-1, section 7).
///
/// It does not decrypt: an encrypted file throws a [PdfException].
final class PdfDocument {
  PdfDocument._(this._bytes, this._locations, this.trailer);

  /// Reads the structure of the PDF in [bytes]. Throws a [PdfException] when
  /// it is not one this reader can take.
  factory PdfDocument.parse(Uint8List bytes) {
    final start = _lastIndexOf(bytes, 'startxref');
    if (start < 0) throw const PdfException('No startxref');
    final parser = PdfParser(bytes, start + 'startxref'.length);
    final offset = parser.next();
    if (offset is! int || offset < 0 || offset >= bytes.length) {
      throw PdfException('A wrong start of the cross-reference: $offset');
    }
    final locations = <int, _Location>{};
    Map<String, Object?>? trailer;
    final document = PdfDocument._(bytes, locations, const {});
    int? next = offset;
    final seen = <int>{};
    while (next != null && seen.add(next)) {
      final section = document._readSection(next, locations);
      trailer ??= section;
      final previous = section['Prev'];
      next = previous is int ? previous : null;
    }
    if (trailer == null) throw const PdfException('No trailer');
    if (trailer.containsKey('Encrypt')) {
      throw const PdfException('The file is encrypted');
    }
    return PdfDocument._(bytes, locations, trailer);
  }

  final Uint8List _bytes;
  final Map<int, _Location> _locations;

  /// The trailer of the newest cross-reference.
  final Map<String, Object?> trailer;

  final _objects = <int, Object?>{};
  final _streams = <int, List<Object?>>{};

  /// [value] itself, or the object it refers to.
  Object? resolve(Object? value) {
    if (value is! PdfRef) return value;
    if (_objects.containsKey(value.number)) return _objects[value.number];
    // A loop of references ends as null.
    _objects[value.number] = null;
    final object = _load(value.number);
    return _objects[value.number] = object;
  }

  /// The dictionary that [value] is or refers to, the dictionary of a stream
  /// included.
  Map<String, Object?>? dictionaryOf(Object? value) => switch (resolve(value)) {
    final Map<String, Object?> dictionary => dictionary,
    final PdfStream stream => stream.dictionary,
    _ => null,
  };

  /// The bytes of [stream] with its filters undone.
  Uint8List bytesOf(PdfStream stream) {
    final filters = _listOf(stream.dictionary['Filter']);
    final parameters = _listOf(stream.dictionary['DecodeParms']);
    var data = stream.data;
    for (final (index, filter) in filters.indexed) {
      final name = resolve(filter);
      if (name is! PdfName) throw const PdfException('A filter is no name');
      final options = index < parameters.length
          ? dictionaryOf(parameters[index])
          : null;
      data = switch (name.value) {
        'FlateDecode' || 'Fl' => _predicted(_inflate(data), options),
        _ => throw PdfException('The filter ${name.value} is not supported'),
      };
    }
    return data;
  }

  /// The pages in their order.
  List<PdfPage> get pages {
    final root = dictionaryOf(trailer['Root']);
    if (root == null) throw const PdfException('No catalog');
    final pages = <PdfPage>[];
    final visited = <Map<String, Object?>>{};
    void walk(Object? node, Map<String, Object?> inherited) {
      final dictionary = dictionaryOf(node);
      if (dictionary == null || !visited.add(dictionary)) return;
      final resources = dictionaryOf(dictionary['Resources']) ?? inherited;
      final kids = resolve(dictionary['Kids']);
      if (kids is List<Object?>) {
        for (final kid in kids) {
          walk(kid, resources);
        }
      } else {
        pages.add(PdfPage(dictionary, resources));
      }
    }

    walk(root['Pages'], const {});
    return pages;
  }

  /// What [page] draws: its content streams one after another.
  Uint8List contentOf(PdfPage page) {
    final content = BytesBuilder(copy: false);
    for (final part in _listOf(page.dictionary['Contents'])) {
      final stream = resolve(part);
      if (stream is! PdfStream) continue;
      content
        ..add(bytesOf(stream))
        ..addByte(0x0a);
    }
    return content.takeBytes();
  }

  List<Object?> _listOf(Object? value) => switch (resolve(value)) {
    null => const [],
    final List<Object?> list => list,
    final single => [single],
  };

  Object? _load(int number) {
    final location = _locations[number];
    if (location == null) return null;
    if (location.offset case final offset?) {
      final parser = PdfParser(_bytes, offset)
        ..next()
        ..next()
        ..expect('obj');
      return _objectAt(parser);
    }
    final objects = _streams[location.stream!] ??= _objectStream(
      location.stream!,
    );
    final index = location.index!;
    return index < objects.length ? objects[index] : null;
  }

  /// The object that [parser] stands before, with the data of a stream when
  /// a stream follows its dictionary.
  Object? _objectAt(PdfParser parser) {
    final object = parser.next();
    if (object is! Map<String, Object?>) return object;
    final mark = parser.position;
    parser.skipSpace();
    if (!_startsAt(_bytes, parser.position, 'stream')) {
      parser.position = mark;
      return object;
    }
    var start = parser.position + 'stream'.length;
    if (_at(start) == 0x0d) start++;
    if (_at(start) == 0x0a) start++;
    final length = resolve(object['Length']);
    var end = length is int ? start + length : -1;
    if (end < start ||
        end > _bytes.length ||
        _indexOf(_bytes, 'endstream', end, end + 32) < 0) {
      // A wrong length: the data ends where `endstream` begins.
      end = _indexOf(_bytes, 'endstream', start, _bytes.length);
      if (end < 0) throw const PdfException('A stream does not end');
      while (end > start && PdfParser.isSpace(_bytes[end - 1])) {
        end--;
      }
    }
    return PdfStream(object, Uint8List.sublistView(_bytes, start, end));
  }

  int? _at(int index) => index < _bytes.length ? _bytes[index] : null;

  List<Object?> _objectStream(int number) {
    final stream = resolve(PdfRef(number, 0));
    if (stream is! PdfStream) return const [];
    final count = stream.dictionary['N'];
    final first = stream.dictionary['First'];
    if (count is! int || first is! int) return const [];
    final data = bytesOf(stream);
    final header = PdfParser(data);
    final offsets = <int>[];
    for (var index = 0; index < count; index++) {
      header.next();
      final offset = header.next();
      offsets.add(offset is int ? offset : 0);
    }
    return [
      for (final offset in offsets) PdfParser(data, first + offset).next(),
    ];
  }

  /// Reads the cross-reference at [offset] into [locations], keeping what a
  /// newer one already gave, and returns its trailer.
  Map<String, Object?> _readSection(
    int offset,
    Map<int, _Location> locations,
  ) {
    final parser = PdfParser(_bytes, offset)..skipSpace();
    if (_startsAt(_bytes, parser.position, 'xref')) {
      parser.expect('xref');
      while (true) {
        final word = parser.next();
        if (word == const PdfKeyword('trailer')) break;
        final count = parser.next();
        if (word is! int || count is! int) {
          throw const PdfException('A broken cross-reference table');
        }
        for (var index = 0; index < count; index++) {
          final at = parser.next();
          parser.next();
          final kind = parser.next();
          if (at is int && kind == const PdfKeyword('n')) {
            locations.putIfAbsent(word + index, () => _Location.inFile(at));
          }
        }
      }
      final trailer = parser.next();
      if (trailer is! Map<String, Object?>) {
        throw const PdfException('No trailer');
      }
      // A hybrid file keeps its compressed objects in a stream beside.
      if (trailer['XRefStm'] case final int stream) {
        _readSection(stream, locations);
      }
      return trailer;
    }
    final stream = (parser
      ..next()
      ..next()
      ..expect('obj'));
    final object = _objectAt(stream);
    if (object is! PdfStream ||
        object.dictionary['Type'] != const PdfName('XRef')) {
      throw const PdfException('No cross-reference at its offset');
    }
    _readStream(object, locations);
    return object.dictionary;
  }

  void _readStream(PdfStream stream, Map<int, _Location> locations) {
    final widths = stream.dictionary['W'];
    if (widths is! List<Object?> || widths.length != 3) {
      throw const PdfException('A cross-reference stream without /W');
    }
    final width = [for (final item in widths) item is int ? item : 0];
    final size = stream.dictionary['Size'];
    final index = switch (stream.dictionary['Index']) {
      final List<Object?> pairs => [
        for (final item in pairs)
          if (item is int) item,
      ],
      _ => [0, if (size is int) size else 0],
    };
    final data = bytesOf(stream);
    final row = width[0] + width[1] + width[2];
    var at = 0;
    int field(int length, int fallback) {
      if (length == 0) return fallback;
      var value = 0;
      for (var byte = 0; byte < length; byte++) {
        value = value * 256 + data[at++];
      }
      return value;
    }

    for (var pair = 0; pair + 1 < index.length; pair += 2) {
      for (
        var number = index[pair];
        number < index[pair] + index[pair + 1];
        number++
      ) {
        if (at + row > data.length) return;
        final type = field(width[0], 1);
        final second = field(width[1], 0);
        final third = field(width[2], 0);
        switch (type) {
          case 1:
            locations.putIfAbsent(number, () => _Location.inFile(second));
          case 2:
            locations.putIfAbsent(
              number,
              () => _Location.inStream(second, third),
            );
        }
      }
    }
  }

  static Uint8List _inflate(Uint8List data) {
    try {
      return const ZLibDecoder().decodeBytes(data);
    } on Object {
      throw const PdfException('A stream does not inflate');
    }
  }

  /// [data] after the predictor of [options], which cross-reference streams
  /// use: each row of PNG starts with the filter of its bytes.
  Uint8List _predicted(Uint8List data, Map<String, Object?>? options) {
    int option(String key, int fallback) => switch (options?[key]) {
      final int value => value,
      _ => fallback,
    };
    final predictor = option('Predictor', 1);
    if (predictor < 10) return data;
    final columns = option('Columns', 1);
    final colors = option('Colors', 1);
    final bits = option('BitsPerComponent', 8);
    final pixel = (colors * bits + 7) ~/ 8;
    final width = (columns * colors * bits + 7) ~/ 8;
    final rows = data.length ~/ (width + 1);
    final out = Uint8List(rows * width);
    for (var row = 0; row < rows; row++) {
      final filter = data[row * (width + 1)];
      for (var column = 0; column < width; column++) {
        final raw = data[row * (width + 1) + 1 + column];
        final left = column >= pixel ? out[row * width + column - pixel] : 0;
        final up = row > 0 ? out[(row - 1) * width + column] : 0;
        final upLeft = row > 0 && column >= pixel
            ? out[(row - 1) * width + column - pixel]
            : 0;
        out[row * width + column] =
            switch (filter) {
              1 => raw + left,
              2 => raw + up,
              3 => raw + ((left + up) >> 1),
              4 => raw + _paeth(left, up, upLeft),
              _ => raw,
            } &
            0xff;
      }
    }
    return out;
  }

  static int _paeth(int left, int up, int upLeft) {
    final estimate = left + up - upLeft;
    final toLeft = (estimate - left).abs();
    final toUp = (estimate - up).abs();
    final toUpLeft = (estimate - upLeft).abs();
    if (toLeft <= toUp && toLeft <= toUpLeft) return left;
    return toUp <= toUpLeft ? up : upLeft;
  }

  static bool _startsAt(Uint8List bytes, int at, String word) {
    if (at < 0 || at + word.length > bytes.length) return false;
    for (var index = 0; index < word.length; index++) {
      if (bytes[at + index] != word.codeUnitAt(index)) return false;
    }
    return true;
  }

  static int _indexOf(Uint8List bytes, String word, int from, int to) {
    final last = (to < bytes.length ? to : bytes.length) - word.length;
    for (var at = from < 0 ? 0 : from; at <= last; at++) {
      if (_startsAt(bytes, at, word)) return at;
    }
    return -1;
  }

  static int _lastIndexOf(Uint8List bytes, String word) {
    for (var at = bytes.length - word.length; at >= 0; at--) {
      if (_startsAt(bytes, at, word)) return at;
    }
    return -1;
  }
}
