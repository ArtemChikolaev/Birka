import 'package:accounts_common/accounts_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

/// The art of the design system for [art] of an account.
CardArt cardArtOf(AccountArt art) => CardArt.values.byName(art.name);

/// The name of [type].
String typeLabel(AccountType type) => t.accounts.types[type.name] ?? type.name;

/// The quiet line of an account: `Рубли · •• 4568` or `Рубли · Вклад`.
String accountSubtitle({
  required Currency currency,
  required AccountType type,
  String? lastDigits,
}) {
  final name = t.app.currencies[currency.code] ?? currency.code;
  final detail = lastDigits == null || lastDigits.isEmpty
      ? typeLabel(type)
      : '•• $lastDigits';
  return '$name · $detail';
}
