import 'dart:async';

import 'package:ask_common/src/domain/ask_answer.dart';
import 'package:ask_common/src/domain/ask_parser.dart';
import 'package:ask_common/src/domain/ask_period.dart';
import 'package:ask_common/src/domain/ask_query.dart';
import 'package:ask_common/src/domain/ask_reading.dart';
import 'package:ask_common/src/domain/ask_repository.dart';
import 'package:ask_common/src/presentation/ask_labels.dart';
import 'package:bloc/bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// What «Спросить» shows (ADR 0028).
@immutable
final class AskState {
  /// Creates a state on [today].
  const AskState({
    required this.today,
    this.text = '',
    this.reading,
    this.answer,
    this.recent = const [],
    this.names = const AskNames(),
    this.capital,
    this.balances = const [],
    this.rates = const RateBook.empty(),
    this.currency = Currency.rub,
    this.monthStart = 1,
  });

  /// The day of the device.
  final CivilDate today;

  /// The question as it stands in the field.
  final String text;

  /// What the question was read as, or `null` while there is none.
  final AskReading? reading;

  /// What the ledger says to a question about money, once it is counted.
  final AskAnswer? answer;

  /// The questions asked last, the latest first.
  final List<String> recent;

  /// The names of the categories, метки and accounts.
  final AskNames names;

  /// What the accounts hold together.
  final Capital? capital;

  /// The accounts with what each holds.
  final List<AccountBalance> balances;

  /// The rates on the device.
  final RateBook rates;

  /// The currency of the totals.
  final Currency currency;

  /// The day that months start on.
  final int monthStart;

  /// Whether a question about money waits for the ledger.
  bool get counting => reading is AskData && answer == null;

  /// The plaques of what the question about money was read as.
  List<AskChip> get chips => switch (reading) {
    AskData(:final query) => askChips(query, names, today: today),
    _ => const [],
  };

  /// What one unit of the currency of a rate comes to in [currency] by the
  /// latest rate, or `null` without it.
  Money? get rate {
    final reading = this.reading;
    if (reading is! AskFactReading) return null;
    final asked = reading.currency;
    if (asked == null || asked == currency) return null;
    var unit = 1;
    for (var i = 0; i < asked.decimalDigits; i++) {
      unit *= 10;
    }
    return rates.convert(Money(unit, asked), currency);
  }

  /// The periods that the plaque of the days offers: this month and the two
  /// before it, the last three whole months and this year, with the one in
  /// use first when it is none of them.
  List<AskPeriod> get periods {
    final choices = [
      AskPeriod.month(today, start: monthStart).upTo(today),
      for (final back in [1, 2])
        AskPeriod.month(
          today.monthStart(monthStart).addMonths(-back),
          start: monthStart,
        ),
      AskPeriod.months(
        today.monthStart(monthStart).addMonths(-1),
        3,
        start: monthStart,
      ),
      AskPeriod.year(today.year).upTo(today),
    ];
    final current = switch (reading) {
      AskData(:final query) => query.period,
      _ => null,
    };
    if (current == null || choices.contains(current)) return choices;
    return [current, ...choices];
  }

  /// The state with the parts that differ.
  AskState copyWith({
    CivilDate? today,
    String? text,
    AskReading? Function()? reading,
    AskAnswer? Function()? answer,
    List<String>? recent,
    AskNames? names,
    Capital? Function()? capital,
    List<AccountBalance>? balances,
    RateBook? rates,
    Currency? currency,
    int? monthStart,
  }) => AskState(
    today: today ?? this.today,
    text: text ?? this.text,
    reading: reading == null ? this.reading : reading(),
    answer: answer == null ? this.answer : answer(),
    recent: recent ?? this.recent,
    names: names ?? this.names,
    capital: capital == null ? this.capital : capital(),
    balances: balances ?? this.balances,
    rates: rates ?? this.rates,
    currency: currency ?? this.currency,
    monthStart: monthStart ?? this.monthStart,
  );
}

/// Reads a question as it is typed and counts the answer in the ledger,
/// which it follows as it changes (ADR 0028).
final class AskCubit extends Cubit<AskState> {
  /// Creates the cubit on [_repository]. [help] gives the common questions
  /// of the help in the language of the app.
  AskCubit(this._repository, {List<HelpQuestion> Function()? help})
    : _help = help ?? helpQuestions,
      super(
        AskState(today: _repository.today(), recent: _repository.recent()),
      ) {
    void ignore(Object _) {}
    _subscriptions.addAll([
      _repository
          .watchCategories(CategoryKind.expense)
          .listen(
            (categories) => _learn(expenses: categories),
            onError: ignore,
          ),
      _repository
          .watchCategories(CategoryKind.income)
          .listen((categories) => _learn(income: categories), onError: ignore),
      _repository.watchTags().listen(
        (tags) => _learn(tags: tags),
        onError: ignore,
      ),
      _repository.watchBalances().listen(_balancesChanged, onError: ignore),
      _repository.watchRates().listen(_ratesChanged, onError: ignore),
      _repository.watchBaseCurrency().listen((base) {
        _base = base;
        _learn();
      }, onError: ignore),
      _repository.watchMonthStart().listen((start) {
        if (isClosed) return;
        emit(state.copyWith(monthStart: start));
        _learn();
      }, onError: ignore),
    ]);
  }

