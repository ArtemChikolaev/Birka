/// The browser and the system that [userAgent] names, for a letter from the
/// site: `Chrome 141 · macOS`, `Safari 26 · iOS 18` or `Firefox 144 ·
/// Windows`. What it does not know stays out, and `web` stands for nothing
/// known.
///
/// Browsers no longer tell every version: macOS stays at 10.15, and Safari on
/// iPhone has said iOS 18 since iOS 26.
String browserSystem(String userAgent) {
  String? named(List<(String, String)> patterns) {
    for (final (name, pattern) in patterns) {
      final match = RegExp(pattern).firstMatch(userAgent);
      if (match == null) continue;
      final version = match.groupCount > 0 ? match.group(1) : null;
      return version == null ? name : '$name $version';
    }
    return null;
  }

  final browser = named(const [
    ('Edge', r'Edg(?:A|iOS)?/(\d+)'),
    ('Firefox', r'(?:Firefox|FxiOS)/(\d+)'),
    ('Chrome', r'(?:Chrome|CriOS)/(\d+)'),
    ('Safari', r'Version/(\d+)[\d.]* (?:Mobile/\S+ )?Safari/'),
  ]);
  final system = named(const [
    ('Android', r'Android (\d+(?:\.\d+)?)'),
    ('iOS', r'(?:iPhone|iPad|iPod).*? OS (\d+)'),
    ('ChromeOS', 'CrOS'),
    ('macOS', 'Macintosh'),
    ('Windows', 'Windows'),
    ('Linux', 'Linux'),
  ]);
  final known = [?browser, ?system];
  return known.isEmpty ? 'web' : known.join(' · ');
}
