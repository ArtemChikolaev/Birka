import 'package:birka_web/app/browser.dart';
import 'package:settings_common/settings_common.dart';

/// The settings of this browser, in its local storage, which a page can read
/// before anything else opens (ADR 0011).
final class BrowserSettingsStore implements SettingsStore {
  /// Creates the store.
  const BrowserSettingsStore();

  static String _inBrowser(String key) => 'birka-$key';

  @override
  String? read(String key) => keptValue(_inBrowser(key));

  @override
  Future<void> write(String key, String value) async =>
      keepValue(_inBrowser(key), value);
}
