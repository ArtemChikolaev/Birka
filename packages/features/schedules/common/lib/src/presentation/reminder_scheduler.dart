import 'dart:async';

import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/src/domain/reminders.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';
import 'package:schedules_common/src/presentation/reminder_labels.dart';

/// Keeps the reminders of the phone in step with the regular payments and
/// the settings (ADR 0025): it plans them again after every change of either,
/// after a new language, and when asked, as when the app comes back after a
/// night.
final class ReminderScheduler {
  /// Creates the scheduler of [_repository] on [_channel]. [now] tells the
  /// time in tests.
  ReminderScheduler(
    this._repository,
    this._channel, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SchedulesRepository _repository;
  final ReminderChannel _channel;
  final DateTime Function() _now;
  final _subscriptions = <StreamSubscription<void>>[];
  List<Schedule>? _schedules;
  ReminderSettings? _settings;
  List<ReminderNote>? _shown;
  Future<void> _work = Future.value();

  /// Starts to follow the payments, the settings and the language.
  void start() {
    _subscriptions.addAll([
      _repository.watchSchedules().listen((schedules) {
        _schedules = schedules;
        unawaited(refresh());
      }),
      _repository.watchReminders().listen((settings) {
        _settings = settings;
        unawaited(refresh());
      }),
      LocaleSettings.getLocaleStream().listen((_) => unawaited(refresh())),
    ]);
  }

  /// Plans the reminders again. Plans run one after another, and a plan
  /// equal to the one the phone holds leaves it alone.
  Future<void> refresh() => _work = _work.then((_) => _apply());

  Future<void> _apply() async {
    final schedules = _schedules;
    final settings = _settings;
    if (schedules == null || settings == null) return;
    final notes = settings.notify
        ? [
            for (final reminder in planReminders(
              schedules,
              now: _now(),
              minutes: settings.minutes,
            ))
              reminderNote(reminder, sums: settings.sums),
          ]
        : const <ReminderNote>[];
    if (_same(_shown, notes)) return;
    try {
      await _channel.show(notes);
      _shown = notes;
    } on Exception {
      // The phone refused; the next change or the next return tries again.
      _shown = null;
    }
  }

  static bool _same(List<ReminderNote>? a, List<ReminderNote> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Stops following.
  Future<void> stop() async {
    await Future.wait(_subscriptions.map((it) => it.cancel()));
    _subscriptions.clear();
  }
}
