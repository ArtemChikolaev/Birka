import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:device_settings/device_settings.dart';
import 'package:home_screen/home_screen.dart';
import 'package:meta/meta.dart';

/// What the page of the widgets shows (ADR 0031).
@immutable
final class WidgetsState {
  /// Creates the state.
  const WidgetsState({
    required this.sums,
    this.canPin = false,
    this.snapshot,
    this.pinned = 0,
  });

  /// Whether the widgets show amounts.
  final bool sums;

  /// Whether the launcher adds a widget when the app asks.
  final bool canPin;

  /// The figures that the widgets show now, the amounts as they are, or
  /// `null` before the first.
  final WidgetSnapshot? snapshot;

  /// How many widgets the launcher added while the page was open.
  final int pinned;

  /// The figures of the first day, or `null` while there are none.
  WidgetDay? get today => snapshot?.days.firstOrNull;

  /// A copy with the given fields changed.
  WidgetsState copyWith({
    bool? sums,
    bool? canPin,
    WidgetSnapshot? snapshot,
    int? pinned,
  }) => WidgetsState(
    sums: sums ?? this.sums,
    canPin: canPin ?? this.canPin,
    snapshot: snapshot ?? this.snapshot,
    pinned: pinned ?? this.pinned,
  );
}

/// The page of the widgets: what «Сегодня» shows now, the switch of the
/// amounts, kept with the settings of the device, and the adding of a widget
/// from the app where the launcher allows it (ADR 0031).
class WidgetsCubit extends Cubit<WidgetsState> {
  /// Creates the page on [_store], [_sums], [_widgets] and [_screen].
  WidgetsCubit(this._store, this._sums, this._widgets, this._screen)
    : super(WidgetsState(sums: _sums.shown, snapshot: _widgets.last)) {
    _subscriptions = [
      _widgets.watch().listen((snapshot) {
        if (snapshot != state.snapshot) {
          emit(state.copyWith(snapshot: snapshot));
        }
      }),
      _sums.watch().listen((shown) {
        if (shown != state.sums) emit(state.copyWith(sums: shown));
      }),
      _screen.pinned.listen(
        (_) => emit(state.copyWith(pinned: state.pinned + 1)),
      ),
    ];
    unawaited(_askPin());
  }

  final SettingsStore _store;
  final WidgetSums _sums;
  final HomeWidgets _widgets;
  final HomeScreen _screen;
  late final List<StreamSubscription<Object?>> _subscriptions;

  Future<void> _askPin() async {
    final can = await _screen.canPin();
    if (!isClosed && can != state.canPin) emit(state.copyWith(canPin: can));
  }

  /// Shows the amounts in the widgets, or hides them behind dots. The
  /// widgets follow at once, and the device keeps the choice.
  Future<void> sumsChanged({required bool shown}) async {
    if (shown == state.sums) return;
    emit(state.copyWith(sums: shown));
    _sums.show(shown: shown);
    await Settings.readFrom(_store).copyWith(widgetSums: shown).writeTo(_store);
  }

  /// Asks the launcher to add «Сегодня».
  Future<void> pin() => _screen.pin();

  @override
  Future<void> close() async {
    await Future.wait(_subscriptions.map((it) => it.cancel()));
    return super.close();
  }
}
