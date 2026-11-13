import 'package:ask_common/src/domain/ask_period.dart';
import 'package:ask_common/src/domain/ask_query.dart';
import 'package:ask_common/src/domain/ask_reading.dart';
import 'package:ask_common/src/domain/ask_words.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// What the parser knows of the ledger and of the day to read a question.
@immutable
final class AskVocabulary {
  /// Creates a vocabulary for [today].
  const AskVocabulary({
    required this.today,
    this.categories = const [],
    this.tags = const [],
    this.accounts = const [],
    this.monthStart = 1,
    this.base,
  });

  /// The day of the question.
  final CivilDate today;

  /// The categories that a question can name, of both kinds.
  final List<Category> categories;

  /// The метки that a question can name.
  final List<Tag> tags;

  /// The accounts that a question can name.
  final List<Account> accounts;

  /// The day that months start on (ADR 0024).
  final int monthStart;

  /// The currency of the totals, which an amount without one is in.
  final Currency? base;
}

/// Reads a question in words, in Russian or English, as one of a few typed
/// answers, with no model and nothing sent anywhere (ADR 0028).
///
/// It knows the words of periods, amounts, kinds of money and facts, and it
/// finds categories, метки and accounts by their names in any form of the
/// word. What it cannot place stays as words that the note of an operation
/// has to hold.
final class AskParser {
  /// Creates a parser with [vocabulary], which answers from the common
  /// questions of [help] too.
  AskParser(this.vocabulary, {this.help = const []});

  /// What the parser knows of the ledger.
  final AskVocabulary vocabulary;

  /// The common questions of the help, in the language of the app.
  final List<HelpQuestion> help;

  CivilDate get _today => vocabulary.today;

  /// What [question] is read as, or `null` while it is too short to tell.
  AskReading? read(String question) {
    final tokens = askTokens(question);
    final letters = tokens.fold(0, (sum, token) => sum + token.text.length);
    if (letters < 3) return null;
    if (_asksAdvice(tokens)) return const AskRefused(AskRefusal.advice);
    if (_offTopic(tokens)) return const AskRefused(AskRefusal.offTopic);
    if (_helpCue(tokens)) {
      final answers = _help(tokens);
      if (answers.isNotEmpty) {
        return AskHelpReading(answers, places: _places(tokens));
      }
    }
    final fact = _fact(tokens);
    if (fact != null) return fact;
    final data = _data(tokens);
    if (data != null) return data;
    final places = _places(tokens);
    final answers = _help(tokens);
    if (answers.isNotEmpty) return AskHelpReading(answers, places: places);
    if (places.isNotEmpty) return AskPlacesReading(places);
    return const AskUnknown();
  }

  // ---------------------------------------------------------------- refusals

  static const _adviceStarts = [
    'инвест',
    'вложить',
    'вкладыв',
    'акци',
    'облигац',
    'крипт',
    'биткоин',
    'вырастет',
    'упадет',
    'выгодн',
    'invest',
    'stock',
    'crypto',
    'bitcoin',
  ];
  static const _adviceWords = {
    'купить',
    'покупать',
    'продать',
    'продавать',
    'обменять',
    'менять',
    'buy',
    'sell',
    'should',
  };

  bool _asksAdvice(List<AskToken> tokens) {
    for (final (i, token) in tokens.indexed) {
      final word = token.text;
      if (startsAny(word, _adviceStarts) || _adviceWords.contains(word)) {
        return true;
      }
      // «Стоит ли», but not «сколько стоит».
      if (word == 'стоит' &&
          i + 1 < tokens.length &&
          tokens[i + 1].text == 'ли') {
        return true;
      }
      final rate = tokens.any((t) => t.text.startsWith('курс'));
      if ((word == 'прогноз' || word == 'будет') && rate) {
        return true;
      }
    }
    return false;
  }

  static const _offTopicStarts = [
    'погод',
    'новост',
    'анекдот',
    'шутк',
    'стих',
    'рецепт',
    'weather',
    'news',
    'joke',
    'poem',
    'recipe',
  ];

  bool _offTopic(List<AskToken> tokens) =>
      tokens.any((token) => startsAny(token.text, _offTopicStarts)) ||
      _phrase(tokens, ['кто', 'ты']) ||
      _phrase(tokens, ['как', 'дела']) ||
      _phrase(tokens, ['who', 'are', 'you']);

