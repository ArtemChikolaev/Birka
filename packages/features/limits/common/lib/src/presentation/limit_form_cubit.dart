import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/src/domain/limits_repository.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Where the form of a limit stands.
enum LimitFormStatus {
  /// What it needs is on its way.
  loading,

  /// The person fills it in.
  editing,

  /// The limit is on its way into the ledger.
  saving,

  /// The limit is set.
  saved,

  /// The limit is taken away.
  removed,

  /// The ledger refused it.
  failed,
}

/// The form of a monthly limit: its category, sum and currency, what the
/// category spent on average, and whether to say so early (ADR 0033).
@immutable
final class LimitFormState {
  /// Creates the state.
  const LimitFormState({
    required this.status,
    required this.today,
    required this.month,
    this.monthStart = 1,
    this.categories = const [],
    this.categoryId,
    this.editing = false,
    this.amount,
    this.currency = Currency.rub,
    this.currencies = const [Currency.rub],
    this.warnEarly = true,
    this.suggestion,
    this.took = false,
    this.spent,
  });

  /// Where the form stands.
  final LimitFormStatus status;

  /// Today.
  final CivilDate today;

  /// The first day of this month.
  final CivilDate month;

  /// The day the month starts on.
  final int monthStart;

  /// The categories the form can pick: top categories of expenses without a
  /// limit, and the one whose limit it changes.
  final List<Category> categories;

  /// The picked category.
  final String? categoryId;

  /// Whether the form changes a limit that is already set.
  final bool editing;

  /// The sum of a month, in [currency].
  final Money? amount;

  /// The currency of the limit.
  final Currency currency;

  /// The currencies the limit can be in, the shown one first.
  final List<Currency> currencies;

  /// Whether Birka says so once 80 % is gone.
  final bool warnEarly;

  /// What the category spent on average in the three months before, in
  /// [currency], with the limit Birka offers.
  final LimitSuggestion? suggestion;

  /// Whether [amount] came from the offer.
  final bool took;

  /// What this month took of the category so far, in [currency].
  final Money? spent;

  /// The picked category.
  Category? get category =>
      categories.where((category) => category.id == categoryId).firstOrNull;

  /// Whether the limit can be saved.
  bool get canSave =>
      (status == LimitFormStatus.editing || status == LimitFormStatus.failed) &&
      category != null &&
      (amount?.isPositive ?? false);

  /// The 80 % of [amount] that Birka says so at.
  Money? get warnAt => switch (amount) {
    final amount? => Money((amount.minorUnits * 4 / 5).round(), currency),
    null => null,
  };

  /// Whether [amount] is what Birka offers.
  bool get asOffered => amount != null && amount == suggestion?.offer;

  /// A copy with the given fields changed.
  LimitFormState copyWith({
    LimitFormStatus? status,
    String? categoryId,
    Money? Function()? amount,
    Currency? currency,
    bool? warnEarly,
    LimitSuggestion? Function()? suggestion,
    bool? took,
    Money? Function()? spent,
  }) => LimitFormState(
    status: status ?? this.status,
    today: today,
    month: month,
    monthStart: monthStart,
    categories: categories,
    categoryId: categoryId ?? this.categoryId,
    editing: editing,
    amount: amount == null ? this.amount : amount(),
    currency: currency ?? this.currency,
    currencies: currencies,
    warnEarly: warnEarly ?? this.warnEarly,
    suggestion: suggestion == null ? this.suggestion : suggestion(),
    took: took ?? this.took,
    spent: spent == null ? this.spent : spent(),
  );
}

/// Sets, changes or takes away the monthly limit of a category.
final class LimitFormCubit extends Cubit<LimitFormState> {
  /// Creates the form on [_repository]: for the limit of [categoryId] when
  /// that category has one, else for a new limit, of [categoryId] when given.
  LimitFormCubit(this._repository, {String? categoryId})
    : super(
        LimitFormState(
          status: LimitFormStatus.loading,
          today: _repository.today(),
          month: _repository.today().monthStart(),
        ),
      ) {
    unawaited(_load(categoryId));
  }

  final LimitsRepository _repository;
  RateBook _rates = const RateBook.empty();
  List<CategoryDayTotal> _rows = const [];
  Set<String> _regular = const {};

