import 'package:ask_common/src/domain/ask_period.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// Which money a question counts.
enum AskSide {
  /// What went out: `траты`, `расходы`.
  expenses,

  /// What came in: `доходы`.
  income,
}

/// What a question wants most from the money it counts. The answer shows
/// the total in any case.
enum AskFocus {
  /// How much: `сколько`.
  total,

  /// How many times: `сколько раз`.
  count,

  /// The mean of one operation: `в среднем`.
  average,

  /// The biggest operations: `самая крупная трата`.
  biggest,

  /// Where it went: `на что больше всего`.
  categories,
}

/// A question about the money in the ledger, typed: what the parser makes of
/// the words, and what a model will have to fill in the same way later
/// (ADR 0028). The ledger counts it on the device.
@immutable
final class AskQuery {
  /// Creates a query.
  const AskQuery({
    this.side = AskSide.expenses,
    this.period,
    this.categoryIds = const {},
    this.tagId,
    this.accountId,
    this.words = const [],
    this.above,
    this.below,
    this.focus = AskFocus.total,
  });

  /// Which money it counts.
  final AskSide side;

  /// The days it covers, or `null` for every day of the метка [tagId].
  final AskPeriod? period;

  /// The categories it keeps, with their subcategories, or every one when
  /// empty.
  final Set<String> categoryIds;

  /// The метка an operation has to wear.
  final String? tagId;

  /// The account an operation has to go through.
  final String? accountId;

  /// Words that the note of an operation has to hold, such as `такси` when
  /// no category bears the name.
  final List<String> words;

  /// What an operation has to be more than, in its own currency or, at the
  /// rate of its day, in another.
  final Money? above;

  /// What an operation has to be less than.
  final Money? below;

  /// What the question wants most.
  final AskFocus focus;

  /// The query with [period] in place of its own.
  AskQuery withPeriod(AskPeriod period) => AskQuery(
    side: side,
    period: period,
    categoryIds: categoryIds,
    tagId: tagId,
    accountId: accountId,
    words: words,
    above: above,
    below: below,
    focus: focus,
  );

  /// The query as plain data, for the golden tests of the parser.
  Map<String, Object> toJson() => {
    'side': side.name,
    'period': ?period?.toJson(),
    if (categoryIds.isNotEmpty) 'categories': [...categoryIds]..sort(),
    'tag': ?tagId,
    'account': ?accountId,
    if (words.isNotEmpty) 'words': words,
    'above': ?above?.toString(),
    'below': ?below?.toString(),
    if (focus != AskFocus.total) 'focus': focus.name,
  };

  @override
  String toString() => 'AskQuery(${toJson()})';
}
