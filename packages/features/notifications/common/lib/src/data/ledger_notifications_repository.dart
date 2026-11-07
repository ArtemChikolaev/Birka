import 'package:ledger/ledger.dart';
import 'package:notifications_common/src/domain/notifications_repository.dart';

/// Keeps the notices in the ledger of this device, which writes them in the
/// same writes as what they tell of (ADR 0026).
final class LedgerNotificationsRepository implements NotificationsRepository {
  /// Creates the repository on [_ledger]. [now] tells the time in tests.
  LedgerNotificationsRepository(this._ledger, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// How long the device keeps a notice.
  static const keep = Duration(days: 90);

  final LedgerRepository _ledger;
  final DateTime Function() _now;

  @override
  DateTime now() => _now();

  @override
  Stream<List<Notice>> watchNotices() => _ledger.watchNotices();

  @override
  Stream<int> watchNew() => _ledger.watchNewNotices();

  @override
  Future<void> read([Iterable<String>? ids]) => _ledger.readNotices(ids);

  @override
  Future<void> forgetOld() async {
    await _ledger.forgetNotices(before: _now().subtract(keep));
  }
}
