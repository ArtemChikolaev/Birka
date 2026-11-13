import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// What «Спросить» reads from the ledger and keeps on the device
/// (ADR 0028). Nothing leaves it.
abstract interface class AskRepository {
  /// The day of the device.
  CivilDate today();

  /// The categories of [kind], the archived ones too, since past operations
  /// keep them.
  Stream<List<Category>> watchCategories(CategoryKind kind);

  /// The метки, the archived ones too.
  Stream<List<Tag>> watchTags();

  /// The accounts with what each holds.
  Stream<List<AccountBalance>> watchBalances();

  /// The transactions from [from] to [to] with both ends included, every one
  /// without them, or those that wear метка [tagId], the latest first.
  Stream<List<Transaction>> watchTransactions({
    CivilDate? from,
    CivilDate? to,
    String? tagId,
  });

  /// The rates kept on the device.
  Stream<RateBook> watchRates();

  /// The currency of the totals that the person picked, or `null` for the
  /// one of the first account.
  Stream<Currency?> watchBaseCurrency();

  /// The day that months start on (ADR 0024).
  Stream<int> watchMonthStart();

  /// The questions asked last, the latest first.
  List<String> recent();

  /// Keeps [questions] as the questions asked last.
  Future<void> keepRecent(List<String> questions);
}
