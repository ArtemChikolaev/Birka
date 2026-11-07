import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';
import 'package:schedules_common/src/domain/spending_plan.dart';

/// An account that the money of the days can count. It is locked when it is
/// in another currency than the totals, which the plan cannot add up yet.
typedef CountedAccount = ({
  AccountBalance row,
  bool counted,
  bool locked,
});

/// Everything the regular payments show, as it is now.
@immutable
final class SchedulesView {
  /// Creates the view of [schedules] on [today].
  SchedulesView({
    required this.today,
    required this.schedules,
    required this.accounts,
    required this.categories,
    required this.base,
    required this.settings,
    required this.todays,
    this.imports = const [],
    this.monthStart = 1,
  });

  /// The day it shows.
  final CivilDate today;

  /// The regular payments, the nearest first.
  final List<Schedule> schedules;

  /// The accounts, archived ones included.
  final List<AccountBalance> accounts;

  /// The categories of both kinds by their ids.
  final Map<String, Category> categories;

  /// The currency of the totals: the picked one, or that of the first
  /// account. `null` without accounts.
  final Currency? base;

  /// How this device counts the money of the days.
  final PaydaySettings settings;

  /// The transactions of today.
  final List<Transaction> todays;

  /// The imports whose transactions the ledger holds.
  final List<LedgerImport> imports;

  /// The day of the calendar that the months start on (ADR 0024).
  final int monthStart;

  /// The accounts by their ids.
  late final Map<String, Account> accountsById = {
    for (final row in accounts) row.account.id: row.account,
  };

  /// The payments that a statement brought today, with the import of the
  /// statement when the ledger still lists it.
  late final List<({Schedule schedule, LedgerImport? import})> found = () {
    final byId = {for (final import in imports) import.id: import};
    return [
      for (final schedule in schedules)
        if (schedule.last case ScheduleLast(
          done: ScheduleDone.found,
          :final importId,
        ) when doneToday(schedule))
          (schedule: schedule, import: byId[importId]),
    ];
  }();

  /// Whether something was done to [schedule] today, so that its line says
  /// what rather than how often it comes.
  bool doneToday(Schedule schedule) => switch (schedule.last) {
    final last? => CivilDate.of(last.at.toLocal()) == today,
    null => false,
  };

  /// The payments that wait for the person: those that ask, whose day has
  /// come.
  late final List<Schedule> waiting = [
    for (final schedule in schedules)
      if (schedule.onDay == ScheduleOnDay.ask && schedule.isDue(today))
        schedule,
  ];

  /// The times of the next 30 days, today included, apart from those that
  /// wait, the earliest first.
  late final List<Occurrence> ahead = () {
    final end = today.addDays(29);
    final waits = {for (final schedule in waiting) schedule.id};
    return [
      for (final schedule in schedules)
        for (final on in schedule.timesUntil(end))
          if (on.compareTo(today) >= 0 &&
              !(waits.contains(schedule.id) && on == schedule.next))
            (schedule: schedule, on: on),
    ]..sort((a, b) => a.on.compareTo(b.on));
  }();

  /// The nearest times from today on, the ones that wait first.
  late final List<Occurrence> upcoming = [
    for (final schedule in waiting) (schedule: schedule, on: schedule.next),
    ...ahead,
  ];

  /// Every regular payment: the incomes first, then the nearest first.
  late final List<Schedule> all = [
    ...schedules.where((it) => it.kind == TransactionKind.income),
    ...schedules.where((it) => it.kind != TransactionKind.income),
  ];

  /// The accounts that the money of the days can count, archived ones left
  /// out, the counted ones marked.
  late final List<CountedAccount> countable = [
    for (final row in accounts)
      if (!row.account.archived)
        (
          row: row,
          counted: row.account.currency == base && _counts(row.account),
          locked: row.account.currency != base,
        ),
  ];

  /// The accounts that the money of the days counts.
  late final List<AccountBalance> counted = [
    for (final it in countable)
      if (it.counted) it.row,
  ];

  /// How much can be spent each day, or `null` without accounts or when it
  /// counts until a salary that no regular income brings.
  late final SpendingPlan? plan = switch (base) {
    final base? => SpendingPlan.of(
      today: today,
      until: settings.until,
      currency: base,
      schedules: schedules,
      counted: counted,
      todays: todays,
      aside: Money(settings.asideMinor, base),
      monthStart: monthStart,
    ),
    null => null,
  };

  /// The regular income that brings the next salary to a counted account, its
  /// advance aside.
  late final Schedule? salary = () {
    final ids = {for (final row in counted) row.account.id};
    Schedule? found;
    CivilDate? first;
    for (final schedule in schedules) {
      if (schedule.kind != TransactionKind.income ||
          !ids.contains(schedule.accountId)) {
        continue;
      }
      var time = schedule.next;
      while (time.compareTo(today) <= 0 || schedule.isAdvance(time)) {
        time = schedule.after(time);
      }
      if (first == null || time.compareTo(first) < 0) {
        first = time;
        found = schedule;
      }
    }
    return found;
  }();

  bool _counts(Account account) => switch (settings.accounts) {
    final ids? => ids.contains(account.id),
    null =>
      account.type == AccountType.debit || account.type == AccountType.cash,
  };
}

/// What the regular payments show.
@immutable
sealed class SchedulesState {
  const SchedulesState();
}

/// The first read has not come back yet.
final class SchedulesLoading extends SchedulesState {
  /// Creates the state.
  const SchedulesLoading();
}

