import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:import_common/import_common.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const _reader = FileStatementReader();

Future<StatementTable> _read(Uint8List bytes, [String name = 'file.csv']) =>
    _reader.read(name, bytes);

List<List<String>> _texts(StatementTable table) => [
  for (final row in table.rows) [for (final cell in row.cells) cell.text],
];

Matcher _unreadable(UnreadableReason reason) => throwsA(
  isA<UnreadableFile>().having((error) => error.reason, 'reason', reason),
);

void main() {
  group('CSV', () {
    test('reads Windows-1251 with semicolons and decimal commas', () async {
      final table = await _read(
        windows1251(
          'Дата операции;Описание;Сумма\r\n'
          '03.10.2026;Кофейня «Зерно»;-420,00\r\n'
          '05.10.2026;Аптека №12;-1 180,00\r\n',
        ),
      );
      expect(table.file, TableFile.csv);
      expect(_texts(table), [
        ['Дата операции', 'Описание', 'Сумма'],
        ['03.10.2026', 'Кофейня «Зерно»', '-420,00'],
        ['05.10.2026', 'Аптека №12', '-1 180,00'],
      ]);
    });

    test('reads UTF-8 with a mark and quoted cells', () async {
      final table = await _read(
        utf8WithMark(
          'Date,Description,Amount\n'
          '2026-10-03,"Coffee, ""Zerno""",-4.20\n'
          '2026-10-04,"Two\nlines",-1.00\n'
          '2026-10-05,Taxi,-6.12',
        ),
      );
      expect(_texts(table), [
        ['Date', 'Description', 'Amount'],
        ['2026-10-03', 'Coffee, "Zerno"', '-4.20'],
        ['2026-10-04', 'Two\nlines', '-1.00'],
        ['2026-10-05', 'Taxi', '-6.12'],
      ]);
      expect([for (final row in table.rows) row.line], [1, 2, 3, 4]);
    });

    test('reads UTF-16 and tabs', () async {
      final table = await _read(utf16('Дата\tСумма\n03.10.2026\t-420,00\n'));
      expect(_texts(table), [
        ['Дата', 'Сумма'],
        ['03.10.2026', '-420,00'],
      ]);
    });

    test('takes the separator that Excel names on the first line', () async {
      final table = await _read(
        Uint8List.fromList(utf8.encode('sep=,\nDate;Info,Amount\n1;2,3\n')),
      );
      expect(_texts(table), [
        ['Date;Info', 'Amount'],
        ['1;2', '3'],
      ]);
      expect(table.rows.first.line, 2);
    });

    test('keeps the numbers of rows past blank ones', () async {
      final table = await _read(
        Uint8List.fromList(utf8.encode('Выписка\n\n;\nДата;Сумма\n1;2\n')),
      );
      expect([for (final row in table.rows) row.line], [1, 4, 5]);
    });

    test('has a limit of rows', () async {
      final text = StringBuffer('Date;Amount\n');
      for (var index = 0; index < StatementReader.maxRows; index++) {
        text.writeln('2026-10-03;1');
      }
      await expectLater(
        _read(Uint8List.fromList(utf8.encode(text.toString()))),
        _unreadable(UnreadableReason.tooLarge),
      );
    });
  });

  group('Excel', () {
    test('reads shared, rich and inline strings, numbers and gaps', () async {
      final table = await _read(
        workbook(
          shared: [
            '<t>Дата операции</t>',
            [
              '<r><t>Опи</t></r>',
              '<r><t xml:space="preserve">сание</t></r>',
              '<rPh><t>ヨミ</t></rPh>',
            ].join(),
            '<t>Сумма</t>',
          ],
          rows: [
            [
              '<row r="2">',
              '<c r="A2" t="s"><v>0</v></c>',
              '<c r="B2" t="s"><v>1</v></c>',
              '<c r="D2" t="s"><v>2</v></c>',
              '</row>',
            ],
            [
              '<row r="3">',
              '<c r="A3" t="inlineStr"><is><t>03.10.2026</t></is></c>',
              '<c r="B3" t="str"><f>A1</f><v>Кофе &amp; булка</v></c>',
              '<c r="C3" t="b"><v>1</v></c>',
              '<c r="D3"><v>-420.5</v></c>',
              '</row>',
            ],
            [
              '<row r="5">',
              '<c r="A5"/>',
              '<c r="B5" t="e"><v>#N/A</v></c>',
              '</row>',
            ],
          ],
        ),
        'alfa-2026-10.xlsx',
      );
      expect(table.file, TableFile.xlsx);
      expect(table.rows.map((row) => row.line), [2, 3, 5]);
      expect(table.rows[0].cells.map((cell) => cell.text), [
        'Дата операции',
        'Описание',
        '',
        'Сумма',
      ]);
      expect(table.rows[1].cells, [
        const Cell.text('03.10.2026'),
        const Cell.text('Кофе & булка'),
        const Cell.text('TRUE'),
        const Cell.number('-420.5'),
      ]);
      expect(table.rows[2].cells, [Cell.empty, const Cell.text('#N/A')]);
    });

    test('turns numbers in the formats of dates into dates', () async {
      final table = await _read(
        workbook(
          formats: {164: 'dd.mm.yyyy hh:mm', 165: r'#,##0.00\ "руб."'},
          styles: [0, 14, 164, 165],
          rows: [
            [
              '<row r="1">',
              '<c r="A1" s="1"><v>46298</v></c>',
              '<c r="B1" s="2"><v>46298.598611111112</v></c>',
              '<c r="C1" s="3"><v>-2340.5</v></c>',
              '<c r="D1" s="2"><v>0.5</v></c>',
              '</row>',
            ],
          ],
        ),
      );
      expect(table.rows.single.cells, [
        const Cell.date('2026-10-03'),
        const Cell.date('2026-10-03T14:22:00'),
        const Cell.number('-2340.5'),
        const Cell.text('12:00:00'),
      ]);
    });

    test('counts days from 1904 in old Mac workbooks', () async {
      final table = await _read(
        workbook(
          since1904: true,
          styles: [14],
          rows: [
            ['<row r="1">', '<c r="A1"><v>44836</v></c>', '</row>'],
          ],
        ),
      );
      expect(table.rows.single.cells.single, const Cell.date('2026-10-03'));
    });

    test('finds the first sheet by its relation', () async {
      final table = await _read(
        workbook(
          sheetPath: 'worksheets/statement.xml',
          rows: [
            [
              '<row r="1">',
              '<c r="A1" t="inlineStr"><is><t>Да</t></is></c>',
              '</row>',
            ],
          ],
        ),
      );
      expect(table.rows.single.cells.single.text, 'Да');
    });

    test('fails on a broken or foreign archive', () async {
      await expectLater(
        _read(Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 1, 2, 3])),
        _unreadable(UnreadableReason.damaged),
      );
      final document = ZipEncoder().encodeBytes(
        Archive()..add(ArchiveFile.string('word/document.xml', '<w/>')),
      );
      await expectLater(
        _read(document),
        _unreadable(UnreadableReason.notATable),
      );
    });
  });

  test('tells a PDF, a picture and an empty file from a table', () async {
    await expectLater(
      _read(Uint8List.fromList(utf8.encode('%PDF-1.7 ...'))),
      _unreadable(UnreadableReason.pdf),
    );
    await expectLater(
      _read(Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a])),
      _unreadable(UnreadableReason.notATable),
    );
    await expectLater(
      _read(Uint8List.fromList([0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1])),
      _unreadable(UnreadableReason.notATable),
    );
    await expectLater(
      _read(Uint8List.fromList(utf8.encode('<html><table>'))),
      _unreadable(UnreadableReason.notATable),
    );
    await expectLater(_read(Uint8List(0)), _unreadable(UnreadableReason.empty));
    await expectLater(
      _read(Uint8List.fromList(utf8.encode('\n\n;;\n'))),
      _unreadable(UnreadableReason.empty),
    );
  });
}
