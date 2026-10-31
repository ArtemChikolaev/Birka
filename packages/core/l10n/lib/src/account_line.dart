import 'package:l10n/src/generated/strings.g.dart';

/// The quiet line of an account: `Рубли · •• 4568` or `Рубли · Вклад`. [type]
/// is the name of the type of the account.
String accountLine({
  required String currency,
  required String type,
  String? lastDigits,
}) {
  final name = t.app.currencies[currency] ?? currency;
  final detail = lastDigits == null || lastDigits.isEmpty
      ? t.accounts.types[type] ?? type
      : '•• $lastDigits';
  return '$name · $detail';
}
