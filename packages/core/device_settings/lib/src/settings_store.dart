/// Where the settings of this device live. Each host has its own place, and
/// reading is immediate, because a page needs its language before anything
/// else opens (ADR 0011).
abstract interface class SettingsStore {
  /// The value under [key], or `null` when there is none.
  String? read(String key);

  /// Keeps [value] under [key].
  Future<void> write(String key, String value);
}
