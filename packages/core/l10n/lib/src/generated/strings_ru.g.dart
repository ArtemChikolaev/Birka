///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsRu extends Translations
    with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsRu({
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
             locale: AppLocale.ru,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ),
       super(
         cardinalResolver: cardinalResolver,
         ordinalResolver: ordinalResolver,
       ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <ru>.
  final TranslationMetadata<AppLocale, Translations> _meta;
  @override
  TranslationMetadata<AppLocale, Translations> get $meta => _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key) ?? super[key];

  late final TranslationsRu _root = this; // ignore: unused_field

  @override
  TranslationsRu $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => TranslationsRu(meta: meta ?? this.$meta);

  // Translations
  @override
  late final _Translations$app$ru app = _Translations$app$ru._(_root);
}

// Path: app
class _Translations$app$ru extends Translations$app$en {
  _Translations$app$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get overview => 'Обзор';
  @override
  String get operations => 'Операции';
  @override
  String get reports => 'Отчёты';
  @override
  String get more => 'Ещё';
  @override
  String get newOperation => 'Новая операция';
  @override
  String get close => 'Закрыть';
  @override
  String get comingSoon => 'Этот экран появится скоро.';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'app.overview' => 'Обзор',
      'app.operations' => 'Операции',
      'app.reports' => 'Отчёты',
      'app.more' => 'Ещё',
      'app.newOperation' => 'Новая операция',
      'app.close' => 'Закрыть',
      'app.comingSoon' => 'Этот экран появится скоро.',
      _ => null,
    };
  }
}
