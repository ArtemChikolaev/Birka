import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:limits_common/src/domain/limits_repository.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Whether the limits came.
enum LimitsStatus {
  /// They are on their way.
  loading,

  /// They are here.
  ready,

  /// The ledger could not give them.
  failed,
}

/// A category of expenses without a limit, with what this month took.
@immutable
final class FreeCategory {
  /// Creates the entry of [category].
  const FreeCategory(this.category, this.spent, {this.regular = false});

  /// The category.
  final Category category;

  /// What this month took, in the shown currency when it converts.
  final Money spent;

  /// Whether regular payments go to it.
  final bool regular;
}

/// The limits of this month and the categories without one (ADR 0033).
@immutable
final class LimitsState {
  /// Creates the state.
  const LimitsState({
    required this.status,
    required this.today,
    required this.month,
    this.limits = const [],
    this.free = const [],
    this.shown = Currency.rub,
  });

  /// Whether the limits came.
  final LimitsStatus status;

  /// Today.
  final CivilDate today;

  /// The first day of this month, as the month start sets it.
  final CivilDate month;

  /// The limits, over first and then the nearest to their end.
  final List<LimitProgress> limits;

  /// The categories without a limit that this month spent in, the largest
  /// first.
  final List<FreeCategory> free;

  /// The currency the totals are shown in.
  final Currency shown;

  /// The last day of this month.
  CivilDate get end => month.addMonths(1).addDays(-1);

  /// The day the limits start anew.
  CivilDate get next => month.addMonths(1);

  /// How many days are left in the month, today among them.
  int get daysLeft => today.daysUntil(end) + 1;

  /// How many limits the month went over.
  int get over => limits.where((l) => l.state == LimitState.over).length;

  /// How many limits the month stays within.
  int get within => limits.length - over;
}

/// Follows the limits of this month and what each took.
final class LimitsCubit extends Cubit<LimitsState> {
  /// Creates the cubit on [_repository].
  LimitsCubit(this._repository)
    : super(
        LimitsState(
          status: LimitsStatus.loading,
          today: _repository.today(),
          month: _repository.today().monthStart(),
        ),
      ) {
    _subscriptions.addAll([
      _repository.watchMonthStart().listen((day) {
        _monthStart = day;
        _follow();
      }, onError: _failed),
      _repository.watchCategories().listen((categories) {
        _categories = categories;
        _update();
      }, onError: _failed),
      _repository.watchRates().listen((rates) {
        _rates = rates;
        _update();
      }, onError: (Object _) {}),
      _repository.watchShownCurrency().listen((shown) {
        _shown = shown;
        _update();
      }, onError: (Object _) {}),
      _repository.watchRegular().listen((regular) {
        _regular = regular;
        _update();
      }, onError: (Object _) {}),
    ]);
  }

  final LimitsRepository _repository;
  final _subscriptions = <StreamSubscription<Object?>>[];
  StreamSubscription<List<CategoryDayTotal>>? _spending;
  int? _monthStart;
  CivilDate? _month;
  List<Category>? _categories;
  List<CategoryDayTotal>? _rows;
  RateBook _rates = const RateBook.empty();
  Currency _shown = Currency.rub;
  Set<String> _regular = const {};

  void _failed(Object _) {
    if (isClosed) return;
    emit(
      LimitsState(
        status: LimitsStatus.failed,
        today: state.today,
        month: state.month,
      ),
    );
  }

  // Follows the spending of the month of today, and of the next one once
  // today is in it.
  void _follow() {
    final start = _monthStart;
    if (start == null || isClosed) return;
    final month = _repository.today().monthStart(start);
    if (month == _month && _spending != null) return;
    _month = month;
    _rows = null;
    unawaited(_spending?.cancel());
    _spending = _repository
        .watchSpending(from: month, to: month.addMonths(1).addDays(-1))
        .listen((rows) {
          _rows = rows;
          _update();
        }, onError: _failed);
  }

  /// Counts again for the day it is now, as when the app comes back after
  /// midnight.
  void refresh() {
    _follow();
    _update();
  }

  void _update() {
    final rows = _rows;
    final categories = _categories;
    final month = _month;
    if (rows == null || categories == null || month == null || isClosed) {
      return;
    }
    final today = _repository.today();
    final limited = {
      for (final category in categories)
        if (category.limit != null) category.id,
    };
    final open = {for (final category in categories) category.id};
    final spent = [
      for (final row in rows)
        if (row.category case final category?
            when !limited.contains(category.id) &&
                open.contains(category.id) &&
                row.day.compareTo(today) <= 0)
          row,
    ];
    emit(
      LimitsState(
        status: LimitsStatus.ready,
        today: today,
        month: month,
        limits: limitsProgress(
          categories,
          rows,
          _rates,
          month: month,
          today: today,
        ),
        free: [
          for (final total in totalsIn(_shown, spent, _rates))
            if (total.category case final category?)
              FreeCategory(
                category,
                total.total,
                regular: _regular.contains(category.id),
              ),
        ],
        shown: _shown,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _spending?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
