import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// What the limits of categories are counted from (ADR 0033).
abstract interface class LimitsRepository {
  /// Today on this device.
  CivilDate today();

  /// The day the month starts on, from the settings (ADR 0024).
  Stream<int> watchMonthStart();

  /// The categories of expenses that are not archived, with their limits.
  Stream<List<Category>> watchCategories();

  /// The expenses from [from] to [to] by top category and day, in the
  /// currencies of their accounts.
  Stream<List<CategoryDayTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  });

  /// The rates of the Bank of Russia by day.
  Stream<RateBook> watchRates();

  /// The currency totals are shown in: the base currency, else that of the
  /// first account in the totals, else rubles.
  Stream<Currency> watchShownCurrency();

  /// The categories that regular payments go to.
  Stream<Set<String>> watchRegular();

  /// The currencies of the accounts, the shown currency first: what a limit
  /// can be set in.
  Future<List<Currency>> currencies();

  /// Sets the limit of category [categoryId], or takes it away with `null`.
  Future<void> setLimit(String categoryId, CategoryLimit? limit);
}