/// The regular payments are here.
final class SchedulesLoaded extends SchedulesState {
  /// Creates the state with [view].
  const SchedulesLoaded(this.view);

  /// What they show.
  final SchedulesView view;
}

/// The regular payments could not be read.
final class SchedulesFailed extends SchedulesState {
  /// Creates the state.
  const SchedulesFailed();
}

/// Follows the regular payments, the accounts they count and the settings of
/// the money of the days, for the list of payments, the card of the overview
/// and the page of the money until the salary (ADR 0023).
class SchedulesCubit extends Cubit<SchedulesState> {
  /// Creates the cubit and starts to follow [_repository].
  SchedulesCubit(this._repository) : super(const SchedulesLoading()) {
    _follow();
  }

  final SchedulesRepository _repository;
  List<StreamSubscription<void>> _subscriptions = const [];

  CivilDate? _today;
  List<Schedule>? _schedules;
  List<AccountBalance>? _accounts;
  List<Category>? _expenses;
  List<Category>? _incomes;
  (Currency?,)? _base;
  PaydaySettings? _settings;
  List<Transaction>? _todays;
  List<LedgerImport>? _imports;
  int? _monthStart;

  /// Reads everything again after a failure.
  Future<void> retry() async {
    final cancelled = _cancel();
    emit(const SchedulesLoading());
    _follow();
    await cancelled;
  }

  /// Catches up with the calendar after a night in the background, since
  /// the money of the day, the payments that wait and the next 30 days all
  /// start today. What it shows stays until the new day comes in.
  Future<void> calendarChecked() async {
    if (_repository.today() == _today) return;
    final cancelled = _cancel();
    _follow();
    await cancelled;
  }

  /// Records the next time of [schedule], for [amount] when it differs.
  Future<void> post(Schedule schedule, {Money? amount}) =>
      _repository.post(schedule.id, amount: amount);

  /// Moves [schedule] on to its time after the next one.
  Future<void> skip(Schedule schedule) => _repository.skip(schedule.id);

  /// Counts the money of the days [until] the salary or the end of the month.
  Future<void> countUntil(SpendUntil until) =>
      _saveSettings((settings) => settings.copyWith(until: until));

  /// Counts account [id] in the money of the days, or stops counting it.
  Future<void> count(String id, {required bool counted}) {
    final view = _view();
    if (view == null) return Future.value();
    final ids = {
      for (final it in view.countable)
        if (it.counted) it.row.account.id,
    };
    counted ? ids.add(id) : ids.remove(id);
    return _saveSettings((settings) => settings.copyWith(accounts: ids));
  }

  /// Keeps [amount] aside from the money of the days.
  Future<void> keepAside(Money amount) => _saveSettings(
    (settings) => settings.copyWith(asideMinor: amount.minorUnits),
  );

  Future<void> _saveSettings(
    PaydaySettings Function(PaydaySettings settings) change,
  ) {
    final settings = _settings;
    if (settings == null) return Future.value();
    return _repository.saveSettings(change(settings));
  }

  void _follow() {
    void failed(Object _) => emit(const SchedulesFailed());
    final today = _repository.today();
    _today = today;
    _schedules = null;
    _accounts = null;
    _expenses = null;
    _incomes = null;
    _base = null;
    _settings = null;
    _todays = null;
    _imports = null;
    _monthStart = null;
    _subscriptions = [
      _repository.watchSchedules().listen((schedules) {
        _schedules = schedules;
        _show();
      }, onError: failed),
      _repository.watchAccounts().listen((accounts) {
        _accounts = accounts;
        _show();
      }, onError: failed),
      _repository.watchCategories(CategoryKind.expense).listen((categories) {
        _expenses = categories;
        _show();
      }, onError: failed),
      _repository.watchCategories(CategoryKind.income).listen((categories) {
        _incomes = categories;
        _show();
      }, onError: failed),
      _repository.watchBaseCurrency().listen((base) {
        _base = (base,);
        _show();
      }, onError: failed),
      _repository.watchSettings().listen((settings) {
        _settings = settings;
        _show();
      }, onError: failed),
      _repository.watchDay(today).listen((todays) {
        _todays = todays;
        _show();
      }, onError: failed),
      _repository.watchImports().listen((imports) {
        _imports = imports;
        _show();
      }, onError: failed),
      _repository.watchMonthStart().listen((day) {
        _monthStart = day;
        _show();
      }, onError: failed),
    ];
  }

  SchedulesView? _view() => switch (state) {
    SchedulesLoaded(:final view) => view,
    _ => null,
  };

  void _show() {
    if ((
          _today,
          _schedules,
          _accounts,
          _expenses,
          _incomes,
          _base,
          _settings,
          _todays,
          _imports,
          _monthStart,
        )
        case (
          final today?,
          final schedules?,
          final accounts?,
          final expenses?,
          final incomes?,
          (final picked,)?,
          final settings?,
          final todays?,
          final imports?,
          final monthStart?,
        )) {
      final first = accounts.where((row) => !row.account.archived).firstOrNull;
      emit(
        SchedulesLoaded(
          SchedulesView(
            today: today,
            schedules: schedules,
            accounts: accounts,
            categories: {
              for (final category in [...expenses, ...incomes])
                category.id: category,
            },
            base: picked ?? first?.account.currency,
            settings: settings,
            todays: todays,
            imports: imports,
            monthStart: monthStart,
          ),
        ),
      );
    }
  }

  Future<void> _cancel() =>
      Future.wait(_subscriptions.map((subscription) => subscription.cancel()));

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }
}
