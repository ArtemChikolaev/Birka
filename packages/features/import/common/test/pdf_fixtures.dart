import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Text in a page of [pdfOf] between these marks goes into the PDF as a literal
/// string in the codes of its font.
const literalOpen = '⟦';

/// The end of a literal string.
const literalClose = '⟧';

/// Text between these marks goes in as a hex string.
const hexOpen = '⟪';

/// The end of a hex string.
const hexClose = '⟫';

/// What a page shows with `BT … Tm … Tj ET` at [x] and [y], in the font of
/// the page.
String place(double x, double y, String text, {bool hex = false}) =>
    'BT /F1 8 Tf 1 0 0 1 $x $y Tm '
    '${hex ? hexOpen : literalOpen}$text${hex ? hexClose : literalClose} '
    'Tj ET\n';

/// A PDF for tests, made the way a reporting library makes the statement of
/// a bank: pages under a tree of two levels that hands down the font, a
/// composite font whose two-byte codes map to Unicode through a ToUnicode
/// CMap of `bfchar` and `bfrange` entries, and the objects in an object
/// stream with the cross-reference in a stream.
///
/// [pages] are content streams in which text between the marks above becomes
/// strings of the font. The first codes are those of `(`, `)`, `\` and CR,
/// so that literal strings need their escapes. [classic] writes a
/// cross-reference table and no object stream instead, [predictor] runs the
/// cross-reference stream through the PNG predictor Up, [encrypted] names a
/// dictionary of encryption in the trailer, and [wrongLength] gives the
/// content of the first page a wrong length.
Uint8List pdfOf(
  List<String> pages, {
  bool classic = false,
  bool predictor = false,
  bool encrypted = false,
  bool wrongLength = false,
}) {
  final mark = RegExp('[$literalOpen$hexOpen](.*?)[$literalClose$hexClose]');
  final characters = <int>{
    for (final page in pages)
      for (final match in mark.allMatches(page)) ...match[1]!.runes,
  }.toList();
  const special = [0x0028, 0x0029, 0x005c, 0x000d];
  final codes = <int, int>{
    for (final (index, character) in characters.indexed)
      character: index < special.length ? special[index] : 0x0100 + index,
  };

  String encoded(Match match) {
    final hex = match[0]!.startsWith(hexOpen);
    final bytes = [
      for (final character in match[1]!.runes) ...[
        codes[character]! >> 8,
        codes[character]! & 0xff,
      ],
    ];
    if (hex) {
      final digits = bytes.map(
        (byte) => byte.toRadixString(16).padLeft(2, '0'),
      );
      return '<${digits.join()}>';
    }
    final text = StringBuffer('(');
    for (final byte in bytes) {
      text.write(switch (byte) {
        0x28 || 0x29 || 0x5c => '\\${String.fromCharCode(byte)}',
        0x0d => r'\r',
        _ => String.fromCharCode(byte),
      });
    }
    text.write(')');
    return text.toString();
  }

  final contents = [
    for (final page in pages) page.replaceAllMapped(mark, encoded),
  ];
  String hex4(int value) => value.toRadixString(16).padLeft(4, '0');
  final entries = codes.entries.toList();
  final half = entries.length ~/ 2;
  final cmap = StringBuffer()
    ..writeln('/CIDInit /ProcSet findresource begin 12 dict begin begincmap')
    ..writeln('/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) >> def')
    ..writeln('1 begincodespacerange <0000> <FFFF> endcodespacerange')
    ..writeln('$half beginbfchar');
  for (final entry in entries.take(half)) {
    cmap.writeln('<${hex4(entry.value)}> <${hex4(entry.key)}>');
  }
  cmap
    ..writeln('endbfchar')
    ..writeln('${entries.length - half} beginbfrange');
  for (final entry in entries.skip(half)) {
    // Every other entry as an array, to read both forms.
    final code = '<${hex4(entry.value)}> <${hex4(entry.value)}>';
    final target = '<${hex4(entry.key)}>';
    cmap.writeln(
      entries.indexOf(entry).isEven ? '$code $target' : '$code [$target]',
    );
  }
  cmap.writeln(
    'endbfrange endcmap CMapName currentdict /CMap defineresource pop end end',
  );

  // The objects: 1 catalog, 2 and 3 pages, 4 font, 5 its CID font, 6 its map,
  // then a dictionary and a content stream for each page.
  final count = pages.length;
  final dictionaries = <int, String>{
    1: '<< /Type /Catalog /Pages 2 0 R >>',
    2: '<< /Type /Pages /Kids [3 0 R] /Count $count >>',
    3:
        '<< /Type /Pages /Parent 2 0 R /Count $count '
        '/Kids [${[for (var i = 0; i < count; i++) '${7 + 2 * i} 0 R'].join(' ')}] '
        '/Resources << /Font << /F1 4 0 R >> >> >>',
    4:
        '<< /Type /Font /Subtype /Type0 /BaseFont /TestSans '
        '/Encoding /Identity-H /DescendantFonts [5 0 R] /ToUnicode 6 0 R >>',
    5:
        '<< /Type /Font /Subtype /CIDFontType2 /BaseFont /TestSans '
        '/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> >>',
    for (var i = 0; i < count; i++)
      7 + 2 * i:
          '<< /Type /Page /Parent 3 0 R /Contents ${8 + 2 * i} 0 R '
          '/MediaBox [0 0 595 842] >>',
  };
  final streams = <int, Uint8List>{
    6: const ZLibEncoder().encodeBytes(utf8.encode(cmap.toString())),
    for (var i = 0; i < count; i++)
      8 + 2 * i: const ZLibEncoder().encodeBytes(latin1.encode(contents[i])),
  };

  final out = BytesBuilder();
  void write(String text) => out.add(latin1.encode(text));
  final offsets = <int, int>{};
  write('%PDF-1.5\n');
  // A comment of high bytes says that the file is binary.
  out.add(const [0x25, 0xe2, 0xe3, 0xcf, 0xd3, 0x0a]);
  void stream(int number, Map<String, Object> extra, Uint8List data) {
    offsets[number] = out.length;
    final length = wrongLength && number == 8 ? data.length + 7 : data.length;
    write('$number 0 obj\n<< /Length $length /Filter /FlateDecode');
    for (final MapEntry(:key, :value) in extra.entries) {
      write(' /$key $value');
    }
    write(' >>\nstream\n');
    out.add(data);
    write('\nendstream\nendobj\n');
  }

  for (final MapEntry(key: number, value: data) in streams.entries) {
    stream(number, const {}, data);
  }
  var size = 7 + 2 * count;
  final inStream = <int, int>{};
  if (classic) {
    for (final MapEntry(key: number, value: text) in dictionaries.entries) {
      offsets[number] = out.length;
      write('$number 0 obj\n$text\nendobj\n');
    }
  } else {
    final objectStream = size++;
    final header = StringBuffer();
    final body = StringBuffer();
    for (final (index, MapEntry(key: number, value: text))
        in dictionaries.entries.indexed) {
      header.write('$number ${body.length} ');
      body.write('$text\n');
      inStream[number] = index;
    }
    final first = header.length;
    stream(
      objectStream,
      {'Type': '/ObjStm', 'N': dictionaries.length, 'First': first},
      const ZLibEncoder().encodeBytes(latin1.encode('$header$body')),
    );
    final xref = size++;
    final rows = <List<int>>[
      for (var number = 0; number < size; number++)
        if (number == 0)
          [0, 0, 0, 0, 0xff, 0xff]
        else if (inStream.containsKey(number))
          [
            2,
            0,
            objectStream >> 8 & 0xff,
            objectStream & 0xff,
            0,
            inStream[number]!,
          ]
        else if (number == xref)
          [
            1,
            ...[
              out.length >> 16 & 0xff,
              out.length >> 8 & 0xff,
              out.length & 0xff,
            ],
            0,
            0,
          ]
        else
          [
            1,
            offsets[number]! >> 16 & 0xff,
            offsets[number]! >> 8 & 0xff,
            offsets[number]! & 0xff,
            0,
            0,
          ],
    ];
    final raw = <int>[];
    for (final (index, row) in rows.indexed) {
      if (!predictor) {
        raw.addAll(row);
        continue;
      }
      raw.add(2);
      for (var column = 0; column < row.length; column++) {
        final up = index == 0 ? 0 : rows[index - 1][column];
        raw.add((row[column] - up) & 0xff);
      }
    }
    final start = out.length;
    stream(xref, {
      'Type': '/XRef',
      'Size': size,
      'W': '[1 3 2]',
      'Root': '1 0 R',
      if (predictor) 'DecodeParms': '<< /Predictor 12 /Columns 6 >>',
      if (encrypted) 'Encrypt': '<< /Filter /Standard >>',
    }, const ZLibEncoder().encodeBytes(raw));
    write('startxref\n$start\n%%EOF\n');
    return out.takeBytes();
  }
  final start = out.length;
  write('xref\n0 $size\n0000000000 65535 f \n');
  for (var number = 1; number < size; number++) {
    final offset = offsets[number];
    write(
      offset == null
          ? '0000000000 65535 f \n'
          : '${offset.toString().padLeft(10, '0')} 00000 n \n',
    );
  }
  write('trailer\n<< /Size $size /Root 1 0 R');
  if (encrypted) write(' /Encrypt << /Filter /Standard >>');
  write(' >>\nstartxref\n$start\n%%EOF\n');
  return out.takeBytes();
}
