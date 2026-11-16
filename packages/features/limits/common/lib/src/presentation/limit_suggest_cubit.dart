import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/src/domain/limits_repository.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Where the offer of limits stands.
enum LimitSuggestStatus {
  /// The averages are on their way.
  loading,

  /// The limits are offered.
  ready,

  /// No full month before this one spent anything yet.
  short,

  /// Every category that spent already has a limit.
  nothing,

  /// The picked limits are on their way into the ledger.
  saving,

  /// They are set.
  saved,

  /// The ledger refused them.
  failed,
}

/// Limits offered from the average spending of the three full months before
/// this one (ADR 0033).
@immutable
final class LimitSuggestState {
  /// Creates the state.
  const LimitSuggestState({
    required this.status,
    required this.month,
    this.suggestions = const [],
    this.picked = const {},
    this.step = const Money.zero(Currency.rub),
    this.saved = 0,
  });

  /// Where the offer stands.
  final LimitSuggestStatus status;

  /// The first day of this month.
  final CivilDate month;

  /// The limits offered, the checked ones first.
  final List<LimitSuggestion> suggestions;

  /// The categories whose limits are checked.
  final Set<String> picked;

  /// The step the limits are rounded up to.
  final Money step;

  /// How many limits the last save set.
  final int saved;

  /// The first days of the three months the averages come from.
  List<CivilDate> get months => fullMonthsBefore(month);

  /// The day a full month before this one is first there: the start of the
  /// next month.
  CivilDate get nextFull => month.addMonths(1);

  /// Whether the checked limits can be set.
  bool get canSave =>
      (status == LimitSuggestStatus.ready ||
          status == LimitSuggestStatus.failed) &&
      picked.isNotEmpty;

  /// A copy with the given fields changed.
  LimitSuggestState copyWith({
    LimitSuggestStatus? status,
    Set<String>? picked,
    int? saved,
  }) => LimitSuggestState(
    status: status ?? this.status,
    month: month,
    suggestions: suggestions,
    picked: picked ?? this.picked,
    step: step,
    saved: saved ?? this.saved,
  );
}

/// Offers limits from averages and sets the checked ones.
final class LimitSuggestCubit extends Cubit<LimitSuggestState> {
  /// Creates the offer on [_repository].
  LimitSuggestCubit(this._repository)
    : super(
        LimitSuggestState(
          status: LimitSuggestStatus.loading,
          month: _repository.today().monthStart(),
        ),
      ) {
    unawaited(_load());
  }

  final LimitsRepository _repository;

  Future<void> _load() async {
    try {
      final start = await _repository.watchMonthStart().first;
      final month = _repository.today().monthStart(start);
      final (categories, rates, rows, shown, regular) = await (
        _repository.watchCategories().first,
        _repository.watchRates().first,
        _repository
            .watchSpending(from: month.addMonths(-3), to: month.addDays(-1))
            .first,
        _repository.watchShownCurrency().first,
        _repository.watchRegular().first,
      ).wait;
      final suggestions = suggestLimits(
        categories,
        rows,
        rates,
        currency: shown,
        month: month,
        regular: regular,
      );
      if (isClosed) return;
      emit(
        LimitSuggestState(
          status: suggestions.isNotEmpty
              ? LimitSuggestStatus.ready
              : rows.isEmpty
              ? LimitSuggestStatus.short
              : LimitSuggestStatus.nothing,
          month: month,
          suggestions: suggestions,
          picked: {
            for (final suggestion in suggestions)
              if (suggestion.picked) suggestion.category.id,
          },
          step: limitStep(rates, shown),
        ),
      );
    } on Object {
      if (!isClosed) {
        emit(state.copyWith(status: LimitSuggestStatus.failed));
      }
    }
  }

  /// Checks the limit of [categoryId], or unchecks it.
  void toggle(String categoryId) {
    final picked = {...state.picked};
    if (!picked.remove(categoryId)) picked.add(categoryId);
    emit(state.copyWith(picked: picked));
  }

  /// Sets the checked limits.
  Future<void> save() async {
    if (!state.canSave) return;
    final chosen = [
      for (final suggestion in state.suggestions)
        if (state.picked.contains(suggestion.category.id)) suggestion,
    ];
    emit(state.copyWith(status: LimitSuggestStatus.saving));
    try {
      for (final suggestion in chosen) {
        await _repository.setLimit(
          suggestion.category.id,
          CategoryLimit(suggestion.offer),
        );
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            status: LimitSuggestStatus.saved,
            saved: chosen.length,
          ),
        );
      }
    } on Object {
      if (!isClosed) emit(state.copyWith(status: LimitSuggestStatus.failed));
    }
  }
}
