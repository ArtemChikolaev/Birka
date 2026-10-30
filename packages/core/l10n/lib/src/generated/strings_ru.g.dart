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
  late final _Translations$accounts$ru accounts = _Translations$accounts$ru._(
    _root,
  );
  @override
  late final _Translations$app$ru app = _Translations$app$ru._(_root);
}

// Path: accounts
class _Translations$accounts$ru extends Translations$accounts$en {
  _Translations$accounts$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Счета';
  @override
  String get back => 'Назад';
  @override
  String get add => 'Добавить счёт';
  @override
  String get capital => 'Капитал';
  @override
  String get and => 'и';
  @override
  String inAccounts({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'в ${n} счёте',
        few: 'в ${n} счетах',
        many: 'в ${n} счетах',
        other: 'в ${n} счетах',
      );
  @override
  String get main => 'основной';
  @override
  String get emptyTitle => 'Пока нет счетов';
  @override
  String get emptyHint => 'Добавьте первый, чтобы видеть, где лежат деньги.';
  @override
  String get archive => 'Архив';
  @override
  String get failed => 'Не удалось прочитать счета.';
  @override
  String get retry => 'Повторить';
  @override
  Map<String, String> get types => {
    'cash': 'Наличные',
    'debit': 'Дебетовая карта',
    'credit': 'Кредитная карта',
    'savings': 'Накопительный',
    'deposit': 'Вклад',
    'loan': 'Кредит',
    'debt': 'Долг',
    'investment': 'Инвестиции',
    'crypto': 'Криптокошелёк',
  };
  @override
  late final _Translations$accounts$form$ru form =
      _Translations$accounts$form$ru._(_root);
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
  @override
  String get soon => 'скоро';
  @override
  Map<String, String> get currencies => {
    'RUB': 'Рубли',
    'USD': 'Доллары',
    'EUR': 'Евро',
    'USDT': 'USDT',
    'GEL': 'Лари',
    'TRY': 'Лиры',
    'KZT': 'Тенге',
    'AED': 'Дирхамы',
    'THB': 'Баты',
  };
  @override
  String get categories => 'Категории';
  @override
  String get import => 'Импорт';
  @override
  String get backup => 'Бэкап';
}

// Path: accounts.form
class _Translations$accounts$form$ru extends Translations$accounts$form$en {
  _Translations$accounts$form$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get newTitle => 'Новый счёт';
  @override
  String get editTitle => 'Счёт';
  @override
  String get name => 'Название';
  @override
  String get namePlaceholder => 'Зарплатная';
  @override
  String get type => 'Тип';
  @override
  String get currency => 'Валюта';
  @override
  String get openingBalance => 'Остаток сейчас';
  @override
  String get debt => 'Долг по карте';
  @override
  String get lastDigits => 'Последние 4 цифры карты';
  @override
  String get art => 'Оформление';
  @override
  String get includeInTotals => 'Учитывать в капитале';
  @override
  String get save => 'Сохранить';
  @override
  String get archive => 'Убрать в архив';
  @override
  String get restore => 'Вернуть из архива';
  @override
  String get nameMissing => 'Дайте счёту название.';
  @override
  String get amountInvalid => 'Введите сумму, например 1250,50.';
  @override
  String get lastDigitsInvalid => 'Введите четыре цифры.';
  @override
  String get failed => 'Не удалось сохранить. Попробуйте ещё раз.';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'accounts.title' => 'Счета',
      'accounts.back' => 'Назад',
      'accounts.add' => 'Добавить счёт',
      'accounts.capital' => 'Капитал',
      'accounts.and' => 'и',
      'accounts.inAccounts' =>
        ({required num n}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one: 'в ${n} счёте',
              few: 'в ${n} счетах',
              many: 'в ${n} счетах',
              other: 'в ${n} счетах',
            ),
      'accounts.main' => 'основной',
      'accounts.emptyTitle' => 'Пока нет счетов',
      'accounts.emptyHint' =>
        'Добавьте первый, чтобы видеть, где лежат деньги.',
      'accounts.archive' => 'Архив',
      'accounts.failed' => 'Не удалось прочитать счета.',
      'accounts.retry' => 'Повторить',
      'accounts.types.cash' => 'Наличные',
      'accounts.types.debit' => 'Дебетовая карта',
      'accounts.types.credit' => 'Кредитная карта',
      'accounts.types.savings' => 'Накопительный',
      'accounts.types.deposit' => 'Вклад',
      'accounts.types.loan' => 'Кредит',
      'accounts.types.debt' => 'Долг',
      'accounts.types.investment' => 'Инвестиции',
      'accounts.types.crypto' => 'Криптокошелёк',
      'accounts.form.newTitle' => 'Новый счёт',
      'accounts.form.editTitle' => 'Счёт',
      'accounts.form.name' => 'Название',
      'accounts.form.namePlaceholder' => 'Зарплатная',
      'accounts.form.type' => 'Тип',
      'accounts.form.currency' => 'Валюта',
      'accounts.form.openingBalance' => 'Остаток сейчас',
      'accounts.form.debt' => 'Долг по карте',
      'accounts.form.lastDigits' => 'Последние 4 цифры карты',
      'accounts.form.art' => 'Оформление',
      'accounts.form.includeInTotals' => 'Учитывать в капитале',
      'accounts.form.save' => 'Сохранить',
      'accounts.form.archive' => 'Убрать в архив',
      'accounts.form.restore' => 'Вернуть из архива',
      'accounts.form.nameMissing' => 'Дайте счёту название.',
      'accounts.form.amountInvalid' => 'Введите сумму, например 1250,50.',
      'accounts.form.lastDigitsInvalid' => 'Введите четыре цифры.',
      'accounts.form.failed' => 'Не удалось сохранить. Попробуйте ещё раз.',
      'app.overview' => 'Обзор',
      'app.operations' => 'Операции',
      'app.reports' => 'Отчёты',
      'app.more' => 'Ещё',
      'app.newOperation' => 'Новая операция',
      'app.close' => 'Закрыть',
      'app.comingSoon' => 'Этот экран появится скоро.',
      'app.soon' => 'скоро',
      'app.currencies.RUB' => 'Рубли',
      'app.currencies.USD' => 'Доллары',
      'app.currencies.EUR' => 'Евро',
      'app.currencies.USDT' => 'USDT',
      'app.currencies.GEL' => 'Лари',
      'app.currencies.TRY' => 'Лиры',
      'app.currencies.KZT' => 'Тенге',
      'app.currencies.AED' => 'Дирхамы',
      'app.currencies.THB' => 'Баты',
      'app.categories' => 'Категории',
      'app.import' => 'Импорт',
      'app.backup' => 'Бэкап',
      _ => null,
    };
  }
}
