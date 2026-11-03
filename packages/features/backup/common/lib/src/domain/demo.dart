import 'package:backup_common/src/domain/demo_ledger.dart';
import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';

/// Where the demo of a device stands. It lives in a database of its own, so
/// that the ledger of the device stays as it was (ADR 0019).
enum DemoState {
  /// The ledger of the device is open.
  off,

  /// The demo is on and waits to be filled, once its database opens.
  fresh,

  /// The demo is on and filled.
  on
  ;

  /// Whether the app shows the demo.
  bool get isOn => this != DemoState.off;
}

/// Where the store of the settings keeps the state of the demo.
const demoKey = 'demo';

/// The name of the database of the ledger of the device.
const ledgerDatabase = 'birka';

/// The name of the database of the demo.
const demoDatabase = 'birka-demo';

/// Where the demo of the device stands, as [store] keeps it.
DemoState demoStateIn(SettingsStore store) =>
    DemoState.values.asNameMap()[store.read(demoKey)] ?? DemoState.off;

/// The database that the app opens while the demo stands as [store] keeps it.
String databaseNameIn(SettingsStore store) =>
    demoStateIn(store).isOn ? demoDatabase : ledgerDatabase;

/// Turns the demo on or off in [store]. The host then opens the other
/// database; a demo that comes on starts afresh.
Future<void> turnDemo(SettingsStore store, {required bool on}) =>
    store.write(demoKey, (on ? DemoState.fresh : DemoState.off).name);

/// Fills [ledger], the demo just opened, when the demo has just come on.
/// Anything else stays as it is.
Future<void> settleDemo(
  SettingsStore store,
  LedgerRepository ledger, {
  required DateTime now,
}) async {
  if (demoStateIn(store) != DemoState.fresh) return;
  await fillDemo(ledger, now: now);
  await store.write(demoKey, DemoState.on.name);
}
