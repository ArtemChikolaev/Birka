import 'package:meta/meta.dart';

/// What a letter to the developer says about the app and the device, and no
/// more: the version of the app, the system and the language (ADR 0018).
@immutable
final class AppAbout {
  /// Creates the description.
  const AppAbout({
    required this.version,
    required this.build,
    required this.system,
    required this.locale,
  });

  /// The version of the app, such as `0.1.0`.
  final String version;

  /// The number of the build, such as `42`.
  final String build;

  /// The system with its version, such as `Android 14`.
  final String system;

  /// The language and the region of the device, such as `ru-RU`.
  final String locale;

  /// The last lines of a letter: `—` and `Birka 0.1.0 (42) · Android 14 ·
  /// ru-RU`.
  String get signature => '—\nBirka $version ($build) · $system · $locale';

  @override
  bool operator ==(Object other) =>
      other is AppAbout &&
      other.version == version &&
      other.build == build &&
      other.system == system &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(version, build, system, locale);
}
