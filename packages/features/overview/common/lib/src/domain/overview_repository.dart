import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Where the first screen reads what it shows.
abstract interface class OverviewRepository {
  /// The accounts in everyday use with their balances, in their order.
  Stream<List<AccountBalance>> watchAccounts();

  /// The kept exchange rates.
  Stream<RateBook> watchRates();

  /// The currency picked for totals, if one was.
  Stream<Currency?> watchBaseCurrency();

  /// What each day since [from] changed the accounts that count.
  Stream<List<DayChange>> watchDayChanges({required CivilDate from});

  /// What went through the categories of expenses on each day from [from] to
  /// [to].
  Stream<List<CategoryDayTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  });
}
