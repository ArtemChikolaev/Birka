import 'dart:async';

import 'package:device_settings/device_settings.dart';

/// The pairs that the person says are no transfers (ADR 0022, point 7),
/// kept apart on this device in [_store]. Everything that counts the inbox
/// shares one of them, so that a pair kept apart leaves every count at once.
final class DismissedPairs {
  /// Reads the pairs kept apart in [_store].
  DismissedPairs(this._store)
    : _keys = {
        for (final key in (_store.read(key) ?? '').split(','))
          if (key.isNotEmpty) key,
      };

  /// Where the pairs stay in the settings, as their keys.
  static const key = 'inboxNotTransfers';

  final SettingsStore _store;
  Set<String> _keys;
  final _changes = StreamController<Set<String>>.broadcast();

  /// The keys of the pairs kept apart.
  Set<String> get keys => _keys;

  /// The keys after each pair kept apart.
  Stream<Set<String>> get changes => _changes.stream;

  /// Keeps the pair of [pairKey] apart. When the settings cannot keep it,
  /// the error comes through and nothing changes.
  Future<void> add(String pairKey) async {
    final next = {..._keys, pairKey};
    await _store.write(key, next.join(','));
    _keys = next;
    _changes.add(next);
  }
}
