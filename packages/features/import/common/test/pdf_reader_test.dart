import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:import_common/import_common.dart';
import 'package:import_common/src/data/pdf/pdf_document.dart';
import 'package:import_common/src/data/pdf/pdf_syntax.dart';
import 'package:import_common/src/data/pdf/pdf_text.dart';
import 'package:import_common/src/data/pdf/sber_statement.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:test/test.dart';

import 'pdf_fixtures.dart';

Object? _parse(String text) =>
    PdfParser(Uint8List.fromList(latin1.encode(text))).next();

Matcher _unreadable(UnreadableReason reason) => throwsA(
  isA<UnreadableFile>().having((error) => error.reason, 'reason', reason),
);

/// The texts of the lines of [pdf], each with the positions of its runs.
List<String> _lines(Uint8List pdf) => [
  for (final line in textLines(PdfDocument.parse(pdf)))
    '${line.page} ${line.runs.map(_run).join(' | ')}',
];

String _run(PdfTextRun run) => '${run.x.round()},${run.y.round()} ${run.text}';

/// The first page of a statement of Sberbank, as its PDF lays it out.
String _sberFirstPage({
  String received = '+5 100,00',
  String spent = '3 099,00',
}) => [
  place(171, 813.9, '900'),
  place(191, 813.9, 'www.sberbank.ru'),
  place(452, 813.9, 'Заказано в СберБанк Онлайн'),
  place(45, 761.7, 'Индивидуальная выписка по счёту дебетовой карты'),
  place(349, 711.8, 'ИТОГО ПО ОПЕРАЦИЯМ ЗА ПЕРИОД:'),
  place(349, 686.9, 'Пополнение'),
  place(506, 686.9, received),
  place(349, 672.9, 'Списание'),
  place(510, 672.9, spent),
  place(57, 668.9, 'Номер счёта'),
  place(195, 668.9, '40817 810 0 0000 0000000'),
  place(57, 654.9, 'Карта'),
  place(195, 654.9, 'МИР Классическая •••• 1234'),
  place(57, 640.9, 'Валюта'),
  place(195, 640.9, 'Российский рубль'),
  place(45, 527.6, 'Расшифровка операций'),
  place(45, 501.9, 'ДАТА ОПЕРАЦИИ (МСК)'),
  place(145, 501.9, 'КАТЕГОРИЯ'),
  place(469, 501.9, 'СУММА В ВАЛЮТЕ СЧЁТА'),
  place(45, 486.9, 'Дата обработки'),
  place(145, 486.9, 'Описание операции'),
  // The first operation: a fee of the bank.
  place(45, 451.9, '13.08.2026'),
  place(96, 451.9, '09:25'),
  place(145, 451.9, 'Прочие операции'),
  place(541, 451.9, '99,00'),
  place(45, 440.9, '13.08.2026'),
  place(96, 440.9, '203688'),
  place(145, 440.9, 'MOBILE BANK: KOMISSIYA. Операция по карте ****1234'),
  // Money received.
  place(45, 423.9, '13.08.2026'),
  place(96, 423.9, '09:20'),
  place(145, 423.9, 'Перевод СБП', hex: true),
  place(532, 423.9, '+100,00'),
  place(45, 412.9, '13.08.2026'),
  place(96, 412.9, '072239'),
  place(145, 412.9, 'Т-Банк. Операция по карте ****1234'),
  // A transfer whose amount holds a fee.
  place(45, 395.9, '12.08.2026'),
  place(96, 395.9, '18:02'),
  place(145, 395.9, 'Перевод с карты'),
  place(526, 395.9, '3 000,00'),
  place(45, 384.9, '12.08.2026'),
  place(96, 384.9, '814221'),
  place(145, 384.9, 'SBOL. Операция по карте ****1234'),
  place(145, 374.5, 'В сумму операции включена комиссия 30,00 руб.'),
  // The first line of an operation whose second line is on the next page.
  place(45, 132.9, '10.08.2026'),
  place(96, 132.9, '21:21'),
  place(145, 132.9, 'Внесение наличных'),
  place(526, 132.9, '+5 000,00'),
  place(236, 102.9, 'Продолжение на следующей странице'),
  place(111, 59.9, '1. Сноска о дате обработки'),
].join();

