import 'dart:async';

import 'package:device_settings/device_settings.dart';
import 'package:home_screen/home_screen.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/payday_settings.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';
import 'package:schedules_common/src/presentation/schedules_cubit.dart';
import 'package:schedules_common/src/presentation/today_widget.dart';

/// Keeps the widgets of the home screen in step with the money of the day
/// (ADR 0031). It follows what the plan of the day reads, the choice of the
/// amounts and the language, and hands the figures of today and tomorrow to
/// [HomeWidgets] whenever they change. The widgets never read the ledger.
final class TodayWidgetFeed {
  /// Creates the feed of [_repository] into [_widgets], which shows the
  /// amounts as [_sums] says.
  TodayWidgetFeed(this._repository, this._widgets, this._sums);

  final SchedulesRepository _repository;
  final HomeWidgets _widgets;
  final WidgetSums _sums;
  final _subscriptions = <StreamSubscription<void>>[];
  CivilDate? _today;
  List<Schedule>? _schedules;
  List<AccountBalance>? _accounts;
  (Currency?,)? _base;
  PaydaySettings? _settings;
  List<Transaction>? _todays;
  int? _monthStart;
  Future<void> _work = Future.value();

  /// Starts to follow the money of the day.
  void start() {
    if (_subscriptions.isEmpty) _follow();
  }

  /// Catches up with the calendar after a night in the background, since
  /// the money of the day starts today.
  Future<void> calendarChecked() async {
    if (_subscriptions.isEmpty || _repository.today() == _today) return;
    await _cancel();
    _follow();
  }

  /// Stops following.
  Future<void> stop() async {
    await _cancel();
    await _work;
  }

  void _follow() {
    final today = _repository.today();
    _today = today;
    _schedules = null;
    _accounts = null;
    _base = null;
    _settings = null;
    _todays = null;
    _monthStart = null;
    // A ledger that fails to read leaves the widgets as they are.
    void ignore(Object _) {}
    _subscriptions.addAll([
      _repository.watchSchedules().listen((schedules) {
        _schedules = schedules;
        _publish();
      }, onError: ignore),
      _repository.watchAccounts().listen((accounts) {
        _accounts = accounts;
        _publish();
      }, onError: ignore),
      _repository.watchBaseCurrency().listen((base) {
        _base = (base,);
        _publish();
      }, onError: ignore),
      _repository.watchSettings().listen((settings) {
        _settings = settings;
        _publish();
      }, onError: ignore),
      _repository.watchDay(today).listen((todays) {
        _todays = todays;
        _publish();
      }, onError: ignore),
      _repository.watchMonthStart().listen((day) {
        _monthStart = day;
        _publish();
      }, onError: ignore),
      _sums.watch().listen((_) => _publish()),
      LocaleSettings.getLocaleStream().listen((_) => _publish()),
    ]);
  }

  Future<void> _cancel() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    await Future.wait(subscriptions.map((it) => it.cancel()));
  }

  void _publish() {
    if ((_today, _schedules, _accounts, _base, _settings, _todays, _monthStart)
        case (
          final today?,
          final schedules?,
          final accounts?,
          final base?,
          final settings?,
          final todays?,
          final monthStart?,
        )) {
      final snapshot = todayWidgetSnapshot(
        SchedulesView(
          today: today,
          schedules: schedules,
          accounts: accounts,
          categories: const {},
          base: totalsCurrency(base.$1, accounts),
          settings: settings,
          todays: todays,
          monthStart: monthStart,
        ),
        sums: _sums.shown,
      );
      _work = _work.then((_) => _show(snapshot));
    }
  }

  Future<void> _show(WidgetSnapshot snapshot) async {
    try {
      await _widgets.show(snapshot);
    } on Exception {
      // A home screen that fails leaves the app as it is.
    }
  }
}
