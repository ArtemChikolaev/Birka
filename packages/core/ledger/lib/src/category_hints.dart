import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/transaction.dart';
import 'package:meta/meta.dart';

/// Why a category is likely for an operation without one (ADR 0022).
enum HintReason {
  /// The person gave operations of the same name this category.
  sameName,

  /// The same amount on the same account went into this category month after
  /// month.
  everyMonth,

  /// An operation of the same import with a similar name has the category.
  sameImport,

  /// An operation with a similar name has the category.
  similarName,
}

/// A category that the past choices of the person suggest for an operation.
@immutable
final class CategoryHint {
  /// Creates a hint.
  const CategoryHint({
    required this.categoryId,
    required this.reason,
    required this.first,
    required this.last,
    this.count = 1,
    this.like,
  });

  /// The category.
  final String categoryId;

  /// Why it is likely.
  final HintReason reason;

  /// How many operations say so.
  final int count;

  /// The day of the first of them.
  final CivilDate first;

  /// The day of the last of them.
  final CivilDate last;

  /// The note of the operation it resembles, for a similar name.
  final String? like;
}

/// What the person chose before, kept to suggest a category for an operation
/// without one: by its name, by its amount month after month, and by a
/// similar name, first in its own import (ADR 0022). Similar names compare by
/// their words in Latin letters, so that `BARBERSHOP 77` meets «Барбершоп».
final class CategoryMemory {
  /// Remembers the expenses and income of [history] that have one category.
  factory CategoryMemory(Iterable<Transaction> history) {
    final byName = <String, List<_Known>>{};
    final byWord = <String, List<_Known>>{};
    final byAmount = <String, List<_Known>>{};
    for (final transaction in history) {
      if (!_kinds.contains(transaction.kind)) continue;
      final ids = {
        for (final allocation in transaction.allocations) allocation.categoryId,
      };
      if (ids.length != 1) continue;
      final categoryId = ids.single;
      if (categoryId == null) continue;
      final known = (transaction: transaction, categoryId: categoryId);
      final name = nameKey(transaction.note);
      if (name.isNotEmpty) (byName[name] ??= []).add(known);
      for (final word in nameWords(transaction.note)) {
        (byWord[word] ??= []).add(known);
      }
      if (_amountKey(transaction) case final key?) {
        (byAmount[key] ??= []).add(known);
      }
    }
    return CategoryMemory._(byName, byWord, byAmount);
  }

  CategoryMemory._(this._byName, this._byWord, this._byAmount);

  final Map<String, List<_Known>> _byName;
  final Map<String, List<_Known>> _byWord;
  final Map<String, List<_Known>> _byAmount;

  static const Set<TransactionKind> _kinds = {
    TransactionKind.expense,
    TransactionKind.income,
  };

  /// How many months back an amount counts for [HintReason.everyMonth].
  static const _months = 3;

  /// The category that the past suggests for [transaction], or `null` when
  /// nothing does.
  CategoryHint? hintFor(Transaction transaction) {
    if (!_kinds.contains(transaction.kind)) return null;
    bool fits(_Known known) =>
        known.transaction.id != transaction.id &&
        known.transaction.kind == transaction.kind;

    final name = nameKey(transaction.note);
    final same = [
      for (final known in _byName[name] ?? const <_Known>[])
        if (fits(known)) known,
    ];
    if (name.isNotEmpty && same.isNotEmpty) {
      return _mostCommon(same, HintReason.sameName);
    }

    final month = _monthOf(transaction.occurredOn);
    final monthly = <_Known>[];
    for (final known
        in _byAmount[_amountKey(transaction)] ?? const <_Known>[]) {
      final ago = month - _monthOf(known.transaction.occurredOn);
      if (fits(known) && ago >= 1 && ago <= _months) monthly.add(known);
    }
    final months = {
      for (final known in monthly) _monthOf(known.transaction.occurredOn),
    };
    if (months.length >= 2) return _mostCommon(monthly, HintReason.everyMonth);

    final similar = <_Known>{
      for (final word in nameWords(transaction.note))
        for (final MapEntry(key: known, value: list) in _byWord.entries)
          if (_alike(word, known))
            for (final it in list)
              if (fits(it)) it,
    };
    if (similar.isEmpty) return null;
    final importId = transaction.importId;
    final ofImport = [
      for (final known in similar)
        if (importId != null && known.transaction.importId == importId) known,
    ];
    final latest = (ofImport.isEmpty ? similar : ofImport).reduce(
      (a, b) =>
          a.transaction.occurredOn.compareTo(b.transaction.occurredOn) >= 0
          ? a
          : b,
    );
    return CategoryHint(
      categoryId: latest.categoryId,
      reason: ofImport.isEmpty ? HintReason.similarName : HintReason.sameImport,
      first: latest.transaction.occurredOn,
      last: latest.transaction.occurredOn,
      like: latest.transaction.note,
    );
  }

