import 'package:meta/meta.dart';

/// What a fiscal receipt says happened, from the side of the seller, as the
/// tag `n` of its QR code gives it (ADR 0032).
enum ReceiptKind {
  /// «Приход»: the person paid the seller. It is spending.
  sale,

  /// «Возврат прихода»: the seller gave the money of a sale back.
  saleReturn,

  /// «Расход»: the seller paid the person, such as for things bought from
  /// them.
  payout,

  /// «Возврат расхода»: the person gave such money back.
  payoutReturn
  ;

  /// Whether the money left the person, so that the receipt is an expense
  /// for them; otherwise it is an income.
  bool get spends => this == sale || this == payoutReturn;
}

/// The fiscal receipt that a transaction was made from (ADR 0032).
///
/// The fiscal drive, the number of the document and the fiscal sign name one
/// receipt of a till, so that the same receipt is never recorded twice; the
/// drive alone names the till, which Birka learns the category of.
@immutable
final class Receipt {
  /// Creates a receipt.
  const Receipt({
    required this.drive,
    required this.document,
    required this.sign,
    required this.kind,
  });

  /// The number of the fiscal drive («ФН») of the till that printed it.
  final String drive;

  /// The number of the fiscal document («ФД»).
  final String document;

  /// The fiscal sign of the document («ФП»).
  final String sign;

  /// What it says happened.
  final ReceiptKind kind;

  /// Whether [other] is the same receipt, whatever kind it says.
  bool sameAs(Receipt other) =>
      drive == other.drive && document == other.document && sign == other.sign;

  @override
  bool operator ==(Object other) =>
      other is Receipt && sameAs(other) && kind == other.kind;

  @override
  int get hashCode => Object.hash(drive, document, sign, kind);

  @override
  String toString() => 'Receipt($drive, $document, $sign, ${kind.name})';
}
