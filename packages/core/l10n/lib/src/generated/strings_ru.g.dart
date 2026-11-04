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
  late final _Translations$backup$ru backup = _Translations$backup$ru._(_root);
  @override
  late final _Translations$categories$ru categories =
      _Translations$categories$ru._(_root);
  @override
  late final _Translations$demo$ru demo = _Translations$demo$ru._(_root);
  @override
  late final _Translations$help$ru help = _Translations$help$ru._(_root);
  @override
  late final _Translations$onboarding$ru onboarding =
      _Translations$onboarding$ru._(_root);
  @override
  late final _Translations$overview$ru overview = _Translations$overview$ru._(
    _root,
  );
  @override
  late final _Translations$reports$ru reports = _Translations$reports$ru._(
    _root,
  );
  @override
  late final _Translations$settings$ru settings = _Translations$settings$ru._(
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
  String get data => 'Данные';
  @override
  String get support => 'Поддержка';
  @override
  String get help => 'Помощь и отзыв';
}

// Path: backup
class _Translations$backup$ru extends Translations$backup$en {
  _Translations$backup$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Данные';
  @override
  String get back => 'Назад';
  @override
  String get storedTitle => 'Учёт хранится здесь';
  @override
  String get storedText =>
      'Только на этом устройстве, без серверов. Копия в файле поможет перенести его или не потерять.';
  @override
  String get noCopyYet => 'Копии ещё не было';
  @override
  String lastCopy({required Object when}) => 'Последняя копия: ${when}';
  @override
  String todayAt({required Object time}) => 'сегодня, ${time}';
  @override
  String yesterdayAt({required Object time}) => 'вчера, ${time}';
  @override
  String dayAt({required Object day, required Object time}) =>
      '${day}, ${time}';
  @override
  String get operations => 'Операции';
  @override
  String get accounts => 'Счета';
  @override
  String get categories => 'Категории';
  @override
  String get save => 'Сохранить копию';
  @override
  String get restore => 'Восстановить из копии';
  @override
  String get export => 'Экспорт';
  @override
  String get exportTitle => 'Операции в CSV';
  @override
  String get exportText =>
      'Для Excel и Google Таблиц: дата, сумма, валюта, счёт, категория';
  @override
  String get records => 'Учёт';
  @override
  String get demo => 'Демо-данные';
  @override
  String get demoText => 'Пример счетов и операций, чтобы осмотреться';
  @override
  String get wipe => 'Удалить все данные';
  @override
  String get filesNote =>
      'Файлы сохраняются только туда, куда вы укажете в окне системы.';
  @override
  String get filesNoteSite =>
      'Файлы сохраняются туда же, куда браузер кладёт загрузки.';
  @override
  String get restoreTitle => 'Восстановить из копии?';
  @override
  String get restoreText =>
      'Записи на этом устройстве заменятся содержимым файла. Отменить это нельзя, поэтому сначала сохраните копию нынешних, если они нужны.';
  @override
  String get replace => 'Заменить записи';
  @override
  String get cancel => 'Отмена';
  @override
  String get wipeTitle => 'Удалить все данные?';
  @override
  String get wipeText =>
      'Счета, операции и категории исчезнут с этого устройства. Язык и другие настройки останутся. Без копии вернуть записи не получится.';
  @override
  String get saveFirst => 'Сначала сохранить копию';
  @override
  String get wipeAll => 'Удалить всё';
  @override
  String saved({required Object name}) => 'Копия готова: ${name}';
  @override
  String restored({required Object day}) =>
      'Записи восстановлены из копии от ${day}';
  @override
  String exported({required Object name}) => 'Файл готов: ${name}';
  @override
  String get wiped => 'Все данные удалены с этого устройства';
  @override
  String get notACopy => 'Это не копия Birka.';
  @override
  String get newer =>
      'Эту копию сделала более новая версия Birka. Обновите приложение и попробуйте снова.';
  @override
  String get damaged => 'Копия повреждена, её не получится восстановить.';
  @override
  String get failed => 'Не получилось. Попробуйте ещё раз.';
  @override
  String operationsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} операция',
        few: '${count} операции',
        many: '${count} операций',
        other: '${count} операции',
      );
  @override
  String accountsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} счёт',
        few: '${count} счёта',
        many: '${count} счетов',
        other: '${count} счёта',
      );
  @override
  late final _Translations$backup$csv$ru csv = _Translations$backup$csv$ru._(
    _root,
  );
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