  // ---------------------------------------------------------------- help

  static const _helpCues = {
    'как',
    'откуда',
    'почему',
    'зачем',
    'где',
    'how',
    'why',
    'where',
  };

  bool _helpCue(List<AskToken> tokens) =>
      _helpCues.contains(tokens.first.text) ||
      _phrase(tokens, ['что', 'такое']) ||
      _phrase(tokens, ['what', 'is']);

  /// The common questions that [tokens] ask, the best first: a word of the
  /// question counts twice, a word of its answer once.
  List<int> _help(List<AskToken> tokens) {
    final words = [
      for (final token in tokens)
        if (!token.isNumber &&
            token.text.length >= 3 &&
            !askStopWords.contains(token.text) &&
            !_helpCues.contains(token.text))
          token.text,
    ];
    if (words.isEmpty) return const [];
    final scored = <(int, int)>[];
    for (final (index, entry) in help.indexed) {
      final asked = askNameWords(entry.question);
      final answered = askNameWords(entry.answer);
      var inQuestion = 0;
      var inAnswer = 0;
      for (final word in words) {
        if (asked.any((other) => wordMatch(word, other) >= 2)) {
          inQuestion++;
        } else if (answered.any((other) => wordMatch(word, other) >= 2)) {
          inAnswer++;
        }
      }
      final score = inQuestion * 2 + inAnswer;
      if ((inQuestion >= 1 && score >= 3) || inQuestion >= 2) {
        scored.add((index, score));
      }
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (index, _) in scored.take(2)) index];
  }

  // ---------------------------------------------------------------- places

  static const _placeStarts = <AskPlace, List<String>>{
    AskPlace.payday: ['зарплат', 'аванс', 'прогноз', 'payday', 'salary'],
    AskPlace.schedules: [
      'регулярн',
      'подписк',
      'платеж',
      'списани',
      'recurring',
      'subscript',
    ],
    AskPlace.tags: ['метк', 'поездк', 'путешеств', 'tag', 'trip'],
    AskPlace.accounts: ['счет', 'карт', 'account', 'card'],
    AskPlace.categories: ['категор', 'categor'],
    AskPlace.imports: ['импорт', 'выписк', 'загруз', 'import', 'statement'],
    AskPlace.inbox: ['входящ', 'разобрат', 'inbox'],
    AskPlace.backup: [
      'копи',
      'бэкап',
      'бекап',
      'резерв',
      'экспорт',
      'перенес',
      'перенос',
      'данны',
      'восстанов',
      'backup',
      'export',
      'restore',
      'data',
    ],
    AskPlace.help: [
      'помощ',
      'справк',
      'поддержк',
      'разработчик',
      'ошибк',
      'help',
      'support',
      'feedback',
    ],
    AskPlace.notifications: [
      'уведомлен',
      'напоминан',
      'колокольч',
      'notification',
      'remind',
    ],
    AskPlace.reports: ['отчет', 'статистик', 'диаграмм', 'report', 'statist'],
    AskPlace.settings: [
      'настройк',
      'язык',
      'тема',
      'темн',
      'валют',
      'setting',
      'language',
      'theme',
      'currency',
    ],
  };

  /// The screens that [tokens] name, in the order of [AskPlace].
  List<AskPlace> _places(List<AskToken> tokens) => [
    for (final MapEntry(key: place, value: starts) in _placeStarts.entries)
      if (tokens.any((token) => startsAny(token.text, starts))) place,
  ];

  // ---------------------------------------------------------------- facts

  AskFactReading? _fact(List<AskToken> tokens) {
    if (tokens.any((token) => token.text.startsWith('курс')) ||
        _has(tokens, 'rate')) {
      final currency = tokens
          .map((token) => currencyOf(token.text))
          .whereType<Currency>()
          .where((currency) => currency != vocabulary.base)
          .firstOrNull;
      return AskFactReading(AskFact.rate, currency: currency ?? Currency.usd);
    }
    final spendable =
        (_has(tokens, 'можно') &&
            tokens.any((token) => startsAny(token.text, ['трат', 'потрат']))) ||
        (_has(tokens, 'осталось') &&
            tokens.any(
              (token) => startsAny(token.text, ['день', 'сегодн', 'зарплат']),
            )) ||
        _phrase(tokens, ['can', 'i', 'spend']) ||
        _phrase(tokens, ['left', 'for', 'today']);
    if (spendable) return const AskFactReading(AskFact.allowance);
    final noPeriod = !tokens.any((token) => _monthOf(token.text) != null);
    final payments =
        tokens.any((token) => startsAny(token.text, ['платеж', 'списан'])) ||
        (_has(tokens, 'когда') &&
            tokens.any(
              (token) => startsAny(token.text, ['плат', 'оплат', 'спиш']),
            )) ||
        _phrase(tokens, ['next', 'payment']) ||
        _has(tokens, 'bills');
    if (payments && noPeriod) return const AskFactReading(AskFact.payments);
    final spends = tokens.any(
      (token) => startsAny(token.text, [..._expenseStarts, ..._incomeStarts]),
    );
    final capital =
        !spends &&
        (_phrase(tokens, ['сколько', 'денег']) ||
            _phrase(tokens, ['сколько', 'у', 'меня']) ||
            tokens.any(
              (token) => startsAny(token.text, ['капитал', 'баланс']),
            ) ||
            _phrase(tokens, ['на', 'счетах']) ||
            _phrase(tokens, ['net', 'worth']) ||
            _phrase(tokens, ['money', 'do', 'i', 'have']) ||
            _has(tokens, 'balance'));
    if (capital) return const AskFactReading(AskFact.capital);
    return null;
  }

  // ---------------------------------------------------------------- data

  static const _expenseStarts = [
    'трат',
    'трач',
    'покуп',
    'расход',
    'потрат',
    'ушл',
    'ушло',
    'заплат',
    'оплат',
    'платил',
    'spent',
    'spend',
    'expens',
    'paid',
  ];
  static const _incomeStarts = [
    'доход',
    'заработ',
    'получил',
    'пришл',
    'поступ',
    'income',
    'earn',
  ];

  AskData? _data(List<AskToken> tokens) {
    final period = _period(tokens);
    final allTime = _allTime(tokens);
    final (above, below) = _amounts(tokens);
    final side = _side(tokens);
    final focus = _focus(tokens);
    final tag = _tag(tokens);
    final account = _account(tokens);
    final categories = _categories(tokens, side);
    final words = [
      for (final token in tokens)
        if (!token.used &&
            !token.isNumber &&
            token.text.length >= 3 &&
            !askStopWords.contains(token.text) &&
            currencyOf(token.text) == null)
          token.text,
    ];
    final signals =
        period != null ||
        allTime ||
        above != null ||
        below != null ||
        side != null ||
        focus != AskFocus.total ||
        tag != null ||
        account != null ||
        categories.isNotEmpty;
    if (!signals) return null;
    final kind = side ?? _sideOf(categories) ?? AskSide.expenses;
    final days = period ?? _defaultPeriod(tag: tag, allTime: allTime);
    return AskData(
      AskQuery(
        side: kind,
        period: days?.upTo(_today),
        categoryIds: categories,
        tagId: tag,
        accountId: account,
        words: words,
        above: above,
        below: below,
        focus: focus,
      ),
      places: categories.isEmpty ? const [] : _namedPlaces(tokens),
    );
  }

  /// The screens that a word also names when it named a category, such as
  /// `зарплата`.
  List<AskPlace> _namedPlaces(List<AskToken> tokens) => [
    for (final place in _places(tokens))
      if (place == AskPlace.payday || place == AskPlace.schedules) place,
  ];

  AskPeriod? _defaultPeriod({required String? tag, required bool allTime}) {
    if (tag != null || allTime) return null;
    return AskPeriod.month(_today, start: vocabulary.monthStart);
  }

  bool _allTime(List<AskToken> tokens) {
    for (var i = 0; i + 1 < tokens.length; i++) {
      final all = tokens[i].text == 'все' || tokens[i].text == 'всё';
      if (all && tokens[i + 1].text.startsWith('врем')) {
        tokens[i].used = tokens[i + 1].used = true;
        return true;
      }
      if (tokens[i].text == 'all' && tokens[i + 1].text == 'time') {
        tokens[i].used = tokens[i + 1].used = true;
        return true;
      }
    }
    return false;
  }

  AskSide? _side(List<AskToken> tokens) {
    AskSide? side;
    for (final token in tokens) {
      if (token.used) continue;
      if (startsAny(token.text, _expenseStarts)) {
        side ??= AskSide.expenses;
        token.used = true;
      } else if (startsAny(token.text, _incomeStarts)) {
        side ??= AskSide.income;
        token.used = true;
      }
    }
    return side;
  }

  AskSide? _sideOf(Set<String> categories) {
    for (final category in vocabulary.categories) {
      if (categories.contains(category.id)) {
        return category.kind == CategoryKind.income
            ? AskSide.income
            : AskSide.expenses;
      }
    }
    return null;
  }

  AskFocus _focus(List<AskToken> tokens) {
    for (final (i, token) in tokens.indexed) {
      final word = token.text;
      final next = i + 1 < tokens.length ? tokens[i + 1].text : '';
      if (word == 'раз' || word.startsWith('часто') || word == 'times') {
        token.used = true;
        return AskFocus.count;
      }
      if (word == 'сколько' && next.startsWith('операц')) {
        tokens[i + 1].used = true;
        return AskFocus.count;
      }
      if (word.startsWith('средн') || word == 'average') {
        token.used = true;
        return AskFocus.average;
      }
      final biggest =
          (word.startsWith('сам') &&
              startsAny(next, ['больш', 'крупн', 'дорог'])) ||
          startsAny(word, ['крупнейш', 'максимальн', 'biggest', 'largest']);
      if (biggest) {
        token.used = true;
        if (next.isNotEmpty && !word.startsWith('крупнейш')) {
          tokens[i + 1].used = true;
        }
        return AskFocus.biggest;
      }
      if ((word == 'на' && next == 'что') ||
          word == 'куда' ||
          word.startsWith('категориям') ||
          word == 'where') {
        token.used = true;
        if (next == 'что') tokens[i + 1].used = true;
        return AskFocus.categories;
      }
    }
    return AskFocus.total;
  }

  // ---------------------------------------------------------------- names

  /// The категории that [tokens] name, with the best match of each word.
  Set<String> _categories(List<AskToken> tokens, AskSide? side) {
    final found = <String>{};
    for (final token in tokens) {
      if (token.used || token.isNumber) continue;
      if (askStopWords.contains(token.text)) continue;
      var best = 0;
      final picked = <Category>[];
      for (final category in vocabulary.categories) {
        if (side != null && _kindOf(side) != category.kind) continue;
        final words = askNameWords(category.name);
        if (words.isEmpty) continue;
        final score = wordMatch(token.text, words.first);
        if (score == 0 || score < best) continue;
        if (score > best) picked.clear();
        best = score;
        picked.add(category);
      }
      if (picked.isEmpty) continue;
      token.used = true;
      // A subcategory stands for itself, and the answer counts it apart.
      for (final category in picked) {
        found.add(category.id);
      }
    }
    return found;
  }

  CategoryKind _kindOf(AskSide side) =>
      side == AskSide.income ? CategoryKind.income : CategoryKind.expense;

  String? _tag(List<AskToken> tokens) {
    String? best;
    var bestScore = 0;
    var bestTokens = const <AskToken>[];
    for (final tag in vocabulary.tags) {
      final words = askNameWords(tag.name);
      if (words.isEmpty) continue;
      var score = 0;
      final taken = <AskToken>[];
      for (final (i, word) in words.indexed) {
        final token = tokens
            .where((t) => !t.used && !t.isNumber)
            .firstWhere(
              (t) => wordMatch(t.text, word) >= 2,
              orElse: () => AskToken('', -1),
            );
        if (token.index < 0) {
          // The first word of a name has to be there; the others help.
          if (i == 0) break;
          continue;
        }
        score += wordMatch(token.text, word);
        taken.add(token);
      }
      if (taken.isEmpty || score <= bestScore) continue;
      best = tag.id;
      bestScore = score;
      bestTokens = taken;
    }
    for (final token in bestTokens) {
      token.used = true;
    }
    return best;
  }

  static const _accountCues = ['карт', 'счет', 'наличн', 'card', 'account'];

  String? _account(List<AskToken> tokens) {
    final cue = tokens.any((token) => startsAny(token.text, _accountCues));
    for (final account in vocabulary.accounts) {
      final words = askNameWords(account.name);
      if (words.isEmpty) continue;
      final token = tokens
          .where((t) => !t.used && !t.isNumber)
          .firstWhere(
            (t) => wordMatch(t.text, words.first) >= (cue ? 2 : 3),
            orElse: () => AskToken('', -1),
          );
      if (token.index < 0) continue;
      token.used = true;
      for (final other in tokens) {
        if (!other.used && startsAny(other.text, _accountCues)) {
          other.used = true;
        }
      }
      return account.id;
    }
    return null;
  }

  // ---------------------------------------------------------------- amounts

  static const _aboveWords = {
    'больше',
    'более',
    'свыше',
    'дороже',
    'выше',
    'от',
    'over',
    'above',
    'more',
    'from',
  };
  static const _belowWords = {
    'меньше',
    'менее',
    'дешевле',
    'ниже',
    'до',
    'under',
    'below',
    'less',
  };

  (Money?, Money?) _amounts(List<AskToken> tokens) {
    Money? above;
    Money? below;
    for (var i = 0; i < tokens.length; i++) {
      final cue = tokens[i];
      if (cue.used) continue;
      final up = _aboveWords.contains(cue.text);
      final down = _belowWords.contains(cue.text);
      if (!up && !down) continue;
      var j = i + 1;
      if (j < tokens.length && tokens[j].text == 'than') j++;
      final amount = _amountAt(tokens, j);
      if (amount == null) continue;
      cue.used = true;
      if (up) {
        above ??= amount;
      } else {
        below ??= amount;
      }
    }
    return (above, below);
  }

  /// The amount that starts at [start]: a number, maybe in groups of three
  /// (`5 000`), with `тыс` or `к`, and with a currency. Taken tokens are
  /// marked. `null` when there is none, when the number is a day of a month,
  /// as in `до 15 ноября`, or when it is no amount of money at all, such as
  /// one beyond what an amount can hold: the digits go into `Money.parse`,
  /// never into a `double` (ADR 0003).
  Money? _amountAt(List<AskToken> tokens, int start) {
    if (start >= tokens.length || !tokens[start].isNumber) return null;
    var end = start + 1;
    final digits = StringBuffer(tokens[start].text.replaceAll(',', '.'));
    while (end < tokens.length &&
        tokens[end].isNumber &&
        tokens[end].text.length == 3 &&
        !digits.toString().contains('.')) {
      digits.write(tokens[end].text);
      end++;
    }
    if (end < tokens.length && _monthOf(tokens[end].text) != null) return null;
    var text = digits.toString();
    if (end < tokens.length &&
        startsAny(tokens[end].text, ['тыс', 'тр', 'к', 'k', 'thousand'])) {
      text = _thousands(text);
      end++;
    }
    var currency = vocabulary.base ?? Currency.rub;
    if (end < tokens.length) {
      final named = currencyOf(tokens[end].text);
      if (named != null) {
        currency = named;
        end++;
      }
    }
    final Money amount;
    try {
      amount = Money.parse(text, currency);
    } on FormatException {
      return null;
    }
    for (var k = start; k < end; k++) {
      tokens[k].used = true;
    }
    return amount;
  }

  /// [decimal] times a thousand, written exactly: `1.5` gives `1500`.
  static String _thousands(String decimal) {
    final [whole, ...rest] = decimal.split('.');
    final fraction = rest.isEmpty ? '' : rest.first;
    final shifted = fraction.padRight(3, '0');
    final more = shifted.substring(3);
    return '$whole${shifted.substring(0, 3)}${more.isEmpty ? '' : '.$more'}';
  }

  // ---------------------------------------------------------------- periods

  static const _months = <String, int>{
    'январ': 1,
    'феврал': 2,
    'март': 3,
    'апрел': 4,
    'июн': 6,
    'июл': 7,
    'август': 8,
    'сентябр': 9,
    'октябр': 10,
    'ноябр': 11,
    'декабр': 12,
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };
  static const _mays = {'май', 'мая', 'мае', 'маю', 'may'};

  /// The number of the month that [word] names, or `null`.
  static int? _monthOf(String word) {
    if (_mays.contains(word)) return 5;
    for (final MapEntry(key: start, value: month) in _months.entries) {
      if (word.startsWith(start)) return month;
    }
    return null;
  }

  AskPeriod? _period(List<AskToken> tokens) =>
      _relative(tokens) ??
      _range(tokens) ??
      _last(tokens) ??
      _dayOfMonth(tokens) ??
      _month(tokens) ??
      _year(tokens);

  AskPeriod? _relative(List<AskToken> tokens) {
    for (final (i, token) in tokens.indexed) {
      final word = token.text;
      final day = switch (word) {
        'сегодня' || 'today' => _today,
        'вчера' || 'yesterday' => _today.addDays(-1),
        'позавчера' => _today.addDays(-2),
        _ => null,
      };
      if (day != null) {
        token.used = true;
        return AskPeriod.day(day);
      }
      if (i + 1 >= tokens.length) continue;
      final next = tokens[i + 1].text;
      final shift = startsAny(word, ['эт', 'текущ', 'this'])
          ? 0
          : startsAny(word, ['позапрошл'])
          ? -2
          : startsAny(word, ['прошл', 'предыдущ', 'last'])
          ? -1
          : null;
      if (shift == null) continue;
      final period = switch (next) {
        _ when startsAny(next, ['недел', 'week']) => AskPeriod.week(
          _today.addDays(7 * shift),
        ),
        _ when startsAny(next, ['месяц', 'month']) => AskPeriod.month(
          _today.monthStart(vocabulary.monthStart).addMonths(shift),
          start: vocabulary.monthStart,
        ),
        _ when startsAny(next, ['год', 'year']) => AskPeriod.year(
          _today.year + shift,
        ),
        _ => null,
      };
      if (period == null) continue;
      token.used = tokens[i + 1].used = true;
      return period;
    }
    return null;
  }

  /// `с 1 по 15 октября`, `с 1 октября по 15 ноября`, `с 1 октября`.
  AskPeriod? _range(List<AskToken> tokens) {
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (tokens[i].text != 'с' && tokens[i].text != 'since') continue;
      final from = tokens[i + 1].number;
      if (from == null || from < 1 || from > 31) continue;
      var j = i + 2;
      int? fromMonth;
      if (j < tokens.length) fromMonth = _monthOf(tokens[j].text);
      if (fromMonth != null) j++;
      int? to;
      int? toMonth;
      var end = j;
      if (j + 1 < tokens.length && tokens[j].text == 'по') {
        to = tokens[j + 1].number;
        end = j + 2;
        if (end < tokens.length) toMonth = _monthOf(tokens[end].text);
        if (toMonth != null) end++;
      }
      final firstMonth = fromMonth ?? toMonth ?? _today.month;
      final lastMonth = toMonth ?? fromMonth ?? _today.month;
      final first = _dateIn(firstMonth, from);
      final last = to == null ? _today : _dateIn(lastMonth, to, ahead: true);
      if (first == null || last == null) continue;
      for (var k = i; k < end; k++) {
        tokens[k].used = true;
      }
      return AskPeriod.range(first, last);
    }
    // `до 10 ноября`: from the start of that month to the day.
    for (var i = 0; i + 2 < tokens.length; i++) {
      final word = tokens[i].text;
      if (word != 'до' && word != 'по' && word != 'until') continue;
      final day = tokens[i + 1].number;
      final month = _monthOf(tokens[i + 2].text);
      if (day == null || month == null) continue;
      final last = _dateIn(month, day, ahead: true);
      if (last == null) continue;
      for (var k = i; k <= i + 2; k++) {
        tokens[k].used = true;
      }
      return AskPeriod.range(
        CivilDate(last.year, last.month, 1),
        last,
      );
    }
    return null;
  }

  /// `за 30 дней`, `за последние 3 месяца`, `за неделю`, `last 2 weeks`.
  AskPeriod? _last(List<AskToken> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final word = tokens[i].text;
      if (word != 'за' && !word.startsWith('последн') && word != 'last') {
        continue;
      }
      var j = i + 1;
      if (j < tokens.length && tokens[j].text.startsWith('последн')) j++;
      final count = j < tokens.length ? tokens[j].number : null;
      if (count != null) j++;
      if (j >= tokens.length) continue;
      final unit = tokens[j].text;
      final n = count ?? 1;
      final period = switch (unit) {
        _ when startsAny(unit, ['дн', 'день', 'day']) =>
          count == null ? AskPeriod.day(_today) : AskPeriod.lastDays(_today, n),
        _ when startsAny(unit, ['недел', 'week']) => AskPeriod.lastDays(
          _today,
          7 * n,
        ),
        _ when startsAny(unit, ['месяц', 'month']) =>
          count == null
              ? AskPeriod.month(_today, start: vocabulary.monthStart)
              : AskPeriod.months(
                  _today.monthStart(vocabulary.monthStart).addMonths(-1),
                  n,
                  start: vocabulary.monthStart,
                ),
        _ when startsAny(unit, ['год', 'лет', 'year']) =>
          count == null
              ? AskPeriod.year(_today.year)
              : AskPeriod.range(
                  CivilDate.onDay(_today.year - n, _today.month, _today.day),
                  _today,
                ),
        _ => null,
      };
      if (period == null) continue;
      for (var k = i; k <= j; k++) {
        tokens[k].used = true;
      }
      return period;
    }
    return null;
  }

  /// `8 ноября`, `8.11`, `08.11.2025`.
  AskPeriod? _dayOfMonth(List<AskToken> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final dotted = RegExp(
        r'^(\d{1,2})\.(\d{1,2})(?:\.(\d{2,4}))?$',
      ).firstMatch(token.text);
      if (dotted != null) {
        final year = dotted.group(3);
        final date = _dateIn(
          int.parse(dotted.group(2)!),
          int.parse(dotted.group(1)!),
          year: year == null
              ? null
              : (year.length == 2 ? 2000 + int.parse(year) : int.parse(year)),
        );
        if (date == null) continue;
        token.used = true;
        return AskPeriod.day(date);
      }
      final day = token.number;
      if (day == null || day < 1 || day > 31 || i + 1 >= tokens.length) {
        continue;
      }
      final month = _monthOf(tokens[i + 1].text);
      if (month == null) continue;
      final year = i + 2 < tokens.length ? _yearOf(tokens[i + 2]) : null;
      final date = _dateIn(month, day, year: year);
      if (date == null) continue;
      token.used = tokens[i + 1].used = true;
      if (year != null) tokens[i + 2].used = true;
      return AskPeriod.day(date);
    }
    return null;
  }

  /// `в октябре`, `за май 2025`, `october`.
  AskPeriod? _month(List<AskToken> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.used) continue;
      final month = _monthOf(token.text);
      if (month == null) continue;
      final year = i + 1 < tokens.length ? _yearOf(tokens[i + 1]) : null;
      // A month not yet come this year is the one of the last year.
      final inYear =
          year ?? (month > _today.month ? _today.year - 1 : _today.year);
      token.used = true;
      if (year != null) tokens[i + 1].used = true;
      return AskPeriod.month(
        CivilDate(inYear, month, vocabulary.monthStart),
        start: vocabulary.monthStart,
      );
    }
    return null;
  }

  /// `в 2025 году`, `2025`.
  AskPeriod? _year(List<AskToken> tokens) {
    for (final token in tokens) {
      final year = _yearOf(token);
      if (year == null) continue;
      token.used = true;
      return AskPeriod.year(year);
    }
    return null;
  }

  int? _yearOf(AskToken token) {
    final year = token.number;
    if (year == null || year < 2000 || year > _today.year) return null;
    return year;
  }

  /// Day [day] of [month] in [year], or in the latest year that has it on or
  /// before today, or in this year when it may lie [ahead], as the end of a
  /// range; `null` when there is no such day.
  CivilDate? _dateIn(int month, int day, {int? year, bool ahead = false}) {
    bool exists(int y) =>
        DateTime.utc(y, month, day).day == day &&
        month >= 1 &&
        month <= 12 &&
        day >= 1;
    if (year != null) return exists(year) ? CivilDate(year, month, day) : null;
    if (!exists(_today.year)) {
      return exists(_today.year - 1)
          ? CivilDate(_today.year - 1, month, day)
          : null;
    }
    final date = CivilDate(_today.year, month, day);
    return !ahead && date.compareTo(_today) > 0
        ? (exists(_today.year - 1)
              ? CivilDate(_today.year - 1, month, day)
              : null)
        : date;
  }

  // ---------------------------------------------------------------- words

  static bool _has(List<AskToken> tokens, String word) =>
      tokens.any((token) => token.text == word);

  /// Whether [words] come one after another in [tokens].
  static bool _phrase(List<AskToken> tokens, List<String> words) {
    for (var i = 0; i + words.length <= tokens.length; i++) {
      var all = true;
      for (var k = 0; k < words.length; k++) {
        if (tokens[i + k].text != words[k]) {
          all = false;
          break;
        }
      }
      if (all) return true;
    }
    return false;
  }
}