  static CategoryHint _mostCommon(List<_Known> known, HintReason reason) {
    final groups = <String, List<_Known>>{};
    for (final it in known) {
      (groups[it.categoryId] ??= []).add(it);
    }
    CivilDate lastOf(List<_Known> group) => group
        .map((it) => it.transaction.occurredOn)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    final best = groups.entries.reduce((a, b) {
      final byCount = a.value.length.compareTo(b.value.length);
      if (byCount != 0) return byCount > 0 ? a : b;
      return lastOf(a.value).compareTo(lastOf(b.value)) >= 0 ? a : b;
    });
    return CategoryHint(
      categoryId: best.key,
      reason: reason,
      count: best.value.length,
      first: best.value
          .map((it) => it.transaction.occurredOn)
          .reduce((a, b) => a.compareTo(b) <= 0 ? a : b),
      last: lastOf(best.value),
    );
  }

  static int _monthOf(CivilDate day) => day.year * 12 + day.month - 1;

  /// The account, the kind and the amount of [transaction], or `null` for
  /// one that moves money on more than one account.
  static String? _amountKey(Transaction transaction) {
    if (transaction.entries.length != 1) return null;
    final entry = transaction.entries.single;
    return '${entry.accountId}|${transaction.kind.name}|'
        '${entry.amount.minorUnits}|${entry.amount.currency.code}';
  }

  /// Whether two words of names are alike: the same, or one the start of the
  /// other when it has at least five letters.
  static bool _alike(String a, String b) {
    if (a == b) return true;
    final (short, long) = a.length <= b.length ? (a, b) : (b, a);
    return short.length >= 5 && long.startsWith(short);
  }
}

typedef _Known = ({Transaction transaction, String categoryId});

/// [note] as a key of a name: its words in lower case, without digits, so
/// that `Пятёрочка 1234` and `ПЯТЕРОЧКА 77` are one name.
String nameKey(String note) => _plain
    .allMatches(note.toLowerCase().replaceAll('ё', 'е'))
    .map((match) => match[0]!)
    .join(' ');

final _plain = RegExp('[a-zа-я]{2,}');

/// The words of [note] that tell it from others: in Latin letters, of four
/// letters or more, without the words of banks such as «перевод» or `CARD`.
Set<String> nameWords(String note) => {
  for (final word in _words(note))
    if (word.length >= 4 && !_common.contains(word)) word,
};

Iterable<String> _words(String note) sync* {
  final latin = StringBuffer();
  for (final char in note.toLowerCase().split('')) {
    latin.write(_latin[char] ?? char);
  }
  for (final match in _letters.allMatches(latin.toString())) {
    yield match[0]!;
  }
}

final _letters = RegExp('[a-z]{2,}');

/// The words that the descriptions of many operations share.
const _common = {
  'card',
  'karta',
  'karty',
  'kartu',
  'moscow',
  'moskva',
  'online',
  'oplata',
  'payment',
  'perevod',
  'perevody',
  'pokupka',
  'popolnenie',
  'russia',
  'spisanie',
  'transfer',
};

/// Russian letters in the Latin letters that banks use for them.
const _latin = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'е': 'e',
  'ё': 'e',
  'ж': 'zh',
  'з': 'z',
  'и': 'i',
  'й': 'i',
  'к': 'k',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ф': 'f',
  'х': 'kh',
  'ц': 'ts',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'sch',
  'ъ': '',
  'ы': 'y',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};