  Future<void> _load(String? id) async {
    try {
      final start = await _repository.watchMonthStart().first;
      final today = _repository.today();
      final month = today.monthStart(start);
      final (categories, rates, rows, shown, regular, currencies) = await (
        _repository.watchCategories().first,
        _repository.watchRates().first,
        _repository
            .watchSpending(
              from: month.addMonths(-3),
              to: month.addMonths(1).addDays(-1),
            )
            .first,
        _repository.watchShownCurrency().first,
        _repository.watchRegular().first,
        _repository.currencies(),
      ).wait;
      _rates = rates;
      _rows = rows;
      _regular = regular;
      final edited = categories.where((c) => c.id == id).firstOrNull;
      final choices = [
        for (final category in categories)
          if (category.parentId == null &&
              (category.limit == null || category.id == edited?.id))
            category,
      ];
      final limit = edited?.limit;
      final currency = limit?.amount.currency ?? shown;
      if (isClosed) return;
      emit(
        _counted(
          LimitFormState(
            status: LimitFormStatus.editing,
            today: today,
            month: month,
            monthStart: start,
            categories: choices,
            categoryId: edited?.id ?? choices.firstOrNull?.id,
            editing: limit != null,
            amount: limit?.amount,
            currency: currency,
            currencies: [
              currency,
              for (final other in currencies)
                if (other != currency) other,
            ],
            warnEarly: limit?.warnEarly ?? true,
          ),
        ),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: LimitFormStatus.failed));
    }
  }

  // The average of the three months before and the spending of this month,
  // for the picked category in the currency of the limit.
  LimitFormState _counted(LimitFormState next) {
    final category = next.category;
    if (category == null) {
      return next.copyWith(suggestion: () => null, spent: () => null);
    }
    return next.copyWith(
      suggestion: () => suggestLimit(
        category,
        _rows,
        _rates,
        currency: next.currency,
        month: next.month,
        regular: _regular.contains(category.id),
      ),
      spent: () => spendingOf(
        category,
        _rows,
        _rates,
        next.currency,
        from: next.month,
        until: next.today.addDays(1),
      ),
    );
  }

  /// Picks the category of a new limit.
  void categoryPicked(String id) {
    if (state.editing || id == state.categoryId) return;
    emit(
      _counted(
        state.copyWith(categoryId: id, amount: () => null, took: false),
      ),
    );
  }

  /// Takes the sum the person typed.
  void amountChanged(Money? amount) {
    final sum = amount == null
        ? null
        : Money(amount.minorUnits, state.currency);
    emit(state.copyWith(amount: () => sum, took: false));
  }

  /// Moves the limit into [currency]: the sum goes there at the rate of
  /// today, rounded to the step of that currency, instead of keeping its
  /// number.
  void currencyPicked(Currency currency) {
    if (currency == state.currency) return;
    final amount = state.amount;
    Money? moved;
    if (amount != null) {
      final there = _rates.convert(amount, currency);
      if (there != null) {
        final step = limitStep(_rates, currency).minorUnits;
        final rounded = (there.minorUnits / step).round() * step;
        moved = Money(rounded > 0 ? rounded : step, currency);
      }
    }
    emit(
      _counted(
        state.copyWith(currency: currency, amount: () => moved, took: false),
      ),
    );
  }

  /// Takes the limit Birka offers from the average.
  void takeOffer() {
    final offer = state.suggestion?.offer;
    if (offer == null) return;
    emit(state.copyWith(amount: () => offer, took: true));
  }

  /// Turns the early word on or off.
  void warnChanged({required bool on}) => emit(state.copyWith(warnEarly: on));

  /// Sets the limit.
  Future<void> save() async {
    final category = state.category;
    final amount = state.amount;
    if (!state.canSave || category == null || amount == null) return;
    emit(state.copyWith(status: LimitFormStatus.saving));
    try {
      await _repository.setLimit(
        category.id,
        CategoryLimit(amount, warnEarly: state.warnEarly),
      );
      if (!isClosed) emit(state.copyWith(status: LimitFormStatus.saved));
    } on Object {
      if (!isClosed) emit(state.copyWith(status: LimitFormStatus.failed));
    }
  }

  /// Takes the limit away.
  Future<void> remove() async {
    final category = state.category;
    if (!state.editing || category == null) return;
    emit(state.copyWith(status: LimitFormStatus.saving));
    try {
      await _repository.setLimit(category.id, null);
      if (!isClosed) emit(state.copyWith(status: LimitFormStatus.removed));
    } on Object {
      if (!isClosed) emit(state.copyWith(status: LimitFormStatus.failed));
    }
  }
}
