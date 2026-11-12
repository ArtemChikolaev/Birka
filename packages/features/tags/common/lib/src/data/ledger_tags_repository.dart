import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:tags_common/src/domain/tags_repository.dart';

/// Keeps the метки in the ledger and reads their totals at the rates.
final class LedgerTagsRepository implements TagsRepository {
  /// Creates a repository on [_ledger], [_rates] and the choice of
  /// [_baseCurrency]. [now] tells the time in tests.
  LedgerTagsRepository(
    this._ledger,
    this._rates,
    this._baseCurrency, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final LedgerRepository _ledger;
  final RatesRepository _rates;
  final BaseCurrency _baseCurrency;
  final DateTime Function() _now;

  @override
  CivilDate today() => CivilDate.of(_now());

  @override
  Stream<List<Tag>> watchTags() => _ledger.watchTags();

  @override
  Stream<List<Transaction>> watchTagged() =>
      _ledger.watchTransactions(tagged: true, limit: null);

  @override
  Stream<List<Transaction>> watchTransactionsOf(String id) =>
      _ledger.watchTransactions(tagId: id, limit: null);

  @override
  Stream<Transaction?> watchTransaction(String id) =>
      _ledger.watchTransaction(id);

  @override
  Stream<List<Category>> watchCategories() =>
      _ledger.watchCategories(CategoryKind.expense, includeArchived: true);

  @override
  Stream<RateBook> watchRates() => _rates.watchRates();

  @override
  Stream<Currency?> watchBaseCurrency() => _baseCurrency.watch();

  @override
  Stream<Currency?> watchMainCurrency() => _ledger.watchAccounts().map(
    (accounts) => accounts
        .where((account) => account.includeInTotals)
        .firstOrNull
        ?.currency,
  );

  @override
  Future<int> expensesOf(TagDays days) async {
    final transactions = await _ledger
        .watchTransactions(from: days.first, to: days.last, limit: null)
        .first;
    final trip = Tag(id: '', name: '', days: days, marksDays: true);
    return transactions
        .where(
          (transaction) => trip.marks(
            kind: transaction.kind,
            source: transaction.source,
            day: transaction.occurredOn,
          ),
        )
        .length;
  }

  @override
  Future<TagMarking> add({
    required String name,
    TagDays? days,
    bool marksDays = false,
  }) => _ledger.addTag(name: name, days: days, marksDays: marksDays);

  @override
  Future<TagMarking> update(Tag tag) => _ledger.updateTag(tag);

  @override
  Future<void> unmarkDays(String id) => _ledger.unmarkDays(id);

  @override
  Future<void> setTags(String id, Set<String> tagIds) =>
      _ledger.setTags(id, tagIds);
}
