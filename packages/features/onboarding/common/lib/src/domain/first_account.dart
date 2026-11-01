import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// The account that the onboarding adds.
@immutable
final class FirstAccount {
  /// Creates an account.
  const FirstAccount({
    required this.name,
    required this.type,
    required this.balance,
  });

  /// The name of the account.
  final String name;

  /// The kind of the account.
  final AccountType type;

  /// What it holds, which also says its currency.
  final Money balance;
}
