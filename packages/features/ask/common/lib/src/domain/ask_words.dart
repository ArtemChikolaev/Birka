import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

/// A word or a number of a question, and whether a part of the reading has
/// taken it already.
final class AskToken {
  /// Creates the token [text] at place [index] of the question.
  AskToken(this.text, this.index);

  /// The word as [askTokens] keeps it: in lower case, `е` for `ё`.
  final String text;

  /// Where it stands in the question.
  final int index;

  /// Whether a part of the reading has taken it.
  bool used = false;

  /// Whether it is a number.
  bool get isNumber => _digits.hasMatch(text);

  /// The whole number it is, or `null`.
  int? get number =>
      isNumber && !text.contains(RegExp('[.,]')) ? int.tryParse(text) : null;

  static final _digits = RegExp(r'^\d+([.,]\d+)*$');

  @override
  String toString() => text;
}

/// The words and numbers of [question], with the signs of currencies as
/// words of their own.
List<AskToken> askTokens(String question) {
  final tokens = <AskToken>[];
  for (final match in _token.allMatches(searchKey(question))) {
    tokens.add(AskToken(match.group(0)!, tokens.length));
  }
  return tokens;
}

final _token = RegExp(r'\d+(?:[.,]\d+)*|[a-zа-я]+|[₽$€₾₸֏₺£¥]');

/// How well [word] of a question stands for [name], a word of the name of a
/// category, a метка or an account: 3 for the same word, 2 for the same
/// word in another form, 1 for the start of the name while it is being
/// typed, and 0 when it does not.
///
/// Russian changes the end of a word with its case and number, so two words
/// are the same when they share all but their last few letters: `продукты`
/// and `продуктах`, `подарки` and `подарков`. A short name takes no more
/// than two letters after it: `дом` and `дома`, but not `домашний`.
int wordMatch(String word, String name) {
  if (word == name) return 3;
  if (word.length < 3 || name.length < 3) return 0;
  final shared = _shared(word, name);
  if (name.length <= 4) {
    if (shared == name.length && word.length - name.length <= 2) return 2;
  } else if (shared >= _max(4, name.length - 3) && shared >= word.length - 3) {
    return 2;
  } else if (word.length >= 6 && _oneEditApart(word, name)) {
    return 2;
  }
  // A word that is still being typed: `прод` for `продукты`.
  if (word.length >= 4 && shared == word.length) return 1;
  return 0;
}

/// Whether some word of [words] stands for [stem] in the way of `wordMatch`,
/// at least as the same word in another form.
bool hasWord(Iterable<AskToken> words, String stem) =>
    words.any((token) => !token.used && wordMatch(token.text, stem) >= 2);

/// Whether [word] starts with one of [starts].
bool startsAny(String word, List<String> starts) => starts.any(word.startsWith);

int _shared(String a, String b) {
  final length = a.length < b.length ? a.length : b.length;
  var i = 0;
  while (i < length && a.codeUnitAt(i) == b.codeUnitAt(i)) {
    i++;
  }
  return i;
}

int _max(int a, int b) => a > b ? a : b;

bool _oneEditApart(String a, String b) {
  if ((a.length - b.length).abs() > 1 || a[0] != b[0]) return false;
  var i = 0;
  var j = 0;
  var edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length > b.length) {
      i++;
    } else if (b.length > a.length) {
      j++;
    } else {
      i++;
      j++;
    }
  }
  return edits + (a.length - i) + (b.length - j) <= 1;
}

/// The words of [name] that can stand for it, without the short ones such
/// as `и` and `на`.
List<String> askNameWords(String name) => [
  for (final token in askTokens(name))
    if (token.text.length >= 3 || token.isNumber) token.text,
];

/// The currency that [word] names: a sign, a code or a word such as
/// `лари` or `долларов`.
Currency? currencyOf(String word) {
  for (final MapEntry(key: starts, value: code) in _currencyWords.entries) {
    if (starts.any((start) => word == start || word.startsWith(start))) {
      return Currency.iso(code);
    }
  }
  if (word.length == 3 && _codes.contains(word.toUpperCase())) {
    return Currency.iso(word.toUpperCase());
  }
  return null;
}

const _codes = {'RUB', 'USD', 'EUR', 'GEL', 'KZT', 'AMD', 'TRY', 'GBP'};

const _currencyWords = <List<String>, String>{
  ['₽', 'руб', 'рубл', 'rub', 'ruble', 'rouble']: 'RUB',
  [r'$', 'доллар', 'бакс', 'dollar', 'usd']: 'USD',
  ['€', 'евро', 'euro', 'eur']: 'EUR',
  ['₾', 'лари', 'lari', 'gel']: 'GEL',
  ['₸', 'тенге', 'tenge', 'kzt']: 'KZT',
  ['֏', 'драм', 'dram', 'amd']: 'AMD',
  ['₺', 'лир', 'lira', 'try']: 'TRY',
  ['£', 'фунт', 'pound', 'gbp']: 'GBP',
};

/// Words that say nothing about what to count: `сколько`, `я`, `на`.
const askStopWords = {
  // Russian.
  'а', 'в', 'во', 'все', 'всего', 'вообще', 'вот', 'где', 'да', 'для', 'до',
  'его', 'ее', 'если', 'есть', 'еще', 'же', 'за', 'и', 'из', 'или', 'им',
  'их', 'к', 'как', 'какие', 'какой', 'какая', 'когда', 'ко', 'ли', 'мне',
  'меня', 'мной', 'мои', 'мой', 'моих', 'мою', 'моя', 'мы', 'на',
  'нам', 'нас', 'не', 'нибудь', 'но', 'ну', 'о', 'об', 'около', 'от', 'по',
  'покажи', 'покажите', 'показать', 'пожалуйста', 'посчитай', 'посмотри',
  'при', 'про', 'с', 'сколько', 'со', 'так', 'там', 'то', 'том', 'у', 'уже',
  'что', 'чтобы', 'это', 'эти', 'этот', 'эту', 'я', 'было', 'был', 'была',
  'были', 'будет', 'всех', 'всю', 'свои', 'свой', 'своих', 'сумма', 'сумму',
  'денег', 'деньги', 'деньгах', 'всё', 'найди', 'скажи', 'подскажи',
  'интересно', 'хочу', 'знать', 'узнать', 'итого', 'итог', 'общая', 'общую',
  'операции', 'операций', 'операция', 'поездке', 'поездку', 'поездка',
  'хожу',
  'год',
  'году',
  'года',
  'больше',
  'меньше',
  'более',
  'менее',
  'ходил',
  'ходила',
  'чек',
  'метке', 'метка', 'метку', 'категории', 'категория', 'категорию',
  // English.
  'a', 'an', 'and', 'at', 'by', 'did', 'do', 'for', 'from', 'how', 'i',
  'in', 'is', 'it', 'me', 'much', 'my', 'of', 'on', 'show', 'the', 'to',
  'was', 'were', 'what', 'with', 'many', 'money', 'total', 'please',
};