String _sberSecondPage() => [
  place(45, 819.9, 'Индивидуальная выписка по счёту дебетовой карты'),
  place(501, 819.9, 'Страница 2 из 2'),
  place(45, 795.9, 'ДАТА ОПЕРАЦИИ (МСК)'),
  place(145, 795.9, 'КАТЕГОРИЯ'),
  place(45, 780.9, 'Дата обработки'),
  place(45, 745.9, '10.08.2026'),
  place(96, 745.9, '111111'),
  place(145, 745.9, 'Банкомат №60014946. Операция по карте ****1234'),
  place(45, 120.9, 'Дата формирования документа 04.11.2026'),
].join();

void main() {
  group('the syntax of PDF', () {
    test('reads numbers, names, booleans and references', () {
      expect(_parse('42'), 42);
      expect(_parse('-3.5'), -3.5);
      expect(_parse('.5'), 0.5);
      expect(_parse('/Type'), const PdfName('Type'));
      expect(_parse('/A#20B'), const PdfName('A B'));
      expect(_parse('true'), isTrue);
      expect(_parse('null'), isNull);
      expect(_parse('12 0 R'), const PdfRef(12, 0));
      expect(_parse('[1 0 0 RG]'), [1, 0, 0, const PdfKeyword('RG')]);
      expect(_parse('% a comment\n7'), 7);
    });

    test('reads literal strings with their escapes', () {
      const input = '${r'(a (b) \(c\) \\ \n\053\7 d\'}\ne)';
      final string = _parse(input)! as PdfString;
      expect(string.bytes, [
        ...'a (b) (c) \\ \n+'.codeUnits,
        7,
        ...' de'.codeUnits,
      ]);
      expect((_parse('(a\r\nb)')! as PdfString).bytes, 'a\nb'.codeUnits);
    });

    test('reads hex strings, arrays and dictionaries', () {
      expect((_parse('<48 65 6C6c 6>')! as PdfString).bytes, [
        0x48,
        0x65,
        0x6c,
        0x6c,
        0x60,
      ]);
      expect(_parse('<< /Kids [1 0 R 2 0 R] /Count 2 /Sub << /A (x) >> >>'), {
        'Kids': [const PdfRef(1, 0), const PdfRef(2, 0)],
        'Count': 2,
        'Sub': {'A': isA<PdfString>()},
      });
    });
  });

  group('a PDF document', () {
    final pages = [
      place(45, 700, 'Первая страница'),
      place(45, 700, 'Вторая (страница)'),
    ];

    for (final (name, pdf) in [
      ('in object streams', pdfOf(pages)),
      ('with a predictor', pdfOf(pages, predictor: true)),
      ('with a table of references', pdfOf(pages, classic: true)),
      ('with a wrong length of a stream', pdfOf(pages, wrongLength: true)),
    ]) {
      test('reads its pages $name', () {
        final document = PdfDocument.parse(pdf);
        expect(document.pages, hasLength(2));
        expect(_lines(pdf), [
          '0 45,700 Первая страница',
          '1 45,700 Вторая (страница)',
        ]);
      });
    }

    test('refuses an encrypted file and a broken one', () {
      expect(
        () => PdfDocument.parse(pdfOf(pages, encrypted: true)),
        throwsA(isA<PdfException>()),
      );
      expect(
        () => PdfDocument.parse(pdfOf(pages, classic: true, encrypted: true)),
        throwsA(isA<PdfException>()),
      );
      expect(
        () => PdfDocument.parse(Uint8List.fromList(latin1.encode('%PDF-1.7'))),
        throwsA(isA<PdfException>()),
      );
    });
  });

  group('the text of a page', () {
    test('stands where the matrices put it', () {
      final pdf = pdfOf([
        [
          'BT /F1 8 Tf 1 0 0 1 100 500 Tm ⟦Начало⟧ Tj',
          '20 -10 Td ⟦ниже⟧ Tj',
          '12 TL T* ⟦ещё ниже⟧ Tj',
          '0 -12 TD ⟦и ещё⟧ Tj T* ⟦последняя⟧ Tj ET',
          'q 1 0 0 1 10 20 cm BT /F1 8 Tf 1 0 0 1 300 600 Tm ⟦сдвиг⟧ Tj ET Q',
          'BT /F1 8 Tf 1 0 0 1 300 400 Tm ⟦без сдвига⟧ Tj ET',
        ].join('\n'),
      ]);
      expect(_lines(pdf), [
        '0 310,620 сдвиг',
        '0 100,500 Начало',
        '0 120,490 ниже',
        '0 120,478 ещё ниже',
        '0 120,466 и ещё',
        '0 120,454 последняя',
        '0 300,400 без сдвига',
      ]);
    });

    test('joins what follows without a move and spaces out wide gaps', () {
      final pdf = pdfOf([
        [
          'BT /F1 8 Tf 1 0 0 1 50 300 Tm ⟦Опер⟧ Tj ⟦ация⟧ Tj ET',
          'BT /F1 8 Tf 1 0 0 1 50 280 Tm [⟦по⟧ -30 ⟦карте⟧ -400 ⟦1234⟧] TJ ET',
          'BT /F1 8 Tf 1 0 0 1 200 300.8 Tm ⟪рядом⟫ Tj ET',
        ].join('\n'),
      ]);
      expect(_lines(pdf), [
        '0 50,300 Операция | 200,301 рядом',
        '0 50,280 покарте 1234',
      ]);
    });
  });

  group('a statement of Sberbank', () {
    Future<StatementTable> read(Uint8List pdf) =>
        const FileStatementReader().read('выписка.pdf', pdf);

    test('becomes a table of one row for each operation', () async {
      final table = await read(pdfOf([_sberFirstPage(), _sberSecondPage()]));
      expect(table.file, TableFile.pdf);
      expect(table.rows.map((row) => row.line), [0, 1, 2, 3, 4]);
      expect(table.rows[3].cells.map((cell) => cell.text), [
        '12.08.2026 18:02',
        '12.08.2026',
        '814221',
        'Перевод с карты',
        'SBOL. Операция по карте ****1234',
        '2970,00',
        '',
        '30,00',
        'RUB',
        'МИР Классическая •••• 1234',
      ]);
      expect(
        table.rows[4].cells[4].text,
        'Банкомат №60014946. Операция по карте ****1234',
      );
    });

    test(
      'reads money spent without a sign and money received with one',
      () async {
        final table = await read(pdfOf([_sberFirstPage(), _sberSecondPage()]));
        final layout = detectLayout(table);
        expect(layout.format, sber);
        expect(layout.known, sberHeaders.length);
        expect(layout.options.sign, AmountSign.incomePlus);
        final statement = readStatement(table, layout);
        expect(statement.problems, isEmpty);
        final [cash, transfer, received, fee] = statement.rows;
        expect(cash.into!.amount, Decimal.parse('5000'));
        expect(cash.date.day, CivilDate(2026, 8, 10));
        expect(transfer.out!.amount, Decimal.parse('2970'));
        expect(transfer.fee, Decimal.parse('30'));
        expect(transfer.change, Decimal.parse('-3000'));
        expect(received.into!.amount, Decimal.parse('100'));
        expect(received.category, 'Перевод СБП');
        expect(fee.out!.amount, Decimal.parse('99'));
        expect(fee.date.time, const Duration(hours: 9, minutes: 25));
        final account = statement.accounts.single;
        expect(account.currency, 'RUB');
        expect(account.cards, {'1234'});
        expect(account.received, Decimal.parse('5100'));
        expect(account.spent, Decimal.parse('3099'));
      },
    );

    test('is refused when its operations miss its totals', () async {
      await expectLater(
        read(pdfOf([_sberFirstPage(spent: '4 099,00'), _sberSecondPage()])),
        _unreadable(UnreadableReason.incomplete),
      );
    });

    test('is the only PDF that reads for now', () async {
      await expectLater(
        read(pdfOf([place(45, 700, 'Справка о движении средств')])),
        _unreadable(UnreadableReason.pdf),
      );
      await expectLater(
        read(pdfOf([_sberFirstPage()], encrypted: true)),
        _unreadable(UnreadableReason.pdf),
      );
    });
  });
}
