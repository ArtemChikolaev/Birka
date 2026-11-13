import 'dart:convert';

import 'package:ask_common/src/domain/ask_repository.dart';
import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Reads «Спросить» from the ledger and the rates, and keeps the questions
/// asked last with the settings of the device.
final class LedgerAskRepository implements AskRepository {
  /// Creates a repository on [_ledger], [_rates], the choice of
  /// [_baseCurrency], the start of the months [_monthStart] and the settings
  /// of the device in [_store]. [now] tells the time in tests.
  LedgerAskRepository(
    this._ledger,
    this._rates,
    this._baseCurrency,
    this._monthStart,
    this._store, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final BaseCurrency _baseCurrency;
  final MonthStart _monthStart;
  final SettingsStore _store;
  final DateTime Function() _now;

  /// Where the questions asked last live among the settings of the device.
  static const recentKey = 'ask.recent';

  @override
  CivilDate today() => CivilDate.of(_now());

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      _ledger.watchCategories(kind, includeArchived: true);

  @override
  Stream<List<Tag>> watchTags() => _ledger.watchTags(includeArchived: true);

  @override
  Stream<List<AccountBalance>> watchBalances() =>
      _ledger.watchAccountBalances();

  @override
  Stream<List<Transaction>> watchTransactions({
    CivilDate? from,
    CivilDate? to,
    String? tagId,
  }) => _ledger.watchTransactions(
    from: from,
    to: to,
    tagId: tagId,
    limit: null,
  );

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

  @override
  Stream<int> watchMonthStart() => _monthStart.watch();

  @override
  List<String> recent() {
    final kept = _store.read(recentKey);
    if (kept == null) return const [];
    try {
      final list = jsonDecode(kept);
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is String) item,
      ];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> keepRecent(List<String> questions) =>
      _store.write(recentKey, jsonEncode(questions));
}
