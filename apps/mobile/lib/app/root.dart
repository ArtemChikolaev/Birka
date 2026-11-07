import 'dart:async';

import 'package:backup_common/backup_common.dart' show demoStateIn, turnDemo;
import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/dependencies.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:rates/rates.dart';
import 'package:schedules_common/schedules_common.dart'
    show ReminderNotices, ReminderScheduler;
import 'package:settings_common/settings_common.dart';

/// The app on the ledger of the device or on its demo. A turn of the demo
/// opens the other ledger and the app anew on it, on the overview
/// (ADR 0019).
class BirkaRoot extends StatefulWidget {
  /// Creates the root on the ledger that [getIt] holds already. With
  /// [onboarding] the app starts with the steps of a new device.
  const BirkaRoot({
    required this.getIt,
    required this.settings,
    this.onboarding = false,
    super.key,
  });

  /// Knows every implementation (ADR 0006).
  final GetIt getIt;

  /// The settings of the device, which say where the demo stands.
  final SettingsStore settings;

  /// Whether the app starts with the onboarding.
  final bool onboarding;

  @override
  State<BirkaRoot> createState() => _BirkaRootState();
}

class _BirkaRootState extends State<BirkaRoot> {
  late bool _onboarding = widget.onboarding;

  /// Which opening of a ledger the app stands on, which gives each its own
  /// app.
  var _opening = 0;

  /// Whether the other ledger is on its way.
  var _turning = false;

  StreamSubscription<Currency?>? _baseCurrencies;

  @override
  void initState() {
    super.initState();
    _followRates();
    _followReminders();
  }

  @override
  void dispose() {
    unawaited(_baseCurrencies?.cancel());
    super.dispose();
  }

  /// Keeps the rates of the open ledger fresh. The first frame waits for no
  /// network (ADR 0012).
  void _followRates() {
    final rates = widget.getIt<RatesUpdater>();
    unawaited(rates.refresh());
    // Another base currency needs the rates of other days.
    _baseCurrencies = widget
        .getIt<BaseCurrency>()
        .watch()
        .skip(1)
        .listen((_) => unawaited(rates.refresh()));
  }

  /// Keeps the reminders of the phone in step with the payments of the
  /// device (ADR 0025). The demo leaves them as they stand: its payments are
  /// not the person's.
  void _followReminders() {
    // The bell is the app's own: its notices come in the demo too.
    widget.getIt<ReminderNotices>().start();
    if (demoStateIn(widget.settings).isOn) return;
    widget.getIt<ReminderScheduler>().start();
  }

  Future<void> _turnDemo({required bool on}) async {
    // The app of the old ledger goes before the ledger does.
    setState(() => _turning = true);
    await WidgetsBinding.instance.endOfFrame;
    await _baseCurrencies?.cancel();
    await turnDemo(widget.settings, on: on);
    final onboarding = await openLedger(widget.getIt, widget.settings);
    if (!mounted) return;
    _followRates();
    _followReminders();
    setState(() {
      _onboarding = onboarding;
      _opening++;
      _turning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_turning) {
      return const ColoredBox(color: Color(BirkaTokens.colorBackground));
    }
    return BirkaApp(
      key: ValueKey(_opening),
      getIt: widget.getIt,
      onboarding: _onboarding,
      onDemoChanged: (on) => unawaited(_turnDemo(on: on)),
    );
  }
}
