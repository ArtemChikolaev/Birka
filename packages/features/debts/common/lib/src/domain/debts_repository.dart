import 'package:debts_common/src/domain/debt.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// What the debts need of the ledger, the rates and the device (ADR 0029).
abstract interface class DebtsRepository {
  /// Today on the calendar of this device.
  CivilDate today();

  /// The debts that have anything to show, again after every change.
  Stream<List<Debt>> watchDebts();

  /// The accounts of the person that money of a debt can go from or to, with
  /// what each holds: neither archived ones nor debts.
  Stream<List<AccountBalance>> watchAccounts();

  /// The rates that are known.
  Stream<RateBook> watchRates();

  /// The currency that totals are in, or `null` to follow the first account
  /// in the totals.
  Stream<Currency?> watchBaseCurrency();

  /// The currency of the first account in the totals.
  Stream<Currency?> watchMainCurrency();

  /// Moves [amount] between account [accountId] of the person and the debt
  /// of [name] on [side]: out of the account when the person lends, into it
  /// when they borrow. The debt of [debtId] takes it, or else the debt of
  /// that name and side, or else a new one in the currency of [amount].
  /// [terms] replace those of the debt when given. Gives the id of the debt.
  Future<String> open({
    required String name,
    required DebtSide side,
    required String accountId,
    required Money amount,
    required CivilDate day,
    String? debtId,
    String note = '',
    DebtTerms? terms,
  });

  /// Moves [amount] that settles debt [debtId] between it and account
  /// [accountId] of the person: in when the other one gives back, out when
  /// the person does.
  Future<void> settle(
    String debtId, {
    required String accountId,
    required Money amount,
    required CivilDate day,
  });

  /// Gives debt [debtId] the name [name] and the terms [terms].
  Future<void> update(
    String debtId, {
    required String name,
    required DebtTerms terms,
  });
}
