import 'package:device_settings/device_settings.dart';
import 'package:meta/meta.dart';

/// Until when the money of the days is counted.
enum SpendUntil {
  /// Until the day before the salary.
  payday,

  /// Until the last day of the month.
  monthEnd,
}

/// How this device counts the money until the salary (ADR 0023): until when,
/// on which accounts and with how much kept aside. It belongs to the device,
/// as the other settings do (ADR 0011).
@immutable
final class PaydaySettings {
  /// Creates the settings.
  const PaydaySettings({
    this.until = SpendUntil.payday,
    this.accounts,
    this.asideMinor = 0,
  });

  /// Reads the settings from [store], with the defaults for what it lacks.
  factory PaydaySettings.read(SettingsStore store) {
    final accounts = store.read(_accountsKey);
    return PaydaySettings(
      until: store.read(_untilKey) == _monthEnd
          ? SpendUntil.monthEnd
          : SpendUntil.payday,
      accounts: accounts == null
          ? null
          : {
              for (final id in accounts.split(','))
                if (id.isNotEmpty) id,
            },
      asideMinor: int.tryParse(store.read(_asideKey) ?? '') ?? 0,
    );
  }

  static const _untilKey = 'payday-until';
  static const _accountsKey = 'payday-accounts';
  static const _asideKey = 'payday-aside';
  static const _monthEnd = 'month-end';
  static const _payday = 'payday';

  /// Until when the money is counted.
  final SpendUntil until;

  /// The ids of the accounts that are counted, or `null` for the usual ones:
  /// the debit cards and the cash in the base currency.
  final Set<String>? accounts;

  /// What stays aside until the salary, in minor units of the base currency.
  final int asideMinor;

  /// Keeps the settings in [store].
  Future<void> write(SettingsStore store) async {
    await store.write(
      _untilKey,
      until == SpendUntil.monthEnd ? _monthEnd : _payday,
    );
    final accounts = this.accounts;
    if (accounts != null) {
      await store.write(_accountsKey, (accounts.toList()..sort()).join(','));
    }
    await store.write(_asideKey, '$asideMinor');
  }

  /// The same settings with the given ones changed.
  PaydaySettings copyWith({
    SpendUntil? until,
    Set<String>? accounts,
    int? asideMinor,
  }) => PaydaySettings(
    until: until ?? this.until,
    accounts: accounts ?? this.accounts,
    asideMinor: asideMinor ?? this.asideMinor,
  );

  @override
  bool operator ==(Object other) =>
      other is PaydaySettings &&
      other.until == until &&
      other.asideMinor == asideMinor &&
      _sameAccounts(other.accounts, accounts);

  @override
  int get hashCode => Object.hash(
    until,
    asideMinor,
    accounts == null ? null : Object.hashAllUnordered(accounts!),
  );

  static bool _sameAccounts(Set<String>? a, Set<String>? b) => a == null
      ? b == null
      : b != null && a.length == b.length && a.containsAll(b);
}
