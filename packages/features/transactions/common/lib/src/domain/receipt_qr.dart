import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What the QR code of a Russian fiscal receipt says (ADR 0032): when it was
/// paid, how much, and which receipt of which till it is. The code holds no
/// items and no shop, so neither does this.
///
/// The code is a query string such as
/// `t=20261118T0912&s=620.00&fn=7380440700076541&i=24611&fp=2531297412&n=1`:
/// the moment, the sum in rubles, the fiscal drive, the number of the
/// document, its fiscal sign and the kind of the receipt.
@immutable
final class ReceiptQr {
  /// Creates what a code says.
  const ReceiptQr({required this.at, required this.sum, required this.receipt});

  /// Reads [text], or gives `null` when it is not the code of a receipt. A
  /// link that carries the same query after `?` reads too, and a code
  /// without the kind is a sale, as receipts printed before the kind came
  /// were.
  static ReceiptQr? parse(String text) {
    final trimmed = text.trim();
    final start = trimmed.indexOf('?');
    final query = start < 0 ? trimmed : trimmed.substring(start + 1);
    final fields = <String, String>{};
    for (final part in query.split('&')) {
      final equals = part.indexOf('=');
      if (equals <= 0) continue;
      // Every value of a receipt is digits, a point or a T, so nothing in it
      // is ever escaped.
      fields[part.substring(0, equals).trim().toLowerCase()] = part
          .substring(equals + 1)
          .trim();
    }
    final at = _moment(fields['t']);
    final sum = _sum(fields['s']);
    final drive = _number(fields['fn']);
    final document = _number(fields['i']);
    final sign = _number(fields['fp']);
    final kind = _kind(fields['n']);
    if (at == null ||
        sum == null ||
        drive == null ||
        document == null ||
        sign == null ||
        kind == null) {
      return null;
    }
    return ReceiptQr(
      at: at,
      sum: sum,
      receipt: Receipt(
        drive: drive,
        document: document,
        sign: sign,
        kind: kind,
      ),
    );
  }

  /// When it was paid, as the clock of the till showed it.
  final DateTime at;

  /// How much, in rubles.
  final Money sum;

  /// Which receipt it is.
  final Receipt receipt;

  @override
  bool operator ==(Object other) =>
      other is ReceiptQr &&
      other.at == at &&
      other.sum == sum &&
      other.receipt == receipt;

  @override
  int get hashCode => Object.hash(at, sum, receipt);
}

final _momentPattern = RegExp(
  r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})?$',
);
final _sumPattern = RegExp(r'^(\d{1,12})(?:[.,](\d{1,2}))?$');
final _numberPattern = RegExp(r'^\d{1,20}$');

/// `yyyyMMddTHHmm`, with the seconds or without.
DateTime? _moment(String? text) {
  final match = _momentPattern.firstMatch(text ?? '');
  if (match == null) return null;
  final [year, month, day, hour, minute] = [
    for (var group = 1; group <= 5; group++) int.parse(match[group]!),
  ];
  final second = int.parse(match[6] ?? '0');
  if (hour > 23 || minute > 59 || second > 59) return null;
  final moment = DateTime(year, month, day, hour, minute, second);
  // DateTime rolls 31 November into December; a receipt never says it.
  if (moment.month != month || moment.day != day) return null;
  return moment;
}

/// Rubles, with up to two digits of kopecks after a point.
Money? _sum(String? text) {
  final match = _sumPattern.firstMatch(text ?? '');
  if (match == null) return null;
  final kopecks = int.parse((match[2] ?? '0').padRight(2, '0'));
  final minorUnits = int.parse(match[1]!) * 100 + kopecks;
  return minorUnits > 0 ? Money(minorUnits, Currency.rub) : null;
}

String? _number(String? text) =>
    text != null && _numberPattern.hasMatch(text) ? text : null;

ReceiptKind? _kind(String? text) => switch (text) {
  null || '1' => ReceiptKind.sale,
  '2' => ReceiptKind.saleReturn,
  '3' => ReceiptKind.payout,
  '4' => ReceiptKind.payoutReturn,
  _ => null,
};
