import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  const answer = '''
  {
    "Date": "2026-10-31T11:30:00+03:00",
    "PreviousDate": "2026-10-30T11:30:00+03:00",
    "Valute": {
      "USD": {"CharCode": "USD", "Nominal": 1, "Name": "Доллар", "Value": 80.5573},
      "KZT": {"CharCode": "KZT", "Nominal": 100, "Value": 17.7552},
      "TRY": {"CharCode": "TRY", "Nominal": 10, "Value": 16.1698},
      "XAU": {"CharCode": "XAU", "Nominal": 1, "Value": 100}
    }
  }
  ''';

  http.Response ok(String body) => http.Response.bytes(utf8.encode(body), 200);

  group('parse', () {
    test('reads the day and the rates', () {
      final rates = CbrMirror.parse(answer);

      expect(rates.day, CivilDate(2026, 10, 31));
      expect(rates.rubles['USD'], Decimal.parse('80.5573'));
      expect(rates.rubles['XAU'], Decimal.fromInt(100));
    });

    test('turns a price for many units into the price of one', () {
      final rates = CbrMirror.parse(answer);

      expect(rates.rubles['KZT'], Decimal.parse('0.177552'));
      expect(rates.rubles['TRY'], Decimal.parse('1.61698'));
    });

    test('skips a currency that it cannot read', () {
      final rates = CbrMirror.parse(
        '{"Date": "2026-10-31T11:30:00+03:00", "Valute": {"USD": {}}}',
      );

      expect(rates.rubles, isEmpty);
    });

    test('refuses an answer of another shape', () {
      expect(() => CbrMirror.parse('{}'), throwsFormatException);
      expect(() => CbrMirror.parse('not json'), throwsFormatException);
    });
  });

  group('latest', () {
    test('reads today', () async {
      Uri? asked;
      final mirror = CbrMirror(
        MockClient((request) async {
          asked = request.url;
          return ok(answer);
        }),
      );

      final rates = await mirror.latest();

      expect(asked.toString(), 'https://www.cbr-xml-daily.ru/daily_json.js');
      expect(rates.day, CivilDate(2026, 10, 31));
    });

    test('fails on an answer that is not the rates', () {
      final mirror = CbrMirror(
        MockClient((_) async => http.Response('down', 503)),
      );

      expect(mirror.latest(), throwsA(isA<http.ClientException>()));
    });
  });

  group('on', () {
    test('reads the archive of the day', () async {
      Uri? asked;
      final mirror = CbrMirror(
        MockClient((request) async {
          asked = request.url;
          return ok(answer);
        }),
      );

      await mirror.on(CivilDate(2026, 3, 5));

      expect(
        asked.toString(),
        'https://www.cbr-xml-daily.ru/archive/2026/03/05/daily_json.js',
      );
    });

    test('a day without rates is no failure', () async {
      final mirror = CbrMirror(
        MockClient((_) async => http.Response('', 404)),
      );

      expect(await mirror.on(CivilDate(2026, 11, 1)), isNull);
    });
  });

  test('a source that hangs gives up', () async {
    final never = MockClient((_) => Completer<http.Response>().future);
    final source = CbrMirror(never, patience: Duration.zero);

    await expectLater(source.latest(), throwsA(isA<TimeoutException>()));
    await expectLater(
      source.on(CivilDate(2026, 10, 31)),
      throwsA(isA<TimeoutException>()),
    );
  });

  group('a failed request for a day', () {
    final failing = MockClient((_) async => throw http.ClientException('lost'));
    final day = CivilDate(2026, 10, 25);

    test('is a failure', () async {
      await expectLater(
        CbrMirror(failing).on(day),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('in a browser is a day without rates', () async {
      expect(await CbrMirror(failing, inBrowser: true).on(day), isNull);
    });

    test('in a browser stays a failure for the latest rates', () async {
      await expectLater(
        CbrMirror(failing, inBrowser: true).latest(),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('that hangs stops the run in a browser too', () async {
      final never = MockClient((_) => Completer<http.Response>().future);
      final source = CbrMirror(
        never,
        patience: Duration.zero,
        inBrowser: true,
      );

      await expectLater(source.on(day), throwsA(isA<TimeoutException>()));
    });
  });
}
