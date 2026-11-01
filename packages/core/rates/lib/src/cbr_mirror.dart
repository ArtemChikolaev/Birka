import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:rates/src/rate_source.dart';
import 'package:rational/rational.dart';

/// The rates of the Bank of Russia from cbr-xml-daily.ru, which a browser can
/// read too: cbr.ru itself answers no other site (ADR 0012).
final class CbrMirror implements RateSource {
  /// Creates a source that reads through [_client]. The service sometimes
  /// takes its time, and a request gives up after [patience]. [inBrowser] says
  /// that the client runs in a browser, where a day without rates looks like a
  /// lost connection.
  const CbrMirror(
    this._client, {
    Duration patience = const Duration(seconds: 15),
    bool inBrowser = false,
  }) : _patience = patience,
       _inBrowser = inBrowser;

  /// Where the rates come from, which the terms of the service ask us to link.
  static const address = 'https://www.cbr-xml-daily.ru/';

  final http.Client _client;
  final Duration _patience;
  final bool _inBrowser;

  /// Nominals are powers of ten, so this is only a guard.
  static const _digits = 8;

  @override
  Future<DayRates> latest() async {
    return _read(await _get('daily_json.js'));
  }

  @override
  Future<DayRates?> on(CivilDate day) async {
    final path = day.toString().replaceAll('-', '/');
    final http.Response response;
    try {
      response = await _get('archive/$path/daily_json.js');
    } on http.ClientException {
      // The mirror sends its 404 with no CORS header, so a browser reports it
      // as a failed request and hides the status.
      if (_inBrowser) return null;
      rethrow;
    }
    return response.statusCode == 404 ? null : _read(response);
  }

  Future<http.Response> _get(String path) =>
      _client.get(Uri.parse('$address$path')).timeout(_patience);

  DayRates _read(http.Response response) {
    if (response.statusCode != 200) {
      throw http.ClientException(
        'The rates answered ${response.statusCode}',
        response.request?.url,
      );
    }
    return parse(utf8.decode(response.bodyBytes, allowMalformed: true));
  }

  /// Reads the rates out of the [body] of an answer. Throws a
  /// [FormatException] if it holds anything else.
  static DayRates parse(String body) {
    if (jsonDecode(body) case {
      'Date': final String date,
      'Valute': final Map<String, Object?> currencies,
    }) {
      return DayRates(CivilDate.parse(date.substring(0, 10)), {
        for (final MapEntry(key: code, :value) in currencies.entries)
          if (value case {
            'Nominal': final int units,
            'Value': final num rubles,
          })
            code: _perUnit(rubles, units),
      });
    }
    throw const FormatException('Not the rates of a day');
  }

  /// A price for [units] units, turned into a price of one.
  static Decimal _perUnit(num rubles, int units) {
    final price = Decimal.parse('$rubles').toRational();
    return (price / Rational(BigInt.from(units))).toDecimal(
      scaleOnInfinitePrecision: _digits,
    );
  }
}