// Path: demo
class _Translations$demo$ru extends Translations$demo$en {
  _Translations$demo$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get card => 'Зарплатная карта';
  @override
  String get cash => 'Наличные';
  @override
  String get savings => 'Накопления';
  @override
  String get euro => 'Карта в евро';
  @override
  String get advance => 'Аванс';
  @override
  String get salary => 'Зарплата';
  @override
  String get project => 'Подработка';
  @override
  String get interest => 'Проценты на остаток';
  @override
  String get supermarket => 'Супермаркет';
  @override
  String get market => 'Рынок';
  @override
  String get bakery => 'Пекарня';
  @override
  String get coffee => 'Кофейня';
  @override
  String get lunch => 'Обед с коллегами';
  @override
  String get metro => 'Метро';
  @override
  String get taxi => 'Такси';
  @override
  String get utilities => 'Коммуналка';
  @override
  String get phone => 'Связь и интернет';
  @override
  String get music => 'Музыка';
  @override
  String get movies => 'Кино и сериалы';
  @override
  String get pharmacy => 'Аптека';
  @override
  String get cinema => 'Кино';
  @override
  String get concert => 'Концерт';
  @override
  String get clothes => 'Одежда';
  @override
  String get gift => 'Подарок';
  @override
  String get hotel => 'Гостиница';
  @override
  String get trip => 'Поездка';
  @override
  String get toCash => 'Снятие наличных';
  @override
  String get toSavings => 'В накопления';
  @override
  String get toEuro => 'Евро на поездку';
}

// Path: help
class _Translations$help$ru extends Translations$help$en {
  _Translations$help$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Помощь';
  @override
  String get back => 'Назад';
  @override
  String get search => 'Поиск по справке';
  @override
  String get clearSearch => 'Очистить поиск';
  @override
  String get questions => 'Частые вопросы';
  @override
  String get nothingFound =>
      'Ничего не нашлось. Напишите разработчику: ответ пригодится и другим, он появится в справке.';
  @override
  String get storageQuestion => 'Где хранятся мои данные?';
  @override
  String get storageAnswer =>
      'Только на этом устройстве или в этом браузере. Birka не отправляет записи на сервер и не просит пароли от банков.';
  @override
  String get moveQuestion => 'Как перенести учёт на другое устройство?';
  @override
  String get moveAnswer =>
      'Сохраните копию в «Ещё → Данные», перешлите файл себе и восстановите его на новом устройстве. Синхронизация появится позже.';
  @override
  String get ratesQuestion => 'Откуда берётся курс валют?';
  @override
  String get ratesAnswer =>
      'Это курс Банка России на день операции. Курсы обновляются раз в день и хранятся на устройстве.';
  @override
  String get importQuestion => 'Можно ли загрузить операции из банка?';
  @override
  String get importAnswer =>
      'Пока операции вносятся вручную. Загрузка выписок банков — следующая большая функция.';
  @override
  String get hideQuestion => 'Как скрыть суммы?';
  @override
  String get hideAnswer =>
      'Нажмите на глаз на Обзоре. Чтобы суммы были скрыты с самого запуска, включите «Скрывать суммы» в «Ещё».';
  @override
  String get contact => 'Связаться';
  @override
  String get write => 'Написать разработчику';
  @override
  String get writeText => 'Откроется ваша почта';
  @override
  String get bug => 'Сообщить об ошибке';
  @override
  String get bugText =>
      'В письмо добавятся версия и система, без ваших записей';
  @override
  String get idea => 'Предложить идею';
  @override
  String get ideaText => 'Расскажите, чего не хватает в Birka';
  @override
  String get github => 'Ошибки и идеи на GitHub';
  @override
  String get githubText => 'Публично: не пишите туда суммы и названия счетов';
  @override
  String get letterTitle => 'Письмо разработчику';
  @override
  String get letterText =>
      'Откроется ваша почта с этим письмом. В нём будет только то, что видно ниже, и вы сможете его дописать.';
  @override
  String get to => 'Кому';
  @override
  String get subject => 'Тема';
  @override
  String get letterPrivacy =>
      'Операции, суммы и названия счетов в письмо не попадают.';
  @override
  String get openMail => 'Открыть почту';
  @override
  String get cancel => 'Отмена';
  @override
  String get questionSubject => 'Birka · вопрос';
  @override
  String bugSubject({required Object version}) => 'Birka ${version} · ошибка';
  @override
  String get ideaSubject => 'Birka · идея';
  @override
  String get questionBody => 'Здравствуйте!\n';
  @override
  String get bugBody => 'Что случилось:\n\nЧто ожидали:';
  @override
  String get ideaBody => 'Чего не хватает:\n\nКак это помогло бы:';
  @override
  String get language => 'русский';
  @override
  String about({
    required Object version,
    required Object system,
    required Object language,
  }) => 'Birka ${version} · ${system} · ${language}';
  @override
  String noMail({required Object address}) =>
      'Почта не открылась. Адрес скопирован: ${address}';
  @override
  String get noPage => 'Страница не открылась. Попробуйте ещё раз.';
}

