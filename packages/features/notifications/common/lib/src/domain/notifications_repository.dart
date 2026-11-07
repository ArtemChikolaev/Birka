import 'package:ledger/ledger.dart';

/// What the notifications need of the ledger of this device (ADR 0026).
abstract interface class NotificationsRepository {
  /// Now on the clock of this device.
  DateTime now();

  /// The notices, the latest first, now and after every change.
  Stream<List<Notice>> watchNotices();

  /// How many notices are new, now and after every change.
  Stream<int> watchNew();

  /// Marks notices [ids] read, or every new one when [ids] is `null`.
  Future<void> read([Iterable<String>? ids]);

  /// Forgets the notices older than the 90 days that the device keeps.
  Future<void> forgetOld();
}
