import 'dart:async';

import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/src/domain/limits_repository.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The limits of the ledger of this device.
final class LedgerLimitsRepository implements LimitsRepository {
  /// Creates the repository on the ledger and the settings of the device.
  LedgerLimitsRepository(
    this._ledger,
    this._rates,
    this._baseCurrency,
    this._monthStart, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final BaseCurrency _baseCurrency;
  final MonthStart _monthStart;
  final DateTime Function() _now;

  @override
  CivilDate today() => CivilDate.of(_now());

  @override
  Stream<int> watchMonthStart() => _monthStart.watch();

  @override
  Stream<List<Category>> watchCategories() =>
      _ledger.watchCategories(CategoryKind.expense);

  @override
  Stream<List<CategoryDayTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => _ledger.watchCategoryDays(CategoryKind.expense, from: from, to: to);

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<Currency> watchShownCurrency() => Stream.multi((controller) {
    Currency? base;
    Currency? main;
    var baseRead = false;
    var mainRead = false;
    void shown() {
      if (baseRead && mainRead) controller.add(base ?? main ?? Currency.rub);
    }

    final subscriptions = [
      _baseCurrency.watch().listen((currency) {
        base = currency;
        baseRead = true;
        shown();
      }, onError: controller.addError),
      _ledger.watchAccounts().listen((accounts) {
        main = accounts
            .where((account) => account.includeInTotals)
            .firstOrNull
            ?.currency;
        mainRead = true;
        shown();
      }, onError: controller.addError),
    ];
    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
  });

  @override
  Stream<Set<String>> watchRegular() => _ledger.watchSchedules().map(
    (schedules) =>
        schedules.map((schedule) => schedule.categoryId).nonNulls.toSet(),
  );

  @override
  Future<List<Currency>> currencies() async {
    final shown = await watchShownCurrency().first;
    final accounts = await _ledger.watchAccounts().first;
    return {
      shown,
      for (final account in accounts) account.currency,
    }.toList();
  }

  @override
  Future<void> setLimit(String categoryId, CategoryLimit? limit) =>
      _ledger.setCategoryLimit(categoryId, limit);
}