// Path: onboarding
class _Translations$onboarding$ru extends Translations$onboarding$en {
  _Translations$onboarding$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get skip => 'Пропустить';
  @override
  String get back => 'Назад';
  @override
  String get failed => 'Не удалось сохранить. Попробуйте ещё раз.';
  @override
  late final _Translations$onboarding$welcome$ru welcome =
      _Translations$onboarding$welcome$ru._(_root);
  @override
  late final _Translations$onboarding$account$ru account =
      _Translations$onboarding$account$ru._(_root);
  @override
  late final _Translations$onboarding$categories$ru categories =
      _Translations$onboarding$categories$ru._(_root);
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
  String rateOn({required Object day}) => 'Курс ЦБ РФ на ${day}';
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
  String get dayRates => 'Курс ЦБ РФ на день операции';
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

// Path: settings
class _Translations$settings$ru extends Translations$settings$en {
  _Translations$settings$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get general => 'Основное';
  @override
  String get language => 'Язык';
  @override
  String get deviceLanguage => 'Как на устройстве';
  @override
  String get english => 'English';
  @override
  String get russian => 'Русский';
  @override
  String get baseCurrency => 'Базовая валюта';
  @override
  String get firstAccountCurrency => 'Первый счёт';
  @override
  String get ratesCredit => 'Курсы ЦБ РФ в XML и JSON, API';
  @override
  String get security => 'Безопасность';
  @override
  String get hideAmounts => 'Скрывать суммы';
  @override
  String get onLaunch => 'При запуске';
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
  String get noAccountOperations => 'По этому счёту операций пока нет.';
  @override
  String get balanceChart => 'Остаток за период';
  @override
  String get accountGone => 'Этого счёта больше нет.';
  @override
  String get noOperationsHint => 'Нажмите плюс, чтобы записать первую.';
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

// Path: backup.csv
class _Translations$backup$csv$ru extends Translations$backup$csv$en {
  _Translations$backup$csv$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get date => 'Дата';
  @override
  String get kind => 'Тип';
  @override
  String get amount => 'Сумма';
  @override
  String get currency => 'Валюта';
  @override
  String get account => 'Счёт';
  @override
  String get category => 'Категория';
  @override
  String get subcategory => 'Подкатегория';
  @override
  String get note => 'Заметка';
  @override
  String get expense => 'Расход';
  @override
  String get income => 'Доход';
  @override
  String get transfer => 'Перевод';
  @override
  String get adjustment => 'Корректировка';
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

// Path: onboarding.welcome
class _Translations$onboarding$welcome$ru
    extends Translations$onboarding$welcome$en {
  _Translations$onboarding$welcome$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Все деньги —\nв одном месте';
  @override
  String get text =>
      'Счета в любой валюте и без паролей от банков. Данные остаются на вашем устройстве.';
  @override
  String get start => 'Начать';
}

// Path: onboarding.account
class _Translations$onboarding$account$ru
    extends Translations$onboarding$account$en {
  _Translations$onboarding$account$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Первый счёт';
  @override
  String get text =>
      'С него начнётся капитал. Остаток можно поправить в любой момент.';
  @override
  String get next => 'Дальше';
}

// Path: onboarding.categories
class _Translations$onboarding$categories$ru
    extends Translations$onboarding$categories$en {
  _Translations$onboarding$categories$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Категории';
  @override
  String get text => 'Возьмите готовый набор. Его можно менять в любой момент.';
  @override
  String get short => 'Короткий набор';
  @override
  String get full => 'Полный набор';
  @override
  String count({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${n} категория',
        few: '${n} категории',
        many: '${n} категорий',
        other: '${n} категории',
      );
  @override
  String get finish => 'Готово';
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
      'app.data' => 'Данные',
      'app.support' => 'Поддержка',
      'app.help' => 'Помощь и отзыв',
      'backup.title' => 'Данные',
      'backup.back' => 'Назад',
      'backup.storedTitle' => 'Учёт хранится здесь',
      'backup.storedText' =>
        'Только на этом устройстве, без серверов. Копия в файле поможет перенести его или не потерять.',
      'backup.noCopyYet' => 'Копии ещё не было',
      'backup.lastCopy' =>
        ({required Object when}) => 'Последняя копия: ${when}',
      'backup.todayAt' => ({required Object time}) => 'сегодня, ${time}',
      'backup.yesterdayAt' => ({required Object time}) => 'вчера, ${time}',
      'backup.dayAt' =>
        ({required Object day, required Object time}) => '${day}, ${time}',
      'backup.operations' => 'Операции',
      'backup.accounts' => 'Счета',
      'backup.categories' => 'Категории',
      'backup.save' => 'Сохранить копию',
      'backup.restore' => 'Восстановить из копии',
      'backup.export' => 'Экспорт',
      'backup.exportTitle' => 'Операции в CSV',
      'backup.exportText' =>
        'Для Excel и Google Таблиц: дата, сумма, валюта, счёт, категория',
      'backup.records' => 'Учёт',
      'backup.demo' => 'Демо-данные',
      'backup.demoText' => 'Пример счетов и операций, чтобы осмотреться',
      'backup.wipe' => 'Удалить все данные',
      'backup.filesNote' =>
        'Файлы сохраняются только туда, куда вы укажете в окне системы.',
      'backup.filesNoteSite' =>
        'Файлы сохраняются туда же, куда браузер кладёт загрузки.',
      'backup.restoreTitle' => 'Восстановить из копии?',
      'backup.restoreText' =>
        'Записи на этом устройстве заменятся содержимым файла. Отменить это нельзя, поэтому сначала сохраните копию нынешних, если они нужны.',
      'backup.replace' => 'Заменить записи',
      'backup.cancel' => 'Отмена',
      'backup.wipeTitle' => 'Удалить все данные?',
      'backup.wipeText' =>
        'Счета, операции и категории исчезнут с этого устройства. Язык и другие настройки останутся. Без копии вернуть записи не получится.',
      'backup.saveFirst' => 'Сначала сохранить копию',
      'backup.wipeAll' => 'Удалить всё',
      'backup.saved' => ({required Object name}) => 'Копия готова: ${name}',
      'backup.restored' =>
        ({required Object day}) => 'Записи восстановлены из копии от ${day}',
      'backup.exported' => ({required Object name}) => 'Файл готов: ${name}',
      'backup.wiped' => 'Все данные удалены с этого устройства',
      'backup.notACopy' => 'Это не копия Birka.',
      'backup.newer' =>
        'Эту копию сделала более новая версия Birka. Обновите приложение и попробуйте снова.',
      'backup.damaged' => 'Копия повреждена, её не получится восстановить.',
      'backup.failed' => 'Не получилось. Попробуйте ещё раз.',
      'backup.operationsCount' =>
        ({required num n, required Object count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one: '${count} операция',
              few: '${count} операции',
              many: '${count} операций',
              other: '${count} операции',
            ),
      'backup.accountsCount' =>
        ({required num n, required Object count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one: '${count} счёт',
              few: '${count} счёта',
              many: '${count} счетов',
              other: '${count} счёта',
            ),
      'backup.csv.date' => 'Дата',
      'backup.csv.kind' => 'Тип',
      'backup.csv.amount' => 'Сумма',
      'backup.csv.currency' => 'Валюта',
      'backup.csv.account' => 'Счёт',
      'backup.csv.category' => 'Категория',
      'backup.csv.subcategory' => 'Подкатегория',
      'backup.csv.note' => 'Заметка',
      'backup.csv.expense' => 'Расход',
      'backup.csv.income' => 'Доход',
      'backup.csv.transfer' => 'Перевод',
      'backup.csv.adjustment' => 'Корректировка',
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
      'demo.card' => 'Зарплатная карта',
      'demo.cash' => 'Наличные',
      'demo.savings' => 'Накопления',
      'demo.euro' => 'Карта в евро',
      'demo.advance' => 'Аванс',
      'demo.salary' => 'Зарплата',
      'demo.project' => 'Подработка',
      'demo.interest' => 'Проценты на остаток',
      'demo.supermarket' => 'Супермаркет',
      'demo.market' => 'Рынок',
      'demo.bakery' => 'Пекарня',
      'demo.coffee' => 'Кофейня',
      'demo.lunch' => 'Обед с коллегами',
      'demo.metro' => 'Метро',
      'demo.taxi' => 'Такси',
      'demo.utilities' => 'Коммуналка',
      'demo.phone' => 'Связь и интернет',
      'demo.music' => 'Музыка',
      'demo.movies' => 'Кино и сериалы',
      'demo.pharmacy' => 'Аптека',
      'demo.cinema' => 'Кино',
      'demo.concert' => 'Концерт',
      'demo.clothes' => 'Одежда',
      'demo.gift' => 'Подарок',
      'demo.hotel' => 'Гостиница',
      'demo.trip' => 'Поездка',
      'demo.toCash' => 'Снятие наличных',
      'demo.toSavings' => 'В накопления',
      'demo.toEuro' => 'Евро на поездку',
      'help.title' => 'Помощь',
      'help.back' => 'Назад',
      'help.search' => 'Поиск по справке',
      'help.clearSearch' => 'Очистить поиск',
      'help.questions' => 'Частые вопросы',
      'help.nothingFound' =>
        'Ничего не нашлось. Напишите разработчику: ответ пригодится и другим, он появится в справке.',
      'help.storageQuestion' => 'Где хранятся мои данные?',
      'help.storageAnswer' =>
        'Только на этом устройстве или в этом браузере. Birka не отправляет записи на сервер и не просит пароли от банков.',
      'help.moveQuestion' => 'Как перенести учёт на другое устройство?',
      'help.moveAnswer' =>
        'Сохраните копию в «Ещё → Данные», перешлите файл себе и восстановите его на новом устройстве. Синхронизация появится позже.',
      'help.ratesQuestion' => 'Откуда берётся курс валют?',
      'help.ratesAnswer' =>
        'Это курс Банка России на день операции. Курсы обновляются раз в день и хранятся на устройстве.',
      'help.importQuestion' => 'Можно ли загрузить операции из банка?',
      'help.importAnswer' =>
        'Пока операции вносятся вручную. Загрузка выписок банков — следующая большая функция.',
      'help.hideQuestion' => 'Как скрыть суммы?',
      'help.hideAnswer' =>
        'Нажмите на глаз на Обзоре. Чтобы суммы были скрыты с самого запуска, включите «Скрывать суммы» в «Ещё».',
      'help.contact' => 'Связаться',
      'help.write' => 'Написать разработчику',
      'help.writeText' => 'Откроется ваша почта',
      'help.bug' => 'Сообщить об ошибке',
      'help.bugText' =>
        'В письмо добавятся версия и система, без ваших записей',
      'help.idea' => 'Предложить идею',
      'help.ideaText' => 'Расскажите, чего не хватает в Birka',
      'help.github' => 'Ошибки и идеи на GitHub',
      'help.githubText' => 'Публично: не пишите туда суммы и названия счетов',
      'help.letterTitle' => 'Письмо разработчику',
      'help.letterText' =>
        'Откроется ваша почта с этим письмом. В нём будет только то, что видно ниже, и вы сможете его дописать.',
      'help.to' => 'Кому',
      'help.subject' => 'Тема',
      'help.letterPrivacy' =>
        'Операции, суммы и названия счетов в письмо не попадают.',
      'help.openMail' => 'Открыть почту',
      'help.cancel' => 'Отмена',
      'help.questionSubject' => 'Birka · вопрос',
      'help.bugSubject' =>
        ({required Object version}) => 'Birka ${version} · ошибка',
      'help.ideaSubject' => 'Birka · идея',
      'help.questionBody' => 'Здравствуйте!\n',
      'help.bugBody' => 'Что случилось:\n\nЧто ожидали:',
      'help.ideaBody' => 'Чего не хватает:\n\nКак это помогло бы:',
      'help.language' => 'русский',
      'help.about' =>
        ({
          required Object version,
          required Object system,
          required Object language,
        }) => 'Birka ${version} · ${system} · ${language}',
      'help.noMail' =>
        ({required Object address}) =>
            'Почта не открылась. Адрес скопирован: ${address}',
      'help.noPage' => 'Страница не открылась. Попробуйте ещё раз.',
      'onboarding.skip' => 'Пропустить',
      'onboarding.back' => 'Назад',
      'onboarding.failed' => 'Не удалось сохранить. Попробуйте ещё раз.',
      'onboarding.welcome.title' => 'Все деньги —\nв одном месте',
      'onboarding.welcome.text' =>
        'Счета в любой валюте и без паролей от банков. Данные остаются на вашем устройстве.',
      'onboarding.welcome.start' => 'Начать',
      'onboarding.account.title' => 'Первый счёт',
      'onboarding.account.text' =>
        'С него начнётся капитал. Остаток можно поправить в любой момент.',
      'onboarding.account.next' => 'Дальше',
      'onboarding.categories.title' => 'Категории',
      'onboarding.categories.text' =>
        'Возьмите готовый набор. Его можно менять в любой момент.',
      'onboarding.categories.short' => 'Короткий набор',
      'onboarding.categories.full' => 'Полный набор',
      'onboarding.categories.count' =>
        ({required num n}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one: '${n} категория',
              few: '${n} категории',
              many: '${n} категорий',
              other: '${n} категории',
            ),
      'onboarding.categories.finish' => 'Готово',
      'overview.capital' => 'Капитал',
      'overview.rateOn' => ({required Object day}) => 'Курс ЦБ РФ на ${day}',
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
      'reports.dayRates' => 'Курс ЦБ РФ на день операции',
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
      'settings.general' => 'Основное',
      'settings.language' => 'Язык',
      'settings.deviceLanguage' => 'Как на устройстве',
      'settings.english' => 'English',
      'settings.russian' => 'Русский',
      'settings.baseCurrency' => 'Базовая валюта',
      'settings.firstAccountCurrency' => 'Первый счёт',
      'settings.ratesCredit' => 'Курсы ЦБ РФ в XML и JSON, API',
      'settings.security' => 'Безопасность',
      'settings.hideAmounts' => 'Скрывать суммы',
      'settings.onLaunch' => 'При запуске',
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
      'transactions.noAccountOperations' => 'По этому счёту операций пока нет.',
      'transactions.balanceChart' => 'Остаток за период',
      'transactions.accountGone' => 'Этого счёта больше нет.',
      'transactions.noOperationsHint' => 'Нажмите плюс, чтобы записать первую.',
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