  final AskRepository _repository;
  final List<HelpQuestion> Function() _help;
  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<List<Transaction>>? _counting;
  List<Category> _expenses = const [];
  List<Category> _income = const [];
  List<Tag> _tags = const [];
  Currency? _base;
  List<Transaction>? _transactions;
  AskPeriod? _chosen;

  /// Reads [text] as it stands in the field, and counts it when it is about
  /// money.
  void ask(String text) {
    _chosen = null;
    emit(state.copyWith(text: text, today: _repository.today()));
    _read();
  }

  /// Counts the question about money again over [period].
  void choosePeriod(AskPeriod period) {
    if (state.reading is! AskData) return;
    _chosen = period.upTo(state.today);
    _read();
  }

  /// Keeps the question in the field among the questions asked last, when
  /// it was read as something.
  Future<void> remember() async {
    final text = state.text.trim();
    if (text.isEmpty || state.reading == null || state.reading is AskUnknown) {
      return;
    }
    final recent = [
      text,
      for (final question in state.recent)
        if (searchKey(question) != searchKey(text)) question,
    ].take(5).toList();
    emit(state.copyWith(recent: recent));
    await _repository.keepRecent(recent);
  }

  /// Forgets the questions asked last.
  Future<void> forget() async {
    emit(state.copyWith(recent: const []));
    await _repository.keepRecent(const []);
  }

  void _learn({
    List<Category>? expenses,
    List<Category>? income,
    List<Tag>? tags,
  }) {
    if (isClosed) return;
    _expenses = expenses ?? _expenses;
    _income = income ?? _income;
    _tags = tags ?? _tags;
    emit(
      state.copyWith(
        names: AskNames(
          categories: {
            for (final category in [..._expenses, ..._income])
              category.id: category,
          },
          tags: {for (final tag in _tags) tag.id: tag},
          accounts: {
            for (final AccountBalance(:account) in state.balances)
              account.id: account,
          },
        ),
        currency: _currency(state.balances),
      ),
    );
    // The currency of the totals may have changed while the question stayed
    // the same, so the answer is counted again.
    if (state.text.isNotEmpty) {
      _read();
      _count();
    }
  }

  void _balancesChanged(List<AccountBalance> balances) {
    if (isClosed) return;
    emit(
      state.copyWith(
        balances: balances,
        capital: () => Capital.of(
          balances,
          rates: state.rates,
          base: _base,
        ),
        currency: _currency(balances),
      ),
    );
    _learn();
  }

  void _ratesChanged(RateBook rates) {
    if (isClosed) return;
    emit(
      state.copyWith(
        rates: rates,
        capital: () => Capital.of(state.balances, rates: rates, base: _base),
      ),
    );
    _count();
  }

  Currency _currency(List<AccountBalance> balances) =>
      _base ??
      balances
          .where((balance) => balance.account.includeInTotals)
          .firstOrNull
          ?.account
          .currency ??
      Currency.rub;

  void _read() {
    if (isClosed) return;
    final parser = AskParser(
      AskVocabulary(
        today: state.today,
        categories: [..._expenses, ..._income],
        tags: _tags,
        accounts: [
          for (final AccountBalance(:account) in state.balances) account,
        ],
        monthStart: state.monthStart,
        base: state.currency,
      ),
      help: _help(),
    );
    var reading = parser.read(state.text);
    final chosen = _chosen;
    if (reading is AskData && chosen != null) {
      reading = AskData(
        reading.query.withPeriod(chosen),
        places: reading.places,
      );
    }
    final previous = state.reading;
    final same =
        previous is AskData &&
        reading is AskData &&
        previous.query.toString() == reading.query.toString();
    emit(
      state.copyWith(
        reading: () => reading,
        answer: same ? null : () => null,
      ),
    );
    if (reading is AskData) {
      if (!same) _watch(reading.query);
    } else {
      unawaited(_counting?.cancel());
      _counting = null;
      _transactions = null;
    }
  }

  void _watch(AskQuery query) {
    unawaited(_counting?.cancel());
    _transactions = null;
    final period = query.period;
    final before = period?.before;
    _counting = _repository
        .watchTransactions(
          from: before?.first,
          to: period?.last,
          tagId: query.tagId,
        )
        .listen((transactions) {
          _transactions = transactions;
          _count();
        }, onError: (Object _) {});
  }

  void _count() {
    final reading = state.reading;
    final transactions = _transactions;
    if (isClosed || reading is! AskData || transactions == null) return;
    emit(
      state.copyWith(
        answer: () => answerOf(
          reading.query,
          transactions: transactions,
          categories: [..._expenses, ..._income],
          rates: state.rates,
          currency: state.currency,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _counting?.cancel();
    return super.close();
  }
}
