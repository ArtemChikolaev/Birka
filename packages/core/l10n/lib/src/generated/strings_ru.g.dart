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
  @override
  late final _Translations$categories$ru categories =
      _Translations$categories$ru._(_root);
  @override
  late final _Translations$overview$ru overview = _Translations$overview$ru._(
    _root,
  );
  @override
  late final _Translations$reports$ru reports = _Translations$reports$ru._(
    _root,
  );
  @override
  late final _Translations$transactions$ru transactions =
      _Translations$transactions$ru._(_root);
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
  String get retry => 'Повторить';
  @override
  String get storedHere => 'Данные хранятся только в этом браузере.';
  @override
  String get notStored =>
      'Этот браузер не хранит данные, поэтому они исчезнут, когда вы закроете вкладку.';
  @override
  String get openElsewhere =>
      'Birka открыта в другой вкладке. Закройте её и попробуйте снова.';
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
  String get import => 'Импорт';
  @override
  String get backup => 'Бэкап';
}

// Path: categories
class _Translations$categories$ru extends Translations$categories$en {
  _Translations$categories$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Категории';
  @override
  String get back => 'Назад';
  @override
  String get add => 'Добавить категорию';
  @override
  String get expense => 'Расходы';
  @override
  String get income => 'Доходы';
  @override
  String get emptyTitle => 'Пока нет категорий';
  @override
  String get emptyHint => 'Возьмите готовый набор или создайте свои.';
  @override
  String get addPresets => 'Добавить готовый набор';
  @override
  String get addOwn => 'Создать свою';
  @override
  String get archive => 'Архив';
  @override
  String get failed => 'Не удалось прочитать категории.';
  @override
  String subcategories({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${n} подкатегория',
        few: '${n} подкатегории',
        many: '${n} подкатегорий',
        other: '${n} подкатегории',
      );
  @override
  Map<String, String> get presets => {
    'groceries': 'Продукты',
    'cafe': 'Кафе',
    'transport': 'Транспорт',
    'home': 'Дом',
    'health': 'Здоровье',
    'leisure': 'Досуг',
    'subscriptions': 'Подписки',
    'clothes': 'Одежда',
    'travel': 'Поездки',
    'education': 'Обучение',
    'gifts': 'Подарки',
    'salary': 'Зарплата',
    'freelance': 'Подработка',
    'interest': 'Проценты',
    'giftsReceived': 'Подарки',
  };
  @override
  late final _Translations$categories$form$ru form =
      _Translations$categories$form$ru._(_root);
}

// Path: overview
class _Translations$overview$ru extends Translations$overview$en {
  _Translations$overview$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get capital => 'Капитал';
  @override
  String currencies({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${n} валюта',
        few: '${n} валюты',
        many: '${n} валют',
        other: '${n} валюты',
      );
  @override
  String get week => 'Неделя';
  @override
  String get month => 'Месяц';
  @override
  String get year => 'Год';
  @override
  String get inWeek => 'за неделю';
  @override
  String get inYear => 'за год';
  @override
  String get chart => 'Капитал за период';
  @override
  String get accounts => 'Счета';
  @override
  String allAccounts({required Object n}) => 'Все ${n}';
  @override
  String spendingIn({required Object month}) => 'Траты ${month}';
  @override
  List<String> get monthsIn => [
    'в январе',
    'в феврале',
    'в марте',
    'в апреле',
    'в мае',
    'в июне',
    'в июле',
    'в августе',
    'в сентябре',
    'в октябре',
    'в ноябре',
    'в декабре',
  ];
  @override
  String get noSpending => 'В этом месяце трат пока нет.';
  @override
  String get ring => 'Траты по категориям';
  @override
  String get failed => 'Не удалось прочитать обзор.';
  @override
  String get hideAmounts => 'Скрыть суммы';
  @override
  String get showAmounts => 'Показать суммы';
  @override
  List<String> get changeIn => [
    'за январь',
    'за февраль',
    'за март',
    'за апрель',
    'за май',
    'за июнь',
    'за июль',
    'за август',
    'за сентябрь',
    'за октябрь',
    'за ноябрь',
    'за декабрь',
  ];
}

// Path: reports
class _Translations$reports$ru extends Translations$reports$en {
  _Translations$reports$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get expenses => 'Расходы';
  @override
  String get income => 'Доходы';
  @override
  String get byMonth => 'По месяцам';
  @override
  String average({required Object amount}) => 'в среднем ${amount}';
  @override
  String get noExpenses => 'В этом месяце расходов нет.';
  @override
  String get noIncome => 'В этом месяце доходов нет.';
  @override
  String get ring => 'Доли категорий';
  @override
  String get failed => 'Не удалось прочитать отчёт.';
  @override
  List<String> get against => [
    'к январю',
    'к февралю',
    'к марту',
    'к апрелю',
    'к маю',
    'к июню',
    'к июлю',
    'к августу',
    'к сентябрю',
    'к октябрю',
    'к ноябрю',
    'к декабрю',
  ];
  @override
  List<String> get monthsShort => [
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек',
  ];
}

// Path: transactions
class _Translations$transactions$ru extends Translations$transactions$en {
  _Translations$transactions$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get expense => 'Расход';
  @override
  String get income => 'Доход';
  @override
  String get transfer => 'Перевод';
  @override
  String get adjustment => 'Корректировка';
  @override
  String get today => 'Сегодня';
  @override
  String get yesterday => 'Вчера';
  @override
  String get pickDay => 'Выбрать день';
  @override
  String get note => 'Заметка';
  @override
  String get addNote => 'Заметка';
  @override
  String get done => 'Готово';
  @override
  String get account => 'Счёт';
  @override
  String get to => 'Куда';
  @override
  String get sent => 'Списать';
  @override
  String get received => 'Зачислить';
  @override
  String get save => 'Сохранить';
  @override
  String get more => 'Ещё';
  @override
  String get allCategories => 'Все категории';
  @override
  String get failed => 'Не удалось сохранить. Попробуйте ещё раз.';
  @override
  String get failedToRead => 'Не удалось прочитать счета и категории.';
  @override
  String get noAccountsTitle => 'Пока нет счетов';
  @override
  String get noAccountsHint =>
      'Добавьте счёт, чтобы записывать, куда уходят деньги.';
  @override
  String get addAccount => 'Добавить счёт';
  @override
  String get oneAccountHint => 'Для перевода нужен второй счёт.';
  @override
  String get noCategoriesHint => 'Добавьте категории, чтобы разбирать траты.';
  @override
  String get addCategories => 'Добавить категории';
  @override
  String get search => 'Поиск';
  @override
  String get searchHint => 'Кафе, 250 или заметка';
  @override
  String get clearSearch => 'Очистить поиск';
  @override
  String get filterAll => 'Все';
  @override
  String get filterExpenses => 'Расходы';
  @override
  String get filterIncome => 'Доходы';
  @override
  String get filterTransfers => 'Переводы';
  @override
  String get pickMonth => 'Выбрать месяц';
  @override
  String get noOperationsTitle => 'Пока нет операций';
  @override
  String get noOperationsHint => 'Нажмите плюс внизу, чтобы записать первую.';
  @override
  String get nothingFound => 'Ничего не нашлось';
  @override
  String get failedToReadOperations => 'Не удалось прочитать операции.';
  @override
  String get failedToDelete => 'Не удалось удалить. Попробуйте ещё раз.';
  @override
  String get operation => 'Операция';
  @override
  String get edit => 'Изменить';
  @override
  String get editOperation => 'Изменить операцию';
  @override
  String get repeat => 'Повторить';
  @override
  String get delete => 'Удалить';
  @override
  String get deleteTitle => 'Удалить операцию?';
  @override
  String get cancel => 'Отмена';
  @override
  String get back => 'Назад';
  @override
  String get category => 'Категория';
  @override
  String get from => 'Откуда';
  @override
  String get date => 'Дата';
  @override
  late final _Translations$transactions$sources$ru sources =
      _Translations$transactions$sources$ru._(_root);
  @override
  late final _Translations$transactions$keys$ru keys =
      _Translations$transactions$keys$ru._(_root);
  @override
  String dayOfMonth({required Object day, required Object month}) =>
      '${day} ${month}';
  @override
  List<String> get months => [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  @override
  List<String> get monthNames => [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];
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
  String get balance => 'Остаток сейчас';
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

// Path: categories.form
class _Translations$categories$form$ru extends Translations$categories$form$en {
  _Translations$categories$form$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get newTitle => 'Новая категория';
  @override
  String get editTitle => 'Категория';
  @override
  String get name => 'Название';
  @override
  String get namePlaceholder => 'Продукты';
  @override
  String get kind => 'Тип';
  @override
  String get parent => 'Внутри';
  @override
  String get noParent => 'Отдельно';
  @override
  String get color => 'Цвет';
  @override
  String get icon => 'Значок';
  @override
  String get save => 'Сохранить';
  @override
  String get archive => 'Убрать в архив';
  @override
  String get restore => 'Вернуть из архива';
  @override
  String get nameMissing => 'Дайте категории название.';
  @override
  String get failed => 'Не удалось сохранить. Попробуйте ещё раз.';
}

// Path: transactions.sources
class _Translations$transactions$sources$ru
    extends Translations$transactions$sources$en {
  _Translations$transactions$sources$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get manual => 'Вручную';
  @override
  String get import => 'Из выписки';
  @override
  String get notification => 'Из уведомления';
  @override
  String get recurring => 'Регулярная';
  @override
  String get bank => 'Из банка';
}

// Path: transactions.keys
class _Translations$transactions$keys$ru
    extends Translations$transactions$keys$en {
  _Translations$transactions$keys$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get point => 'Запятая';
  @override
  String get add => 'Плюс';
  @override
  String get subtract => 'Минус';
  @override
  String get multiply => 'Умножить';
  @override
  String get divide => 'Разделить';
  @override
  String get backspace => 'Стереть';
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
      'accounts.form.balance' => 'Остаток сейчас',
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
      'app.retry' => 'Повторить',
      'app.storedHere' => 'Данные хранятся только в этом браузере.',
      'app.notStored' =>
        'Этот браузер не хранит данные, поэтому они исчезнут, когда вы закроете вкладку.',
      'app.openElsewhere' =>
        'Birka открыта в другой вкладке. Закройте её и попробуйте снова.',
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
      'app.import' => 'Импорт',
      'app.backup' => 'Бэкап',
      'categories.title' => 'Категории',
      'categories.back' => 'Назад',
      'categories.add' => 'Добавить категорию',
      'categories.expense' => 'Расходы',
      'categories.income' => 'Доходы',
      'categories.emptyTitle' => 'Пока нет категорий',
      'categories.emptyHint' => 'Возьмите готовый набор или создайте свои.',
      'categories.addPresets' => 'Добавить готовый набор',
      'categories.addOwn' => 'Создать свою',
      'categories.archive' => 'Архив',
      'categories.failed' => 'Не удалось прочитать категории.',
      'categories.subcategories' =>
        ({required num n}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one: '${n} подкатегория',
              few: '${n} подкатегории',
              many: '${n} подкатегорий',
              other: '${n} подкатегории',
            ),
      'categories.presets.groceries' => 'Продукты',
      'categories.presets.cafe' => 'Кафе',
      'categories.presets.transport' => 'Транспорт',
      'categories.presets.home' => 'Дом',
      'categories.presets.health' => 'Здоровье',
      'categories.presets.leisure' => 'Досуг',
      'categories.presets.subscriptions' => 'Подписки',
      'categories.presets.clothes' => 'Одежда',
      'categories.presets.travel' => 'Поездки',
      'categories.presets.education' => 'Обучение',
      'categories.presets.gifts' => 'Подарки',
      'categories.presets.salary' => 'Зарплата',
      'categories.presets.freelance' => 'Подработка',
      'categories.presets.interest' => 'Проценты',
      'categories.presets.giftsReceived' => 'Подарки',
      'categories.form.newTitle' => 'Новая категория',
      'categories.form.editTitle' => 'Категория',
      'categories.form.name' => 'Название',
      'categories.form.namePlaceholder' => 'Продукты',
      'categories.form.kind' => 'Тип',
      'categories.form.parent' => 'Внутри',
      'categories.form.noParent' => 'Отдельно',
      'categories.form.color' => 'Цвет',
      'categories.form.icon' => 'Значок',
      'categories.form.save' => 'Сохранить',
      'categories.form.archive' => 'Убрать в архив',
      'categories.form.restore' => 'Вернуть из архива',
      'categories.form.nameMissing' => 'Дайте категории название.',
      'categories.form.failed' => 'Не удалось сохранить. Попробуйте ещё раз.',
      'overview.capital' => 'Капитал',
      'overview.currencies' =>
        ({required num n}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one: '${n} валюта',
              few: '${n} валюты',
              many: '${n} валют',
              other: '${n} валюты',
            ),
      'overview.week' => 'Неделя',
      'overview.month' => 'Месяц',
      'overview.year' => 'Год',
      'overview.inWeek' => 'за неделю',
      'overview.inYear' => 'за год',
      'overview.chart' => 'Капитал за период',
      'overview.accounts' => 'Счета',
      'overview.allAccounts' => ({required Object n}) => 'Все ${n}',
      'overview.spendingIn' => ({required Object month}) => 'Траты ${month}',
      'overview.monthsIn.0' => 'в январе',
      'overview.monthsIn.1' => 'в феврале',
      'overview.monthsIn.2' => 'в марте',
      'overview.monthsIn.3' => 'в апреле',
      'overview.monthsIn.4' => 'в мае',
      'overview.monthsIn.5' => 'в июне',
      'overview.monthsIn.6' => 'в июле',
      'overview.monthsIn.7' => 'в августе',
      'overview.monthsIn.8' => 'в сентябре',
      'overview.monthsIn.9' => 'в октябре',
      'overview.monthsIn.10' => 'в ноябре',
      'overview.monthsIn.11' => 'в декабре',
      'overview.noSpending' => 'В этом месяце трат пока нет.',
      'overview.ring' => 'Траты по категориям',
      'overview.failed' => 'Не удалось прочитать обзор.',
      'overview.hideAmounts' => 'Скрыть суммы',
      'overview.showAmounts' => 'Показать суммы',
      'overview.changeIn.0' => 'за январь',
      'overview.changeIn.1' => 'за февраль',
      'overview.changeIn.2' => 'за март',
      'overview.changeIn.3' => 'за апрель',
      'overview.changeIn.4' => 'за май',
      'overview.changeIn.5' => 'за июнь',
      'overview.changeIn.6' => 'за июль',
      'overview.changeIn.7' => 'за август',
      'overview.changeIn.8' => 'за сентябрь',
      'overview.changeIn.9' => 'за октябрь',
      'overview.changeIn.10' => 'за ноябрь',
      'overview.changeIn.11' => 'за декабрь',
      'reports.expenses' => 'Расходы',
      'reports.income' => 'Доходы',
      'reports.byMonth' => 'По месяцам',
      'reports.average' => ({required Object amount}) => 'в среднем ${amount}',
      'reports.noExpenses' => 'В этом месяце расходов нет.',
      'reports.noIncome' => 'В этом месяце доходов нет.',
      'reports.ring' => 'Доли категорий',
      'reports.failed' => 'Не удалось прочитать отчёт.',
      'reports.against.0' => 'к январю',
      'reports.against.1' => 'к февралю',
      'reports.against.2' => 'к марту',
      'reports.against.3' => 'к апрелю',
      'reports.against.4' => 'к маю',
      'reports.against.5' => 'к июню',
      'reports.against.6' => 'к июлю',
      'reports.against.7' => 'к августу',
      'reports.against.8' => 'к сентябрю',
      'reports.against.9' => 'к октябрю',
      'reports.against.10' => 'к ноябрю',
      'reports.against.11' => 'к декабрю',
      'reports.monthsShort.0' => 'Янв',
      'reports.monthsShort.1' => 'Фев',
      'reports.monthsShort.2' => 'Мар',
      'reports.monthsShort.3' => 'Апр',
      'reports.monthsShort.4' => 'Май',
      'reports.monthsShort.5' => 'Июн',
      'reports.monthsShort.6' => 'Июл',
      'reports.monthsShort.7' => 'Авг',
      'reports.monthsShort.8' => 'Сен',
      'reports.monthsShort.9' => 'Окт',
      'reports.monthsShort.10' => 'Ноя',
      'reports.monthsShort.11' => 'Дек',
      'transactions.expense' => 'Расход',
      'transactions.income' => 'Доход',
      'transactions.transfer' => 'Перевод',
      'transactions.adjustment' => 'Корректировка',
      'transactions.today' => 'Сегодня',
      'transactions.yesterday' => 'Вчера',
      'transactions.pickDay' => 'Выбрать день',
      'transactions.note' => 'Заметка',
      'transactions.addNote' => 'Заметка',
      'transactions.done' => 'Готово',
      'transactions.account' => 'Счёт',
      'transactions.to' => 'Куда',
      'transactions.sent' => 'Списать',
      'transactions.received' => 'Зачислить',
      'transactions.save' => 'Сохранить',
      'transactions.more' => 'Ещё',
      'transactions.allCategories' => 'Все категории',
      'transactions.failed' => 'Не удалось сохранить. Попробуйте ещё раз.',
      'transactions.failedToRead' => 'Не удалось прочитать счета и категории.',
      'transactions.noAccountsTitle' => 'Пока нет счетов',
      'transactions.noAccountsHint' =>
        'Добавьте счёт, чтобы записывать, куда уходят деньги.',
      'transactions.addAccount' => 'Добавить счёт',
      'transactions.oneAccountHint' => 'Для перевода нужен второй счёт.',
      'transactions.noCategoriesHint' =>
        'Добавьте категории, чтобы разбирать траты.',
      'transactions.addCategories' => 'Добавить категории',
      'transactions.search' => 'Поиск',
      'transactions.searchHint' => 'Кафе, 250 или заметка',
      'transactions.clearSearch' => 'Очистить поиск',
      'transactions.filterAll' => 'Все',
      'transactions.filterExpenses' => 'Расходы',
      'transactions.filterIncome' => 'Доходы',
      'transactions.filterTransfers' => 'Переводы',
      'transactions.pickMonth' => 'Выбрать месяц',
      'transactions.noOperationsTitle' => 'Пока нет операций',
      'transactions.noOperationsHint' =>
        'Нажмите плюс внизу, чтобы записать первую.',
      'transactions.nothingFound' => 'Ничего не нашлось',
      'transactions.failedToReadOperations' => 'Не удалось прочитать операции.',
      'transactions.failedToDelete' =>
        'Не удалось удалить. Попробуйте ещё раз.',
      'transactions.operation' => 'Операция',
      'transactions.edit' => 'Изменить',
      'transactions.editOperation' => 'Изменить операцию',
      'transactions.repeat' => 'Повторить',
      'transactions.delete' => 'Удалить',
      'transactions.deleteTitle' => 'Удалить операцию?',
      'transactions.cancel' => 'Отмена',
      'transactions.back' => 'Назад',
      'transactions.category' => 'Категория',
      'transactions.from' => 'Откуда',
      'transactions.date' => 'Дата',
      'transactions.sources.manual' => 'Вручную',
      'transactions.sources.import' => 'Из выписки',
      'transactions.sources.notification' => 'Из уведомления',
      'transactions.sources.recurring' => 'Регулярная',
      'transactions.sources.bank' => 'Из банка',
      'transactions.keys.point' => 'Запятая',
      'transactions.keys.add' => 'Плюс',
      'transactions.keys.subtract' => 'Минус',
      'transactions.keys.multiply' => 'Умножить',
      'transactions.keys.divide' => 'Разделить',
      'transactions.keys.backspace' => 'Стереть',
      'transactions.dayOfMonth' =>
        ({required Object day, required Object month}) => '${day} ${month}',
      'transactions.months.0' => 'января',
      'transactions.months.1' => 'февраля',
      'transactions.months.2' => 'марта',
      'transactions.months.3' => 'апреля',
      'transactions.months.4' => 'мая',
      'transactions.months.5' => 'июня',
      'transactions.months.6' => 'июля',
      'transactions.months.7' => 'августа',
      'transactions.months.8' => 'сентября',
      'transactions.months.9' => 'октября',
      'transactions.months.10' => 'ноября',
      'transactions.months.11' => 'декабря',
      'transactions.monthNames.0' => 'Январь',
      'transactions.monthNames.1' => 'Февраль',
      'transactions.monthNames.2' => 'Март',
      'transactions.monthNames.3' => 'Апрель',
      'transactions.monthNames.4' => 'Май',
      'transactions.monthNames.5' => 'Июнь',
      'transactions.monthNames.6' => 'Июль',
      'transactions.monthNames.7' => 'Август',
      'transactions.monthNames.8' => 'Сентябрь',
      'transactions.monthNames.9' => 'Октябрь',
      'transactions.monthNames.10' => 'Ноябрь',
      'transactions.monthNames.11' => 'Декабрь',
      _ => null,
    };
  }
}
