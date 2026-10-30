///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element

class Translations with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       _meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.en,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  Translations $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => Translations(meta: meta ?? this.$meta);

  // Translations
  late final Translations$app$en app = Translations$app$en.internal(_root);
}

// Path: app
class Translations$app$en {
  Translations$app$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Overview'
  String get overview => 'Overview';

  /// en: 'Operations'
  String get operations => 'Operations';

  /// en: 'Reports'
  String get reports => 'Reports';

  /// en: 'More'
  String get more => 'More';

  /// en: 'New operation'
  String get newOperation => 'New operation';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'This screen is coming soon.'
  String get comingSoon => 'This screen is coming soon.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'app.overview' => 'Overview',
      'app.operations' => 'Operations',
      'app.reports' => 'Reports',
      'app.more' => 'More',
      'app.newOperation' => 'New operation',
      'app.close' => 'Close',
      'app.comingSoon' => 'This screen is coming soon.',
      _ => null,
    };
  }
}
