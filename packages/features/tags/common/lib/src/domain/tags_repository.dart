import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// What the метки need of the ledger, the rates and the device (ADR 0027).
abstract interface class TagsRepository {
  /// Today on the calendar of this device.
  CivilDate today();

  /// The метки, again after every change: the trips by their first days, the
  /// latest first, then the others by name.
  Stream<List<Tag>> watchTags();

  /// The transactions that wear any метка, the latest first.
  Stream<List<Transaction>> watchTagged();

  /// The transactions that wear метка [id], the latest first.
  Stream<List<Transaction>> watchTransactionsOf(String id);

  /// Transaction [id], and `null` while it is not there.
  Stream<Transaction?> watchTransaction(String id);

  /// The categories of expenses, archived ones included.
  Stream<List<Category>> watchCategories();

  /// The rates that are known.
  Stream<RateBook> watchRates();

  /// The currency that totals are in, or `null` to follow the first account
  /// in the totals.
  Stream<Currency?> watchBaseCurrency();

  /// The currency of the first account in the totals.
  Stream<Currency?> watchMainCurrency();

  /// How many expenses of [days] a trip that marks them would put itself on:
  /// those that a regular payment did not give.
  Future<int> expensesOf(TagDays days);

  /// Adds a метка, and says how many expenses its days put it on.
  Future<TagMarking> add({
    required String name,
    TagDays? days,
    bool marksDays = false,
  });

  /// Puts [tag] in place of the метка with its id.
  Future<TagMarking> update(Tag tag);

  /// Takes the days of trip [id] back off its expenses.
  Future<void> unmarkDays(String id);

  /// Puts on transaction [id] exactly the метки [tagIds].
  Future<void> setTags(String id, Set<String> tagIds);
}
