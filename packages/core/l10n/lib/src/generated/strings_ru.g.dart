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
  late final _Translations$imports$ru imports = _Translations$imports$ru._(
    _root,
  );
  @override
  late final _Translations$inbox$ru inbox = _Translations$inbox$ru._(_root);
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
  late final _Translations$schedules$ru schedules =
      _Translations$schedules$ru._(_root);
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
  String get noCategory => 'Без категории';
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
  @override
  String get keptOnDevice => 'данные хранятся на этом устройстве';
  @override
  String get keptInBrowser => 'данные хранятся в этом браузере';
  @override
  String get sourceCode => 'Исходный код на GitHub';
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

// Path: imports
class _Translations$imports$ru extends Translations$imports$en {
  _Translations$imports$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get account => 'Счёт из выписки';
  @override
  Map<String, String> get formats => {
    'alfa': 'Альфа-Банк',
    'tbank': 'Т-Банк',
    'sber': 'Сбербанк',
    'zenmoney': 'Дзен-мани',
    'wise': 'Wise',
    'revolut': 'Revolut',
  };
  @override
  Map<String, String> get formatsOf => {
    'alfa': 'Альфа-Банка',
    'tbank': 'Т-Банка',
    'sber': 'Сбербанка',
    'zenmoney': 'Дзен-мани',
    'wise': 'Wise',
    'revolut': 'Revolut',
  };
  @override
  String get title => 'Импорт выписки';
  @override
  String get back => 'Назад';
  @override
  String stepOf({
    required Object n,
    required Object count,
    required Object what,
  }) => 'Шаг ${n} из ${count} · ${what}';
  @override
  Map<String, String> get steps => {
    'file': 'Файл',
    'format': 'Банк',
    'columns': 'Колонки',
    'account': 'Счёт',
    'copies': 'Дубликаты',
    'done': 'Итог',
  };
  @override
  Map<String, String> get stepWhat => {
    'file': 'файл из банка или Дзен-мани',
    'format': 'чья это выписка',
    'columns': 'как прочитать колонки',
    'account': 'куда записать',
    'copies': 'что уже есть в учёте',
    'done': 'итог',
  };
  @override
  String get stepsLabel => 'Шаги импорта';
  @override
  String get failed => 'Не получилось. Попробуйте ещё раз.';
  @override
  String get dropTitle => 'Перетащите выписку сюда';
  @override
  String get dropText =>
      'Файл из интернет-банка за любой период. Birka узнает банк по колонкам и покажет, как прочитала каждую строку, прежде чем что-то записать.';
  @override
  String get choose => 'Выбрать файл';
  @override
  String get reading => 'Читаем файл…';
  @override
  List<String> get kinds => [
    'CSV',
    'Excel, XLSX',
    'PDF Сбербанка',
    'Выгрузка Дзен-мани',
  ];
  @override
  String get dropNote =>
      'PDF читаем у Сбербанка · до 10 000 строк в одном файле';
  @override
  String get unreadableTitle => 'Файл не прочитался';
  @override
  Map<String, String> get unreadable => {
    'pdf':
        'Этот PDF не прочитать. Birka читает выписки Сбербанка, а у других банков возьмите CSV или Excel.',
    'notATable':
        'В файле нет таблицы операций. Нужен CSV, Excel или PDF Сбербанка.',
    'damaged': 'Файл повреждён. Скачайте выписку заново.',
    'empty': 'В файле пусто.',
    'tooLarge':
        'Файл слишком большой. Возьмите выписку покороче, до 10 000 строк.',
    'incomplete':
        'Операции выписки не сходятся с её итогами, часть не прочиталась. Скачайте выписку заново.',
  };
  @override
  String get howTitle => 'Как это устроено';
  @override
  List<String> get how => [
    'Узнаём банк по колонкам файла: Альфа-Банк, Т-Банк, Сбербанк, Дзен-мани, Wise, Revolut или ваш формат',
    'Показываем каждую строку так, как она попадёт в учёт',
    'Не задваиваем то, что вы уже записали вручную',
    'Импорт отменяется целиком, одной кнопкой, хоть через месяц',
  ];
  @override
  String get privacyTitle => 'Без паролей от банка';
  @override
  String get privacyText =>
      'Файл читается здесь, в браузере. Birka не входит в ваш банк и никуда не отправляет выписку.';
  @override
  String get whereTitle => 'Где взять выписку';
  @override
  String get whereBank => 'Интернет-банк';
  @override
  String get whereBankText =>
      'Раздел выписки или истории операций, формат CSV или Excel за нужные месяцы';
  @override
  String get whereZen => 'Дзен-мани';
  @override
  String get whereZenText =>
      'Экспорт операций в CSV из веб-версии: все счета, категории и годы истории разом';
  @override
  String get whereAbroad => 'Wise и Revolut';
  @override
  String get whereAbroadText =>
      'Statement в CSV: у каждой операции останется своя валюта';
  @override
  String get pastTitle => 'Прошлые импорты';
  @override
  String pastName({required Object format, required Object period}) =>
      '${format} · ${period}';
  @override
  String pastLine({
    required Object operations,
    required Object where,
    required Object day,
  }) => '${operations} → ${where} · ${day}';
  @override
  String operations({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} операция',
        few: '${count} операции',
        many: '${count} операций',
        other: '${count} операции',
      );
  @override
  String accounts({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} счёт',
        few: '${count} счёта',
        many: '${count} счетов',
        other: '${count} счёта',
      );
  @override
  String get undo => 'Отменить';
  @override
  String undoAsk({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'Убрать ${count} операцию этого файла?',
        few: 'Убрать ${count} операции этого файла?',
        many: 'Убрать ${count} операций этого файла?',
        other: 'Убрать ${count} операции этого файла?',
      );
  @override
  String get undoYes => 'Убрать';
  @override
  String get undoNo => 'Оставить';
  @override
  String undone({required Object name}) => 'Импорт «${name}» отменён';
  @override
  String looksLike({required Object bank}) => 'Похоже на выписку ${bank}';
  @override
  String matched({
    required num n,
    required Object total,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    one:
        'Совпала ${n} колонка из ${total}. По ней Birka разберёт файл, а вы проверите результат на следующем шаге.',
    few:
        'Совпали ${n} колонки из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
    many:
        'Совпали ${n} колонок из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
    other:
        'Совпали ${n} колонки из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
  );
  @override
  String get notKnown => 'Банк по колонкам не узнали';
  @override
  String get notKnownText =>
      'Выберите его ниже или назначьте колонки сами на следующем шаге.';
  @override
  String skipped({required Object header}) => '${header} — не берём';
  @override
  String get formatsTitle => 'Формат выписки';
  @override
  Map<String, String> get formatTexts => {
    'alfa': 'Операции одной карты или счёта',
    'tbank': 'Карты и счета, с категориями банка',
    'sber': 'PDF-выписка карты из СберБанк Онлайн',
    'zenmoney': 'Все счета, категории и переводы разом',
    'wise': 'У каждой операции своя валюта и курс',
    'revolut': 'У каждой операции своя валюта и комиссия',
  };
  @override
  String get own => 'Свой формат';
  @override
  String get ownTag => 'любой';
  @override
  String get ownText => 'Колонки назначите сами';
  @override
  Map<String, String> get fileKinds => {
    'csv': 'CSV',
    'xlsx': 'Excel',
    'pdf': 'PDF',
  };
  @override
  String get summaryTitle => 'Что попадёт в учёт';
  @override
  String get summaryFormat => 'Формат';
  @override
  String get summaryRows => 'Строк в файле';
  @override
  String get summaryPeriod => 'Период';
  @override
  String get summaryAccount => 'Счёт';
  @override
  String get accountLater => 'выберем на 4-м шаге';
  @override
  String get summaryOperations => 'Операций';
  @override
  String get summarySpent => 'Расходы';
  @override
  String get summaryReceived => 'Поступления';
  @override
  String get summaryUnsorted => 'Без категории';
  @override
  String toInbox({required Object count}) => '${count} → во «Входящие»';
  @override
  String get summaryBalance => 'Остаток после';
  @override
  String get summaryFromFile => 'Из файла';
  @override
  String get summaryCopies => 'Пропустим копий';
  @override
  String get summaryAdded => 'Добавим';
  @override
  Map<String, String> get next => {
    'format': 'Дальше: банк',
    'columns': 'Дальше: колонки',
    'account': 'Дальше: счёт',
    'copies': 'Дальше: дубликаты',
  };
  @override
  String write({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'Импортировать ${count} операцию',
        few: 'Импортировать ${count} операции',
        many: 'Импортировать ${count} операций',
        other: 'Импортировать ${count} операции',
      );
  @override
  String get nothingToWrite => 'Нечего добавить';
  @override
  String get planning => 'Считаем…';
  @override
  String writing({required Object done, required Object total}) =>
      'Записываем: ${done} из ${total}';
  @override
  String get writeNote => 'Весь импорт можно будет отменить одной кнопкой';
  @override
  String get columnsTitle => 'Колонки файла';
  @override
  Map<String, String> get roles => {
    'date': 'Дата',
    'amount': 'Сумма',
    'expense': 'Расход',
    'income': 'Поступление',
    'fee': 'Комиссия',
    'currency': 'Валюта',
    'expenseCurrency': 'Валюта расхода',
    'incomeCurrency': 'Валюта поступления',
    'account': 'Счёт',
    'expenseAccount': 'Счёт расхода',
    'incomeAccount': 'Счёт поступления',
    'description': 'Описание',
    'note': 'Заметка',
    'category': 'Категория банка',
    'ownCategory': 'Ваша категория',
    'card': 'Карта',
    'balance': 'Остаток',
    'status': 'Статус',
    'skip': 'Не брать',
  };
  @override
  String roleOf({required Object header}) => 'Что в колонке «${header}»';
  @override
  String get signTitle => 'Расход в файле записан';
  @override
  Map<String, String> get signs => {
    'expenseNegative': 'с минусом',
    'expensePositive': 'с плюсом',
    'incomePlus': 'без знака',
  };
  @override
  String get markTitle => 'Копейки отделены';
  @override
  Map<String, String> get marks => {
    'comma': 'запятой',
    'dot': 'точкой',
  };
  @override
  String get datesTitle => 'Даты';
  @override
  Map<String, String> get dateOrders => {
    'dayMonthYear': 'ДД.ММ.ГГГГ',
    'monthDayYear': 'ММ.ДД.ГГГГ',
  };
  @override
  String get missing =>
      'Отметьте колонку даты и колонку суммы: без них строки не станут операциями.';
  @override
  String get previewTitle => 'Так строки попадут в учёт';
  @override
  String previewNote({required Object shown, required Object total}) =>
      'первые ${shown} из ${total} · заголовок и итог не считаем';
  @override
  String get previewDate => 'Дата';
  @override
  String get previewText => 'Описание';
  @override
  String get previewCategory => 'Категория';
  @override
  String get previewAmount => 'Сумма';
  @override
  String get transfer => 'Перевод';
  @override
  String get learned => 'как раньше';
  @override
  String get inbox => 'Решу во «Входящих»';
  @override
  String problems({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} строка не прочиталась',
        few: '${count} строки не прочитались',
        many: '${count} строк не прочитались',
        other: '${count} строки не прочитались',
      );
  @override
  String problemLine({required Object line, required Object fault}) =>
      'Строка ${line}: ${fault}';
  @override
  String andMore({required Object count}) => 'и ещё ${count}';
  @override
  Map<String, String> get rowFaults => {
    'unreadableDate': 'дата не читается',
    'noSuchDay': 'такого дня нет',
    'noAmount': 'нет суммы',
    'unreadableAmount': 'сумма не читается',
    'zeroAmount': 'сумма ноль',
    'declined': 'операция не прошла',
  };
  @override
  String get categoriesTitle => 'Категории банка → ваши';
  @override
  String get categoriesNote => 'Без выбора операции подождут во «Входящих»';
  @override
  Map<String, String> get categoryKinds => {
    'expense': 'расход',
    'income': 'поступление',
  };
  @override
  String get noBankCategory => 'Без категории банка';
  @override
  String newCategory({required Object name}) => 'Новая: ${name}';
  @override
  String get fees => 'Комиссии банка';
  @override
  String categoryOf({required Object name}) => 'Категория для «${name}»';
  @override
  String accountTitleCard({required Object card}) =>
      'Куда записать операции карты ••${card}';
  @override
  String accountTitleNamed({required Object name}) =>
      'Куда записать операции «${name}»';
  @override
  String get accountTitle => 'Куда записать операции';
  @override
  String accountText({required Object operations}) =>
      '${operations}. Выберите счёт в Birka, заведите новый или не берите их.';
  @override
  String get cardMatched => 'совпал номер карты';
  @override
  String get nameMatched => 'совпало название';
  @override
  String otherCurrency({
    required Object currency,
    required Object fileCurrency,
  }) => '${currency}, а в файле ${fileCurrency}';
  @override
  String get newAccount => 'Новый счёт';
  @override
  String newAccountText({required Object name, required Object balance}) =>
      'Заведём «${name}» с остатком ${balance}';
  @override
  String get leaveOut => 'Не брать';
  @override
  String get leaveOutText => 'Операции этого счёта не попадут в учёт';
  @override
  String get balanceMatches => 'Остаток сойдётся с банком';
  @override
  String get balanceDiffers => 'Остаток разойдётся с банком';
  @override
  String balanceInFile({required Object day}) => 'В выписке на ${day}';
  @override
  String get balanceInBirka => 'В Birka после импорта';
  @override
  String get balanceHint =>
      'В учёте есть операции, которых нет в выписке, или их не хватает. Проверьте счёт и дубликаты.';
  @override
  String copiesTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} операция уже есть в учёте',
        few: '${count} операции уже есть в учёте',
        many: '${count} операций уже есть в учёте',
        other: '${count} операции уже есть в учёте',
      );
  @override
  String get copiesText =>
      'Похоже, вы записали их вручную. Копии из выписки пропустим, а ваши записи, с вашими названиями и категориями, останутся как есть.';
  @override
  String get noCopies => 'Повторов нет';
  @override
  String get noCopiesText =>
      'Ни одна операция выписки не похожа на то, что уже есть в учёте.';
  @override
  String get fromFile => 'Из выписки';
  @override
  String get inLedger => 'Уже в учёте';
  @override
  Map<String, String> get reasons => {
    'imported': 'из этого же файла',
    'sameAmount': 'та же сумма',
    'sameDay': 'тот же день',
    'dayBefore': 'на день раньше',
    'dayAfter': 'на день позже',
    'sameAccount': 'тот же счёт',
    'similarName': 'похожее название',
  };
  @override
  String get skipCopy => 'Пропустить копию';
  @override
  String get keepBoth => 'Оставить обе';
  @override
  String leftTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} операция не попадёт в учёт',
        few: '${count} операции не попадут в учёт',
        many: '${count} операций не попадут в учёт',
        other: '${count} операции не попадут в учёт',
      );
  @override
  Map<String, String> get planFaults => {
    'otherCurrency': 'у счёта другая валюта',
    'tooPrecise': 'больше знаков, чем у валюты',
    'unevenTransfer': 'перевод в одной валюте с двумя суммами',
  };
  @override
  String doneTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'Добавили ${count} операцию',
        few: 'Добавили ${count} операции',
        many: 'Добавили ${count} операций',
        other: 'Добавили ${count} операции',
      );
  @override
  String doneWhere({
    required Object format,
    required Object period,
    required Object accounts,
  }) => '${format}, ${period} → ${accounts}';
  @override
  String get doneIncome => 'Поступления';
  @override
  String get doneSpent => 'Новые траты';
  @override
  String get doneSkipped => 'Пропустили копий';
  @override
  String get doneBalance => 'Остаток счёта';
  @override
  String get asInBank => 'как в банке';
  @override
  String unsortedTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} ждёт вашего решения во «Входящих»',
        few: '${count} ждут вашего решения во «Входящих»',
        many: '${count} ждут вашего решения во «Входящих»',
        other: '${count} ждут вашего решения во «Входящих»',
      );
  @override
  String get unsortedText => 'В отчётах они уже есть, просто без категории.';
  @override
  String get sortInbox => 'Разобрать «Входящие»';
  @override
  String get undoTitle => 'Передумали?';
  @override
  String undoText({
    required num n,
    required Object count,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    one:
        'Отмена уберёт ${count} операцию этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
    few:
        'Отмена уберёт ${count} операции этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
    many:
        'Отмена уберёт ${count} операций этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
    other:
        'Отмена уберёт ${count} операции этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
  );
  @override
  String get undoImport => 'Отменить импорт';
  @override
  String get undoneTitle => 'Импорт отменён';
  @override
  String get undoneText =>
      'Операции этого файла убраны из учёта. Ваши записи остались как были.';
  @override
  String get toOperations => 'К операциям';
  @override
  String get another => 'Загрузить ещё выписку';
  @override
  List<String> get monthsWhole => [
    'январь',
    'февраль',
    'март',
    'апрель',
    'май',
    'июнь',
    'июль',
    'август',
    'сентябрь',
    'октябрь',
    'ноябрь',
    'декабрь',
  ];
  @override
  String periodMonth({required Object month, required Object year}) =>
      '${month} ${year}';
  @override
  String periodInMonth({
    required Object from,
    required Object to,
    required Object month,
    required Object year,
  }) => '${from}–${to} ${month} ${year}';
  @override
  String periodInYear({
    required Object from,
    required Object to,
    required Object year,
  }) => '${from} – ${to} ${year}';
  @override
  String periodFar({required Object from, required Object to}) =>
      '${from} – ${to}';
  @override
  String get cancel => 'Отмена';
  @override
  String get finish => 'Готово';
  @override
  String get readingTitle => 'Читаем выписку';
  @override
  String get readingNote => 'Файл читается на телефоне и никуда не уходит';
  @override
  String knownBy({required Object bank}) => '${bank} · узнали по колонкам';
  @override
  String operationsIn({required Object period}) => 'Операций за ${period}';
  @override
  String get alreadyIn => 'Уже есть в учёте';
  @override
  String willSkip({required Object count}) => '${count}, пропустим';
  @override
  String get sortLater => 'Разобрать потом';
  @override
  String inInbox({required Object count}) => '${count} во «Входящих»';
  @override
  String get unknownTitle => 'Формат не узнали';
  @override
  String columnsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} колонка',
        few: '${count} колонки',
        many: '${count} колонок',
        other: '${count} колонки',
      );
  @override
  String rowsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} строка',
        few: '${count} строки',
        many: '${count} строк',
        other: '${count} строки',
      );
  @override
  String get unknownText =>
      'Назначьте колонки этого файла, где дата и где сумма. Остальное Birka прочитает сама.';
  @override
  String get chooseAnother => 'Выбрать другой файл';
  @override
  String get assignColumns => 'Назначить колонки';
  @override
  String get columnsHeading => 'Колонки выписки';
  @override
  String get columnsText =>
      'Отметьте, где в файле дата и где сумма, и строки станут операциями.';
  @override
  Map<String, String> get roleNotes => {
    'date': 'день операции',
    'amount': 'расход и поступление в одной колонке',
    'expense': 'только списания',
    'income': 'только зачисления',
    'currency': 'RUB, USD, EUR…',
    'description': 'магазин, получатель или назначение',
    'category': 'разберём во «Входящих»',
    'balance': 'сверим с банком',
    'skip': 'колонку пропустим',
  };
  @override
  String get noAmounts =>
      'Ни одна сумма не прочиталась. Проверьте, чем в файле отделены копейки.';
  @override
  String columnsDone({required Object operations}) => 'Готово · ${operations}';
  @override
  String get ownColumns => 'колонки назначили вы';
  @override
  String get looksLikeOwn => 'Узнали ваш формат';
  @override
  String get categoriesHeading => 'Категории банка';
  @override
  String categoriesCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} категория в выписке',
        few: '${count} категории в выписке',
        many: '${count} категорий в выписке',
        other: '${count} категории в выписке',
      );
  @override
  String categoriesKnown({required Object known, required Object total}) =>
      '${known} из ${total} узнали сами';
  @override
  String get categoriesNone => 'Birka их пока не знает';
  @override
  String get categoriesAsBefore => 'Как в прошлой выписке';
  @override
  String categoriesKnownText({required Object known, required Object total}) =>
      '${known} из ${total} узнали по названиям. Операции сразу встанут в ваши категории, а без выбора подождут во «Входящих».';
  @override
  String get categoriesText =>
      'Выберите, куда записать операции каждой категории банка. Без выбора они подождут во «Входящих».';
  @override
  String categoriesAsBeforeText({required Object source}) =>
      'Взяли ваш выбор с прошлой выписки ${source}. Поменяйте, если что-то теперь иначе.';
  @override
  String get ownFormatOf => 'вашего формата';
  @override
  String get inboxNote => 'операции подождут без категории';
  @override
  String get newCategoryNote => 'появится при импорте';
  @override
  String get newCategoryMark => 'новая категория';
  @override
  String categoriesDone({required Object count}) =>
      'Готово · ${count} во «Входящих»';
  @override
  String categoriesKept({required Object source}) =>
      'Выбор запомним для выписок ${source}';
  @override
  String rowsLeft({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} строка не попадёт в учёт',
        few: '${count} строки не попадут в учёт',
        many: '${count} строк не попадут в учёт',
        other: '${count} строки не попадут в учёт',
      );
  @override
  String unreadCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} не прочиталась',
        few: '${count} не прочитались',
        many: '${count} не прочитались',
        other: '${count} не прочитались',
      );
  @override
  String declinedCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} не прошла в банке',
        few: '${count} не прошли в банке',
        many: '${count} не прошли в банке',
        other: '${count} не прошли в банке',
      );
  @override
  String unfitCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} не подходит счёту',
        few: '${count} не подходят счёту',
        many: '${count} не подходят счёту',
        other: '${count} не подходят счёту',
      );
  @override
  String restFine({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'ещё ${count} в порядке',
        few: 'остальные ${count} в порядке',
        many: 'остальные ${count} в порядке',
        other: 'остальные ${count} в порядке',
      );
  @override
  String get unreadTitle => 'Не прочитали';
  @override
  String get declinedTitle => 'Не прошли в банке';
  @override
  String get unfitTitle => 'Не подходят счёту';
  @override
  String rowLine({required Object line, required Object what}) =>
      'Строка ${line} · ${what}';
  @override
  String get leftNote =>
      'Непрочитанные запишите вручную или скачайте выписку заново: Birka добавит только то, чего ещё нет в учёте.';
  @override
  String get understood => 'Понятно';
  @override
  String bankHas({required Object amount}) => 'В банке ${amount}';
  @override
  String bankHasMissing({required Object amount}) =>
      'В банке ${amount}: похоже, не хватает непрочитанных строк';
  @override
  String mostUnread({
    required num n,
    required Object count,
    required Object total,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    one: '${count} строка из ${total} не прочиталась',
    few: '${count} строки из ${total} не прочитались',
    many: '${count} строк из ${total} не прочитались',
    other: '${count} строки из ${total} не прочитались',
  );
  @override
  String get mostUnreadText =>
      'Похоже, банк поменял выписку: проверьте, где в ней дата и сумма и чем отделены копейки.';
  @override
  String get checkColumns => 'Проверить колонки';
  @override
  String declinedRows({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} операция не прошла в банке',
        few: '${count} операции не прошли в банке',
        many: '${count} операций не прошли в банке',
        other: '${count} операции не прошли в банке',
      );
}

// Path: inbox
class _Translations$inbox$ru extends Translations$inbox$en {
  _Translations$inbox$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Входящие';
  @override
  String get back => 'Назад';
  @override
  String waiting({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} ждёт решения',
        few: '${count} ждут решения',
        many: '${count} ждут решения',
        other: '${count} ждут решения',
      );
  @override
  String afterImport({required Object bank}) => 'после импорта ${bank}';
  @override
  String afterFile({required Object name}) => 'после импорта «${name}»';
  @override
  Map<String, String> get filters => {
    'all': 'Все',
    'uncategorized': 'Без категории',
    'transfers': 'Переводы',
  };
  @override
  String get filtersLabel => 'Что показать';
  @override
  String get emptyTitle => 'Всё разобрано';
  @override
  String get emptyText =>
      'Здесь появятся операции без категории и переводы между вашими счетами, когда придут из выписки.';
  @override
  String get pairTitle => 'Похоже на перевод между вашими счетами';
  @override
  String get pairText => 'Не трата и не доход: капитал от него не изменится';
  @override
  String rate({required Object rate, required Object unit}) =>
      'Курс обмена ${rate} за ${unit}';
  @override
  String bankRate({required Object rate}) => 'ЦБ в тот день ${rate}';
  @override
  String get makeTransfer => 'Сделать переводом';
  @override
  String get notTransfer => 'Это доход';
  @override
  String get fromStatement => 'из выписки';
  @override
  String get uncategorized => 'Без категории';
  @override
  String section({required Object title, required Object count}) =>
      '${title} · ${count}';
  @override
  String get category => 'Категория';
  @override
  String get other => 'Другая';
  @override
  String get yes => 'Да';
  @override
  String categoryFor({required Object name}) => 'Категория для «${name}»';
  @override
  String sameName({
    required num n,
    required Object count,
    required Object when,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    one: 'так вы отметили его ${count} раз ${when}',
    few: 'так вы отметили его ${count} раза ${when}',
    many: 'так вы отметили его ${count} раз ${when}',
    other: 'так вы отметили его ${count} раза ${when}',
  );
  @override
  String everyMonth({required Object since}) =>
      'та же сумма каждый месяц ${since}';
  @override
  String sameImport({required Object name}) => 'как «${name}» в этой выписке';
  @override
  String similarName({required Object name, required Object when}) =>
      'как «${name}» ${when}';
  @override
  String since({required Object month}) => 'с ${month}';
  @override
  String more({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'и ещё ${count} операция',
        few: 'и ещё ${count} операции',
        many: 'и ещё ${count} операций',
        other: 'и ещё ${count} операции',
      );
  @override
  String picked({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'Выбрана ${count} операция',
        few: 'Выбраны ${count} операции',
        many: 'Выбрано ${count} операций',
        other: 'Выбрано ${count} операции',
      );
  @override
  String get pickedCategory => 'Категория для выбранных';
  @override
  String get pickAll => 'Выбрать все';
  @override
  String get pickNone => 'Снять выбор';
  @override
  String pick({required Object name}) => 'Выбрать «${name}»';
  @override
  String get sourceTitle => 'Откуда подсказки';
  @override
  String get sourceText =>
      'Из ваших прошлых решений: как вы уже называли эти места и какие категории им давали. Считается здесь, на устройстве.';
  @override
  String get learns =>
      'Каждое «Да» учит Birka: в следующей выписке такие операции придут уже с категорией.';
  @override
  String get stillCounted =>
      'Пока операция здесь, она уже есть в учёте и в отчётах, просто без категории.';
  @override
  String get failed => 'Не получилось. Попробуйте ещё раз.';
  @override
  String get madeTransfer => 'Сделали перевод';
  @override
  String accepted({required Object category}) =>
      '${category}: дальше Birka поставит сама';
  @override
  String sorted({required Object category, required Object operations}) =>
      '${category} · ${operations}';
  @override
  String get keptIncome => 'Оставили доходом';
  @override
  String get toImport => 'Загрузить выписку';
  @override
  String get hinted => 'подсказка';
  @override
  String get newCategory => 'Новая категория';
  @override
  String entryTitle({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} ждёт решения во «Входящих»',
        few: '${count} ждут решения во «Входящих»',
        many: '${count} ждут решения во «Входящих»',
        other: '${count} ждут решения во «Входящих»',
      );
  @override
  String entryUncategorized({required Object count}) =>
      '${count} без категории';
  @override
  String entryTransfer({required Object account}) =>
      'перевод со счёта «${account}»';
  @override
  String entryTransfers({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${count} перевод между счетами',
        few: '${count} перевода между счетами',
        many: '${count} переводов между счетами',
        other: '${count} перевода между счетами',
      );
  @override
  String entryBoth({required Object first, required Object second}) =>
      '${first} и ${second}';
  @override
  String get unpick => 'Снять';
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

// Path: schedules
class _Translations$schedules$ru extends Translations$schedules$en {
  _Translations$schedules$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Регулярные платежи';
  @override
  String get back => 'Назад';
  @override
  String get add => 'Новый платёж';
  @override
  String get close => 'Закрыть';
  @override
  String get waitingTitle => 'Ждёт подтверждения';
  @override
  String get post => 'Провести';
  @override
  String get skip => 'Пропустить';
  @override
  String get waitingNote => 'Придёт в выписке банка — Birka не задвоит его.';
  @override
  String waitingDay({required Object name, required Object day}) =>
      '${name} · ${day}';
  @override
  String get ahead => 'Ближайшие 30 дней';
  @override
  String aheadTotal({required Object date, required Object amount}) =>
      'до ${date} ${amount}';
  @override
  String leftAfterPayday({required Object date, required Object amount}) =>
      'К зарплате ${date} на счетах останется ≈ ${amount}, если не считать ежедневных трат.';
  @override
  String leftAfterMonth({required Object amount}) =>
      'К концу месяца на счетах останется ≈ ${amount}, если не считать ежедневных трат.';
  @override
  String section({required Object title, required Object count}) =>
      '${title} · ${count}';
  @override
  String get all => 'Все регулярные';
  @override
  String get emptyTitle => 'Регулярных платежей пока нет';
  @override
  String get emptyText =>
      'Аренда, подписки, зарплата: добавьте их один раз, и Birka покажет месяц вперёд и сколько можно тратить в день.';
  @override
  String get emptyAdd => 'Добавить платёж';
  @override
  String everyMonth({required Object day}) => 'каждый месяц ${day}-го';
  @override
  String everyWeek({required Object weekday}) => 'каждую неделю, ${weekday}';
  @override
  String everyYear({required Object date}) => 'раз в год, ${date}';
  @override
  String get asks => 'спросить';
  @override
  String get posts => 'проводится сам';
  @override
  String get today => 'сегодня';
  @override
  String get tomorrow => 'завтра';
  @override
  String posted({required Object name, required Object amount}) =>
      'Провели «${name}» · ${amount}';
  @override
  String skippedAsk({required Object name, required Object date}) =>
      'Пропустили «${name}» · спросим ${date}';
  @override
  String skippedPost({required Object name, required Object date}) =>
      'Пропустили «${name}» · следующий раз ${date}';
  @override
  String deleted({required Object name}) => 'Удалили «${name}»';
  @override
  String found({required Object name}) => 'Нашли «${name}» в выписке';
  @override
  String foundOf({required Object name, required Object bank}) =>
      'Нашли «${name}» в выписке ${bank}';
  @override
  String foundText({required Object date, required Object amount}) =>
      '${date} · ${amount} · отметили платёж проведённым, копии не будет';
  @override
  String donePosted({required Object date}) =>
      'проведён сегодня · следующий ${date}';
  @override
  String doneSkipped({required Object date}) => 'пропущен · следующий ${date}';
  @override
  String doneFound({required Object date}) =>
      'нашли в выписке · следующий ${date}';
  @override
  Map<String, String> get on => {
    'mon': 'по понедельникам',
    'tue': 'по вторникам',
    'wed': 'по средам',
    'thu': 'по четвергам',
    'fri': 'по пятницам',
    'sat': 'по субботам',
    'sun': 'по воскресеньям',
  };
  @override
  Map<String, String> get weekday => {
    'mon': 'пн',
    'tue': 'вт',
    'wed': 'ср',
    'thu': 'чт',
    'fri': 'пт',
    'sat': 'сб',
    'sun': 'вс',
  };
  @override
  String get newTitle => 'Новый платёж';
  @override
  Map<String, String> get kinds => {
    'expense': 'Расход',
    'income': 'Поступление',
    'transfer': 'Перевод',
  };
  @override
  String get kindLabel => 'Что за платёж';
  @override
  String get amount => 'Сумма';
  @override
  String get name => 'Название';
  @override
  String get namePlaceholder => 'Например, Аренда';
  @override
  String get category => 'Категория';
  @override
  String get noCategory => 'Без категории';
  @override
  String get categoryLater => 'решу во «Входящих»';
  @override
  String get account => 'Счёт';
  @override
  String get toAccount => 'Куда';
  @override
  String get fromAccount => 'Откуда';
  @override
  String get incomeAccount => 'На счёт';
  @override
  String get pickAccount => 'Выберите счёт';
  @override
  String get every => 'Повторять каждый';
  @override
  Map<String, String> get everyOptions => {
    'month': 'Месяц',
    'week': 'Неделю',
    'year': 'Год',
  };
  @override
  String get dayOfMonth => 'Какого числа';
  @override
  String get dayOfWeek => 'Какой день недели';
  @override
  String get dayOfYear => 'Какого дня';
  @override
  String dayNumber({required Object day}) => '${day}-го';
  @override
  String get next => 'Следующий раз';
  @override
  String get onDayTitle => 'В день платежа';
  @override
  Map<String, String> get onDay => {
    'ask': 'Спросить меня',
    'post': 'Провести само',
  };
  @override
  String get askNote =>
      'Подойдёт, если сумма меняется, как у ЖКХ: в этот день платёж подождёт вашего «Провести».';
  @override
  String get postNote =>
      'Для подписок с одной суммой. Придёт в выписке банка — копии не будет.';
  @override
  String get save => 'Сохранить';
  @override
  String get saveNote =>
      'Появится в «Ближайших платежах» и в «Можно тратить сегодня»';
  @override
  String changeNote({required Object date}) =>
      'Изменится со следующего раза: ${date}';
  @override
  String get done => 'Готово';
  @override
  String get delete => 'Удалить платёж';
  @override
  String get deleteNote => 'Прошлые операции останутся';
  @override
  String deleteTitle({required Object name}) => 'Удалить «${name}»?';
  @override
  String get canSpend => 'Можно тратить сегодня';
  @override
  String get overToday => 'Сегодня больше дневного';
  @override
  String ofPerDay({required Object amount}) => 'из ${amount} на день';
  @override
  String spentUntilPayday({required Object amount, required Object days}) =>
      'Потратили ${amount} · до зарплаты ${days}';
  @override
  String spentUntilMonth({required Object amount, required Object days}) =>
      'Потратили ${amount} · до конца месяца ${days}';
  @override
  String spentOver({required Object amount, required Object tomorrow}) =>
      'Потратили ${amount} · завтра можно ${tomorrow} в день';
  @override
  String short({required Object amount, required Object date}) =>
      'Не хватает ${amount} до ${date}';
  @override
  String get upcoming => 'Ближайшие платежи';
  @override
  String get noPaydayLabel => 'До зарплаты';
  @override
  String get noPaydayTitle => 'Сколько можно тратить в день?';
  @override
  String get noPaydayText =>
      'Укажите день зарплаты. Birka вычтет регулярные платежи до него и разделит остаток на дни.';
  @override
  String get noPaydayAction => 'Указать день зарплаты';
  @override
  String days({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${n} день',
        few: '${n} дня',
        many: '${n} дней',
        other: '${n} дней',
      );
  @override
  String get paydayTitle => 'Деньги до зарплаты';
  @override
  String perDay({required Object amount}) => '${amount} в день';
  @override
  String notEnough({required Object amount}) => 'Не хватает ${amount}';
  @override
  String untilPayday({required Object date, required Object days}) =>
      'до зарплаты ${date} · ${days}';
  @override
  String untilDate({required Object date, required Object days}) =>
      'до ${date} · ${days}';
  @override
  String get morning => 'Утром на счетах';
  @override
  String paymentsUntilPayday({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${n} платёж до зарплаты',
        few: '${n} платежа до зарплаты',
        many: '${n} платежей до зарплаты',
        other: '${n} платежей до зарплаты',
      );
  @override
  String paymentsUntilMonth({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: '${n} платёж до конца месяца',
        few: '${n} платежа до конца месяца',
        many: '${n} платежей до конца месяца',
        other: '${n} платежей до конца месяца',
      );
  @override
  String get aside => 'Отложить';
  @override
  String leftFor({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        one: 'Остаётся на ${n} день',
        few: 'Остаётся на ${n} дня',
        many: 'Остаётся на ${n} дней',
        other: 'Остаётся на ${n} дней',
      );
  @override
  String get countUntil => 'Считать до';
  @override
  Map<String, String> get until => {
    'payday': 'Дня зарплаты',
    'monthEnd': 'Конца месяца',
  };
  @override
  String get payday => 'День зарплаты';
  @override
  String paydayFrom({required Object name}) => 'из платежа «${name}»';
  @override
  String get paydayNone => 'добавьте регулярное поступление';
  @override
  String paydayDay({required Object day}) => '${day}-е число';
  @override
  String get accountsTitle => 'Какие счета считать';
  @override
  String count({required Object name}) => 'Считать «${name}»';
  @override
  String get otherCurrency => 'другая валюта, пока не считаем';
  @override
  String get asideRow => 'Отложить до зарплаты';
  @override
  String get asideNote => 'не тратим, даже если «можно»';
  @override
  String get salaryName => 'Зарплата';
  @override
  List<String> get monthsShort => [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
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
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
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
          'app.noCategory' => 'Без категории',
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
          'app.keptOnDevice' => 'данные хранятся на этом устройстве',
          'app.keptInBrowser' => 'данные хранятся в этом браузере',
          'app.sourceCode' => 'Исходный код на GitHub',
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
            ({required Object day}) =>
                'Записи восстановлены из копии от ${day}',
          'backup.exported' =>
            ({required Object name}) => 'Файл готов: ${name}',
          'backup.wiped' => 'Все данные удалены с этого устройства',
          'backup.notACopy' => 'Это не копия Birka.',
          'backup.newer' =>
            'Эту копию сделала более новая версия Birka. Обновите приложение и попробуйте снова.',
          'backup.damaged' => 'Копия повреждена, её не получится восстановить.',
          'backup.failed' => 'Не получилось. Попробуйте ещё раз.',
          'backup.operationsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} операция',
                  few: '${count} операции',
                  many: '${count} операций',
                  other: '${count} операции',
                ),
          'backup.accountsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
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
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
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
          'categories.form.failed' =>
            'Не удалось сохранить. Попробуйте ещё раз.',
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
          'help.githubText' =>
            'Публично: не пишите туда суммы и названия счетов',
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
          'imports.account' => 'Счёт из выписки',
          'imports.formats.alfa' => 'Альфа-Банк',
          'imports.formats.tbank' => 'Т-Банк',
          'imports.formats.sber' => 'Сбербанк',
          'imports.formats.zenmoney' => 'Дзен-мани',
          'imports.formats.wise' => 'Wise',
          'imports.formats.revolut' => 'Revolut',
          'imports.formatsOf.alfa' => 'Альфа-Банка',
          'imports.formatsOf.tbank' => 'Т-Банка',
          'imports.formatsOf.sber' => 'Сбербанка',
          'imports.formatsOf.zenmoney' => 'Дзен-мани',
          'imports.formatsOf.wise' => 'Wise',
          'imports.formatsOf.revolut' => 'Revolut',
          'imports.title' => 'Импорт выписки',
          'imports.back' => 'Назад',
          'imports.stepOf' =>
            ({
              required Object n,
              required Object count,
              required Object what,
            }) => 'Шаг ${n} из ${count} · ${what}',
          'imports.steps.file' => 'Файл',
          'imports.steps.format' => 'Банк',
          'imports.steps.columns' => 'Колонки',
          'imports.steps.account' => 'Счёт',
          'imports.steps.copies' => 'Дубликаты',
          'imports.steps.done' => 'Итог',
          'imports.stepWhat.file' => 'файл из банка или Дзен-мани',
          'imports.stepWhat.format' => 'чья это выписка',
          'imports.stepWhat.columns' => 'как прочитать колонки',
          'imports.stepWhat.account' => 'куда записать',
          'imports.stepWhat.copies' => 'что уже есть в учёте',
          'imports.stepWhat.done' => 'итог',
          'imports.stepsLabel' => 'Шаги импорта',
          'imports.failed' => 'Не получилось. Попробуйте ещё раз.',
          'imports.dropTitle' => 'Перетащите выписку сюда',
          'imports.dropText' =>
            'Файл из интернет-банка за любой период. Birka узнает банк по колонкам и покажет, как прочитала каждую строку, прежде чем что-то записать.',
          'imports.choose' => 'Выбрать файл',
          'imports.reading' => 'Читаем файл…',
          'imports.kinds.0' => 'CSV',
          'imports.kinds.1' => 'Excel, XLSX',
          'imports.kinds.2' => 'PDF Сбербанка',
          'imports.kinds.3' => 'Выгрузка Дзен-мани',
          'imports.dropNote' =>
            'PDF читаем у Сбербанка · до 10 000 строк в одном файле',
          'imports.unreadableTitle' => 'Файл не прочитался',
          'imports.unreadable.pdf' =>
            'Этот PDF не прочитать. Birka читает выписки Сбербанка, а у других банков возьмите CSV или Excel.',
          'imports.unreadable.notATable' =>
            'В файле нет таблицы операций. Нужен CSV, Excel или PDF Сбербанка.',
          'imports.unreadable.damaged' =>
            'Файл повреждён. Скачайте выписку заново.',
          'imports.unreadable.empty' => 'В файле пусто.',
          'imports.unreadable.tooLarge' =>
            'Файл слишком большой. Возьмите выписку покороче, до 10 000 строк.',
          'imports.unreadable.incomplete' =>
            'Операции выписки не сходятся с её итогами, часть не прочиталась. Скачайте выписку заново.',
          'imports.howTitle' => 'Как это устроено',
          'imports.how.0' =>
            'Узнаём банк по колонкам файла: Альфа-Банк, Т-Банк, Сбербанк, Дзен-мани, Wise, Revolut или ваш формат',
          'imports.how.1' =>
            'Показываем каждую строку так, как она попадёт в учёт',
          'imports.how.2' => 'Не задваиваем то, что вы уже записали вручную',
          'imports.how.3' =>
            'Импорт отменяется целиком, одной кнопкой, хоть через месяц',
          'imports.privacyTitle' => 'Без паролей от банка',
          'imports.privacyText' =>
            'Файл читается здесь, в браузере. Birka не входит в ваш банк и никуда не отправляет выписку.',
          'imports.whereTitle' => 'Где взять выписку',
          'imports.whereBank' => 'Интернет-банк',
          'imports.whereBankText' =>
            'Раздел выписки или истории операций, формат CSV или Excel за нужные месяцы',
          'imports.whereZen' => 'Дзен-мани',
          'imports.whereZenText' =>
            'Экспорт операций в CSV из веб-версии: все счета, категории и годы истории разом',
          'imports.whereAbroad' => 'Wise и Revolut',
          'imports.whereAbroadText' =>
            'Statement в CSV: у каждой операции останется своя валюта',
          'imports.pastTitle' => 'Прошлые импорты',
          'imports.pastName' =>
            ({required Object format, required Object period}) =>
                '${format} · ${period}',
          'imports.pastLine' =>
            ({
              required Object operations,
              required Object where,
              required Object day,
            }) => '${operations} → ${where} · ${day}',
          'imports.operations' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} операция',
                  few: '${count} операции',
                  many: '${count} операций',
                  other: '${count} операции',
                ),
          'imports.accounts' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} счёт',
                  few: '${count} счёта',
                  many: '${count} счетов',
                  other: '${count} счёта',
                ),
          'imports.undo' => 'Отменить',
          'imports.undoAsk' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'Убрать ${count} операцию этого файла?',
                  few: 'Убрать ${count} операции этого файла?',
                  many: 'Убрать ${count} операций этого файла?',
                  other: 'Убрать ${count} операции этого файла?',
                ),
          'imports.undoYes' => 'Убрать',
          'imports.undoNo' => 'Оставить',
          'imports.undone' =>
            ({required Object name}) => 'Импорт «${name}» отменён',
          'imports.looksLike' =>
            ({required Object bank}) => 'Похоже на выписку ${bank}',
          'imports.matched' =>
            ({
              required num n,
              required Object total,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one:
                  'Совпала ${n} колонка из ${total}. По ней Birka разберёт файл, а вы проверите результат на следующем шаге.',
              few:
                  'Совпали ${n} колонки из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
              many:
                  'Совпали ${n} колонок из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
              other:
                  'Совпали ${n} колонки из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
            ),
          'imports.notKnown' => 'Банк по колонкам не узнали',
          'imports.notKnownText' =>
            'Выберите его ниже или назначьте колонки сами на следующем шаге.',
          'imports.skipped' =>
            ({required Object header}) => '${header} — не берём',
          'imports.formatsTitle' => 'Формат выписки',
          'imports.formatTexts.alfa' => 'Операции одной карты или счёта',
          'imports.formatTexts.tbank' => 'Карты и счета, с категориями банка',
          'imports.formatTexts.sber' => 'PDF-выписка карты из СберБанк Онлайн',
          'imports.formatTexts.zenmoney' =>
            'Все счета, категории и переводы разом',
          'imports.formatTexts.wise' => 'У каждой операции своя валюта и курс',
          'imports.formatTexts.revolut' =>
            'У каждой операции своя валюта и комиссия',
          'imports.own' => 'Свой формат',
          'imports.ownTag' => 'любой',
          'imports.ownText' => 'Колонки назначите сами',
          'imports.fileKinds.csv' => 'CSV',
          'imports.fileKinds.xlsx' => 'Excel',
          'imports.fileKinds.pdf' => 'PDF',
          'imports.summaryTitle' => 'Что попадёт в учёт',
          'imports.summaryFormat' => 'Формат',
          'imports.summaryRows' => 'Строк в файле',
          'imports.summaryPeriod' => 'Период',
          'imports.summaryAccount' => 'Счёт',
          'imports.accountLater' => 'выберем на 4-м шаге',
          'imports.summaryOperations' => 'Операций',
          'imports.summarySpent' => 'Расходы',
          'imports.summaryReceived' => 'Поступления',
          'imports.summaryUnsorted' => 'Без категории',
          'imports.toInbox' =>
            ({required Object count}) => '${count} → во «Входящие»',
          'imports.summaryBalance' => 'Остаток после',
          'imports.summaryFromFile' => 'Из файла',
          'imports.summaryCopies' => 'Пропустим копий',
          'imports.summaryAdded' => 'Добавим',
          'imports.next.format' => 'Дальше: банк',
          'imports.next.columns' => 'Дальше: колонки',
          'imports.next.account' => 'Дальше: счёт',
          'imports.next.copies' => 'Дальше: дубликаты',
          'imports.write' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'Импортировать ${count} операцию',
                  few: 'Импортировать ${count} операции',
                  many: 'Импортировать ${count} операций',
                  other: 'Импортировать ${count} операции',
                ),
          'imports.nothingToWrite' => 'Нечего добавить',
          'imports.planning' => 'Считаем…',
          'imports.writing' =>
            ({required Object done, required Object total}) =>
                'Записываем: ${done} из ${total}',
          'imports.writeNote' =>
            'Весь импорт можно будет отменить одной кнопкой',
          'imports.columnsTitle' => 'Колонки файла',
          'imports.roles.date' => 'Дата',
          'imports.roles.amount' => 'Сумма',
          'imports.roles.expense' => 'Расход',
          'imports.roles.income' => 'Поступление',
          'imports.roles.fee' => 'Комиссия',
          'imports.roles.currency' => 'Валюта',
          'imports.roles.expenseCurrency' => 'Валюта расхода',
          'imports.roles.incomeCurrency' => 'Валюта поступления',
          'imports.roles.account' => 'Счёт',
          'imports.roles.expenseAccount' => 'Счёт расхода',
          'imports.roles.incomeAccount' => 'Счёт поступления',
          'imports.roles.description' => 'Описание',
          'imports.roles.note' => 'Заметка',
          'imports.roles.category' => 'Категория банка',
          'imports.roles.ownCategory' => 'Ваша категория',
          'imports.roles.card' => 'Карта',
          'imports.roles.balance' => 'Остаток',
          'imports.roles.status' => 'Статус',
          'imports.roles.skip' => 'Не брать',
          'imports.roleOf' =>
            ({required Object header}) => 'Что в колонке «${header}»',
          'imports.signTitle' => 'Расход в файле записан',
          'imports.signs.expenseNegative' => 'с минусом',
          'imports.signs.expensePositive' => 'с плюсом',
          'imports.signs.incomePlus' => 'без знака',
          'imports.markTitle' => 'Копейки отделены',
          'imports.marks.comma' => 'запятой',
          'imports.marks.dot' => 'точкой',
          'imports.datesTitle' => 'Даты',
          'imports.dateOrders.dayMonthYear' => 'ДД.ММ.ГГГГ',
          'imports.dateOrders.monthDayYear' => 'ММ.ДД.ГГГГ',
          'imports.missing' =>
            'Отметьте колонку даты и колонку суммы: без них строки не станут операциями.',
          'imports.previewTitle' => 'Так строки попадут в учёт',
          'imports.previewNote' =>
            ({required Object shown, required Object total}) =>
                'первые ${shown} из ${total} · заголовок и итог не считаем',
          'imports.previewDate' => 'Дата',
          'imports.previewText' => 'Описание',
          'imports.previewCategory' => 'Категория',
          'imports.previewAmount' => 'Сумма',
          'imports.transfer' => 'Перевод',
          'imports.learned' => 'как раньше',
          'imports.inbox' => 'Решу во «Входящих»',
          'imports.problems' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} строка не прочиталась',
                  few: '${count} строки не прочитались',
                  many: '${count} строк не прочитались',
                  other: '${count} строки не прочитались',
                ),
          'imports.problemLine' =>
            ({required Object line, required Object fault}) =>
                'Строка ${line}: ${fault}',
          'imports.andMore' => ({required Object count}) => 'и ещё ${count}',
          'imports.rowFaults.unreadableDate' => 'дата не читается',
          'imports.rowFaults.noSuchDay' => 'такого дня нет',
          'imports.rowFaults.noAmount' => 'нет суммы',
          'imports.rowFaults.unreadableAmount' => 'сумма не читается',
          'imports.rowFaults.zeroAmount' => 'сумма ноль',
          'imports.rowFaults.declined' => 'операция не прошла',
          'imports.categoriesTitle' => 'Категории банка → ваши',
          'imports.categoriesNote' =>
            'Без выбора операции подождут во «Входящих»',
          'imports.categoryKinds.expense' => 'расход',
          'imports.categoryKinds.income' => 'поступление',
          'imports.noBankCategory' => 'Без категории банка',
          'imports.newCategory' => ({required Object name}) => 'Новая: ${name}',
          'imports.fees' => 'Комиссии банка',
          'imports.categoryOf' =>
            ({required Object name}) => 'Категория для «${name}»',
          'imports.accountTitleCard' =>
            ({required Object card}) =>
                'Куда записать операции карты ••${card}',
          'imports.accountTitleNamed' =>
            ({required Object name}) => 'Куда записать операции «${name}»',
          'imports.accountTitle' => 'Куда записать операции',
          'imports.accountText' =>
            ({required Object operations}) =>
                '${operations}. Выберите счёт в Birka, заведите новый или не берите их.',
          'imports.cardMatched' => 'совпал номер карты',
          'imports.nameMatched' => 'совпало название',
          'imports.otherCurrency' =>
            ({required Object currency, required Object fileCurrency}) =>
                '${currency}, а в файле ${fileCurrency}',
          'imports.newAccount' => 'Новый счёт',
          'imports.newAccountText' =>
            ({required Object name, required Object balance}) =>
                'Заведём «${name}» с остатком ${balance}',
          'imports.leaveOut' => 'Не брать',
          'imports.leaveOutText' => 'Операции этого счёта не попадут в учёт',
          'imports.balanceMatches' => 'Остаток сойдётся с банком',
          'imports.balanceDiffers' => 'Остаток разойдётся с банком',
          'imports.balanceInFile' =>
            ({required Object day}) => 'В выписке на ${day}',
          'imports.balanceInBirka' => 'В Birka после импорта',
          'imports.balanceHint' =>
            'В учёте есть операции, которых нет в выписке, или их не хватает. Проверьте счёт и дубликаты.',
          'imports.copiesTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} операция уже есть в учёте',
                  few: '${count} операции уже есть в учёте',
                  many: '${count} операций уже есть в учёте',
                  other: '${count} операции уже есть в учёте',
                ),
          'imports.copiesText' =>
            'Похоже, вы записали их вручную. Копии из выписки пропустим, а ваши записи, с вашими названиями и категориями, останутся как есть.',
          'imports.noCopies' => 'Повторов нет',
          'imports.noCopiesText' =>
            'Ни одна операция выписки не похожа на то, что уже есть в учёте.',
          'imports.fromFile' => 'Из выписки',
          'imports.inLedger' => 'Уже в учёте',
          'imports.reasons.imported' => 'из этого же файла',
          'imports.reasons.sameAmount' => 'та же сумма',
          'imports.reasons.sameDay' => 'тот же день',
          'imports.reasons.dayBefore' => 'на день раньше',
          'imports.reasons.dayAfter' => 'на день позже',
          'imports.reasons.sameAccount' => 'тот же счёт',
          'imports.reasons.similarName' => 'похожее название',
          'imports.skipCopy' => 'Пропустить копию',
          'imports.keepBoth' => 'Оставить обе',
          'imports.leftTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} операция не попадёт в учёт',
                  few: '${count} операции не попадут в учёт',
                  many: '${count} операций не попадут в учёт',
                  other: '${count} операции не попадут в учёт',
                ),
          'imports.planFaults.otherCurrency' => 'у счёта другая валюта',
          'imports.planFaults.tooPrecise' => 'больше знаков, чем у валюты',
          'imports.planFaults.unevenTransfer' =>
            'перевод в одной валюте с двумя суммами',
          'imports.doneTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'Добавили ${count} операцию',
                  few: 'Добавили ${count} операции',
                  many: 'Добавили ${count} операций',
                  other: 'Добавили ${count} операции',
                ),
          'imports.doneWhere' =>
            ({
              required Object format,
              required Object period,
              required Object accounts,
            }) => '${format}, ${period} → ${accounts}',
          'imports.doneIncome' => 'Поступления',
          'imports.doneSpent' => 'Новые траты',
          'imports.doneSkipped' => 'Пропустили копий',
          'imports.doneBalance' => 'Остаток счёта',
          'imports.asInBank' => 'как в банке',
          'imports.unsortedTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} ждёт вашего решения во «Входящих»',
                  few: '${count} ждут вашего решения во «Входящих»',
                  many: '${count} ждут вашего решения во «Входящих»',
                  other: '${count} ждут вашего решения во «Входящих»',
                ),
          'imports.unsortedText' =>
            'В отчётах они уже есть, просто без категории.',
          'imports.sortInbox' => 'Разобрать «Входящие»',
          'imports.undoTitle' => 'Передумали?',
          'imports.undoText' =>
            ({
              required num n,
              required Object count,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              one:
                  'Отмена уберёт ${count} операцию этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
              few:
                  'Отмена уберёт ${count} операции этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
              many:
                  'Отмена уберёт ${count} операций этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
              other:
                  'Отмена уберёт ${count} операции этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
            ),
          'imports.undoImport' => 'Отменить импорт',
          'imports.undoneTitle' => 'Импорт отменён',
          'imports.undoneText' =>
            'Операции этого файла убраны из учёта. Ваши записи остались как были.',
          'imports.toOperations' => 'К операциям',
          'imports.another' => 'Загрузить ещё выписку',
          'imports.monthsWhole.0' => 'январь',
          'imports.monthsWhole.1' => 'февраль',
          'imports.monthsWhole.2' => 'март',
          'imports.monthsWhole.3' => 'апрель',
          'imports.monthsWhole.4' => 'май',
          'imports.monthsWhole.5' => 'июнь',
          'imports.monthsWhole.6' => 'июль',
          'imports.monthsWhole.7' => 'август',
          'imports.monthsWhole.8' => 'сентябрь',
          'imports.monthsWhole.9' => 'октябрь',
          'imports.monthsWhole.10' => 'ноябрь',
          'imports.monthsWhole.11' => 'декабрь',
          'imports.periodMonth' =>
            ({required Object month, required Object year}) =>
                '${month} ${year}',
          'imports.periodInMonth' =>
            ({
              required Object from,
              required Object to,
              required Object month,
              required Object year,
            }) => '${from}–${to} ${month} ${year}',
          'imports.periodInYear' =>
            ({
              required Object from,
              required Object to,
              required Object year,
            }) => '${from} – ${to} ${year}',
          'imports.periodFar' =>
            ({required Object from, required Object to}) => '${from} – ${to}',
          'imports.cancel' => 'Отмена',
          'imports.finish' => 'Готово',
          'imports.readingTitle' => 'Читаем выписку',
          'imports.readingNote' =>
            'Файл читается на телефоне и никуда не уходит',
          'imports.knownBy' =>
            ({required Object bank}) => '${bank} · узнали по колонкам',
          'imports.operationsIn' =>
            ({required Object period}) => 'Операций за ${period}',
          'imports.alreadyIn' => 'Уже есть в учёте',
          'imports.willSkip' =>
            ({required Object count}) => '${count}, пропустим',
          'imports.sortLater' => 'Разобрать потом',
          'imports.inInbox' =>
            ({required Object count}) => '${count} во «Входящих»',
          'imports.unknownTitle' => 'Формат не узнали',
          'imports.columnsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} колонка',
                  few: '${count} колонки',
                  many: '${count} колонок',
                  other: '${count} колонки',
                ),
          'imports.rowsCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} строка',
                  few: '${count} строки',
                  many: '${count} строк',
                  other: '${count} строки',
                ),
          'imports.unknownText' =>
            'Назначьте колонки этого файла, где дата и где сумма. Остальное Birka прочитает сама.',
          'imports.chooseAnother' => 'Выбрать другой файл',
          'imports.assignColumns' => 'Назначить колонки',
          'imports.columnsHeading' => 'Колонки выписки',
          'imports.columnsText' =>
            'Отметьте, где в файле дата и где сумма, и строки станут операциями.',
          'imports.roleNotes.date' => 'день операции',
          'imports.roleNotes.amount' => 'расход и поступление в одной колонке',
          'imports.roleNotes.expense' => 'только списания',
          'imports.roleNotes.income' => 'только зачисления',
          'imports.roleNotes.currency' => 'RUB, USD, EUR…',
          'imports.roleNotes.description' =>
            'магазин, получатель или назначение',
          'imports.roleNotes.category' => 'разберём во «Входящих»',
          'imports.roleNotes.balance' => 'сверим с банком',
          'imports.roleNotes.skip' => 'колонку пропустим',
          'imports.noAmounts' =>
            'Ни одна сумма не прочиталась. Проверьте, чем в файле отделены копейки.',
          'imports.columnsDone' =>
            ({required Object operations}) => 'Готово · ${operations}',
          'imports.ownColumns' => 'колонки назначили вы',
          'imports.looksLikeOwn' => 'Узнали ваш формат',
          'imports.categoriesHeading' => 'Категории банка',
          'imports.categoriesCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} категория в выписке',
                  few: '${count} категории в выписке',
                  many: '${count} категорий в выписке',
                  other: '${count} категории в выписке',
                ),
          'imports.categoriesKnown' =>
            ({required Object known, required Object total}) =>
                '${known} из ${total} узнали сами',
          'imports.categoriesNone' => 'Birka их пока не знает',
          'imports.categoriesAsBefore' => 'Как в прошлой выписке',
          'imports.categoriesKnownText' =>
            ({required Object known, required Object total}) =>
                '${known} из ${total} узнали по названиям. Операции сразу встанут в ваши категории, а без выбора подождут во «Входящих».',
          'imports.categoriesText' =>
            'Выберите, куда записать операции каждой категории банка. Без выбора они подождут во «Входящих».',
          'imports.categoriesAsBeforeText' =>
            ({required Object source}) =>
                'Взяли ваш выбор с прошлой выписки ${source}. Поменяйте, если что-то теперь иначе.',
          'imports.ownFormatOf' => 'вашего формата',
          'imports.inboxNote' => 'операции подождут без категории',
          'imports.newCategoryNote' => 'появится при импорте',
          'imports.newCategoryMark' => 'новая категория',
          _ => null,
        } ??
        switch (path) {
          'imports.categoriesDone' =>
            ({required Object count}) => 'Готово · ${count} во «Входящих»',
          'imports.categoriesKept' =>
            ({required Object source}) =>
                'Выбор запомним для выписок ${source}',
          'imports.rowsLeft' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} строка не попадёт в учёт',
                  few: '${count} строки не попадут в учёт',
                  many: '${count} строк не попадут в учёт',
                  other: '${count} строки не попадут в учёт',
                ),
          'imports.unreadCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} не прочиталась',
                  few: '${count} не прочитались',
                  many: '${count} не прочитались',
                  other: '${count} не прочитались',
                ),
          'imports.declinedCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} не прошла в банке',
                  few: '${count} не прошли в банке',
                  many: '${count} не прошли в банке',
                  other: '${count} не прошли в банке',
                ),
          'imports.unfitCount' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} не подходит счёту',
                  few: '${count} не подходят счёту',
                  many: '${count} не подходят счёту',
                  other: '${count} не подходят счёту',
                ),
          'imports.restFine' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'ещё ${count} в порядке',
                  few: 'остальные ${count} в порядке',
                  many: 'остальные ${count} в порядке',
                  other: 'остальные ${count} в порядке',
                ),
          'imports.unreadTitle' => 'Не прочитали',
          'imports.declinedTitle' => 'Не прошли в банке',
          'imports.unfitTitle' => 'Не подходят счёту',
          'imports.rowLine' =>
            ({required Object line, required Object what}) =>
                'Строка ${line} · ${what}',
          'imports.leftNote' =>
            'Непрочитанные запишите вручную или скачайте выписку заново: Birka добавит только то, чего ещё нет в учёте.',
          'imports.understood' => 'Понятно',
          'imports.bankHas' =>
            ({required Object amount}) => 'В банке ${amount}',
          'imports.bankHasMissing' =>
            ({required Object amount}) =>
                'В банке ${amount}: похоже, не хватает непрочитанных строк',
          'imports.mostUnread' =>
            ({required num n, required Object count, required Object total}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} строка из ${total} не прочиталась',
                  few: '${count} строки из ${total} не прочитались',
                  many: '${count} строк из ${total} не прочитались',
                  other: '${count} строки из ${total} не прочитались',
                ),
          'imports.mostUnreadText' =>
            'Похоже, банк поменял выписку: проверьте, где в ней дата и сумма и чем отделены копейки.',
          'imports.checkColumns' => 'Проверить колонки',
          'imports.declinedRows' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} операция не прошла в банке',
                  few: '${count} операции не прошли в банке',
                  many: '${count} операций не прошли в банке',
                  other: '${count} операции не прошли в банке',
                ),
          'inbox.title' => 'Входящие',
          'inbox.back' => 'Назад',
          'inbox.waiting' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} ждёт решения',
                  few: '${count} ждут решения',
                  many: '${count} ждут решения',
                  other: '${count} ждут решения',
                ),
          'inbox.afterImport' =>
            ({required Object bank}) => 'после импорта ${bank}',
          'inbox.afterFile' =>
            ({required Object name}) => 'после импорта «${name}»',
          'inbox.filters.all' => 'Все',
          'inbox.filters.uncategorized' => 'Без категории',
          'inbox.filters.transfers' => 'Переводы',
          'inbox.filtersLabel' => 'Что показать',
          'inbox.emptyTitle' => 'Всё разобрано',
          'inbox.emptyText' =>
            'Здесь появятся операции без категории и переводы между вашими счетами, когда придут из выписки.',
          'inbox.pairTitle' => 'Похоже на перевод между вашими счетами',
          'inbox.pairText' =>
            'Не трата и не доход: капитал от него не изменится',
          'inbox.rate' =>
            ({required Object rate, required Object unit}) =>
                'Курс обмена ${rate} за ${unit}',
          'inbox.bankRate' =>
            ({required Object rate}) => 'ЦБ в тот день ${rate}',
          'inbox.makeTransfer' => 'Сделать переводом',
          'inbox.notTransfer' => 'Это доход',
          'inbox.fromStatement' => 'из выписки',
          'inbox.uncategorized' => 'Без категории',
          'inbox.section' =>
            ({required Object title, required Object count}) =>
                '${title} · ${count}',
          'inbox.category' => 'Категория',
          'inbox.other' => 'Другая',
          'inbox.yes' => 'Да',
          'inbox.categoryFor' =>
            ({required Object name}) => 'Категория для «${name}»',
          'inbox.sameName' =>
            ({required num n, required Object count, required Object when}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'так вы отметили его ${count} раз ${when}',
                  few: 'так вы отметили его ${count} раза ${when}',
                  many: 'так вы отметили его ${count} раз ${when}',
                  other: 'так вы отметили его ${count} раза ${when}',
                ),
          'inbox.everyMonth' =>
            ({required Object since}) => 'та же сумма каждый месяц ${since}',
          'inbox.sameImport' =>
            ({required Object name}) => 'как «${name}» в этой выписке',
          'inbox.similarName' =>
            ({required Object name, required Object when}) =>
                'как «${name}» ${when}',
          'inbox.since' => ({required Object month}) => 'с ${month}',
          'inbox.more' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'и ещё ${count} операция',
                  few: 'и ещё ${count} операции',
                  many: 'и ещё ${count} операций',
                  other: 'и ещё ${count} операции',
                ),
          'inbox.picked' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'Выбрана ${count} операция',
                  few: 'Выбраны ${count} операции',
                  many: 'Выбрано ${count} операций',
                  other: 'Выбрано ${count} операции',
                ),
          'inbox.pickedCategory' => 'Категория для выбранных',
          'inbox.pickAll' => 'Выбрать все',
          'inbox.pickNone' => 'Снять выбор',
          'inbox.pick' => ({required Object name}) => 'Выбрать «${name}»',
          'inbox.sourceTitle' => 'Откуда подсказки',
          'inbox.sourceText' =>
            'Из ваших прошлых решений: как вы уже называли эти места и какие категории им давали. Считается здесь, на устройстве.',
          'inbox.learns' =>
            'Каждое «Да» учит Birka: в следующей выписке такие операции придут уже с категорией.',
          'inbox.stillCounted' =>
            'Пока операция здесь, она уже есть в учёте и в отчётах, просто без категории.',
          'inbox.failed' => 'Не получилось. Попробуйте ещё раз.',
          'inbox.madeTransfer' => 'Сделали перевод',
          'inbox.accepted' =>
            ({required Object category}) =>
                '${category}: дальше Birka поставит сама',
          'inbox.sorted' =>
            ({required Object category, required Object operations}) =>
                '${category} · ${operations}',
          'inbox.keptIncome' => 'Оставили доходом',
          'inbox.toImport' => 'Загрузить выписку',
          'inbox.hinted' => 'подсказка',
          'inbox.newCategory' => 'Новая категория',
          'inbox.entryTitle' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} ждёт решения во «Входящих»',
                  few: '${count} ждут решения во «Входящих»',
                  many: '${count} ждут решения во «Входящих»',
                  other: '${count} ждут решения во «Входящих»',
                ),
          'inbox.entryUncategorized' =>
            ({required Object count}) => '${count} без категории',
          'inbox.entryTransfer' =>
            ({required Object account}) => 'перевод со счёта «${account}»',
          'inbox.entryTransfers' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${count} перевод между счетами',
                  few: '${count} перевода между счетами',
                  many: '${count} переводов между счетами',
                  other: '${count} перевода между счетами',
                ),
          'inbox.entryBoth' =>
            ({required Object first, required Object second}) =>
                '${first} и ${second}',
          'inbox.unpick' => 'Снять',
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
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${n} категория',
                  few: '${n} категории',
                  many: '${n} категорий',
                  other: '${n} категории',
                ),
          'onboarding.categories.finish' => 'Готово',
          'overview.capital' => 'Капитал',
          'overview.rateOn' =>
            ({required Object day}) => 'Курс ЦБ РФ на ${day}',
          'overview.currencies' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
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
          'overview.spendingIn' =>
            ({required Object month}) => 'Траты ${month}',
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
          'reports.average' =>
            ({required Object amount}) => 'в среднем ${amount}',
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
          'schedules.title' => 'Регулярные платежи',
          'schedules.back' => 'Назад',
          'schedules.add' => 'Новый платёж',
          'schedules.close' => 'Закрыть',
          'schedules.waitingTitle' => 'Ждёт подтверждения',
          'schedules.post' => 'Провести',
          'schedules.skip' => 'Пропустить',
          'schedules.waitingNote' =>
            'Придёт в выписке банка — Birka не задвоит его.',
          'schedules.waitingDay' =>
            ({required Object name, required Object day}) => '${name} · ${day}',
          'schedules.ahead' => 'Ближайшие 30 дней',
          'schedules.aheadTotal' =>
            ({required Object date, required Object amount}) =>
                'до ${date} ${amount}',
          'schedules.leftAfterPayday' =>
            ({required Object date, required Object amount}) =>
                'К зарплате ${date} на счетах останется ≈ ${amount}, если не считать ежедневных трат.',
          'schedules.leftAfterMonth' =>
            ({required Object amount}) =>
                'К концу месяца на счетах останется ≈ ${amount}, если не считать ежедневных трат.',
          'schedules.section' =>
            ({required Object title, required Object count}) =>
                '${title} · ${count}',
          'schedules.all' => 'Все регулярные',
          'schedules.emptyTitle' => 'Регулярных платежей пока нет',
          'schedules.emptyText' =>
            'Аренда, подписки, зарплата: добавьте их один раз, и Birka покажет месяц вперёд и сколько можно тратить в день.',
          'schedules.emptyAdd' => 'Добавить платёж',
          'schedules.everyMonth' =>
            ({required Object day}) => 'каждый месяц ${day}-го',
          'schedules.everyWeek' =>
            ({required Object weekday}) => 'каждую неделю, ${weekday}',
          'schedules.everyYear' =>
            ({required Object date}) => 'раз в год, ${date}',
          'schedules.asks' => 'спросить',
          'schedules.posts' => 'проводится сам',
          'schedules.today' => 'сегодня',
          'schedules.tomorrow' => 'завтра',
          'schedules.posted' =>
            ({required Object name, required Object amount}) =>
                'Провели «${name}» · ${amount}',
          'schedules.skippedAsk' =>
            ({required Object name, required Object date}) =>
                'Пропустили «${name}» · спросим ${date}',
          'schedules.skippedPost' =>
            ({required Object name, required Object date}) =>
                'Пропустили «${name}» · следующий раз ${date}',
          'schedules.deleted' =>
            ({required Object name}) => 'Удалили «${name}»',
          'schedules.found' =>
            ({required Object name}) => 'Нашли «${name}» в выписке',
          'schedules.foundOf' =>
            ({required Object name, required Object bank}) =>
                'Нашли «${name}» в выписке ${bank}',
          'schedules.foundText' =>
            ({required Object date, required Object amount}) =>
                '${date} · ${amount} · отметили платёж проведённым, копии не будет',
          'schedules.donePosted' =>
            ({required Object date}) => 'проведён сегодня · следующий ${date}',
          'schedules.doneSkipped' =>
            ({required Object date}) => 'пропущен · следующий ${date}',
          'schedules.doneFound' =>
            ({required Object date}) => 'нашли в выписке · следующий ${date}',
          'schedules.on.mon' => 'по понедельникам',
          'schedules.on.tue' => 'по вторникам',
          'schedules.on.wed' => 'по средам',
          'schedules.on.thu' => 'по четвергам',
          'schedules.on.fri' => 'по пятницам',
          'schedules.on.sat' => 'по субботам',
          'schedules.on.sun' => 'по воскресеньям',
          'schedules.weekday.mon' => 'пн',
          'schedules.weekday.tue' => 'вт',
          'schedules.weekday.wed' => 'ср',
          'schedules.weekday.thu' => 'чт',
          'schedules.weekday.fri' => 'пт',
          'schedules.weekday.sat' => 'сб',
          'schedules.weekday.sun' => 'вс',
          'schedules.newTitle' => 'Новый платёж',
          'schedules.kinds.expense' => 'Расход',
          'schedules.kinds.income' => 'Поступление',
          'schedules.kinds.transfer' => 'Перевод',
          'schedules.kindLabel' => 'Что за платёж',
          'schedules.amount' => 'Сумма',
          'schedules.name' => 'Название',
          'schedules.namePlaceholder' => 'Например, Аренда',
          'schedules.category' => 'Категория',
          'schedules.noCategory' => 'Без категории',
          'schedules.categoryLater' => 'решу во «Входящих»',
          'schedules.account' => 'Счёт',
          'schedules.toAccount' => 'Куда',
          'schedules.fromAccount' => 'Откуда',
          'schedules.incomeAccount' => 'На счёт',
          'schedules.pickAccount' => 'Выберите счёт',
          'schedules.every' => 'Повторять каждый',
          'schedules.everyOptions.month' => 'Месяц',
          'schedules.everyOptions.week' => 'Неделю',
          'schedules.everyOptions.year' => 'Год',
          'schedules.dayOfMonth' => 'Какого числа',
          'schedules.dayOfWeek' => 'Какой день недели',
          'schedules.dayOfYear' => 'Какого дня',
          'schedules.dayNumber' => ({required Object day}) => '${day}-го',
          'schedules.next' => 'Следующий раз',
          'schedules.onDayTitle' => 'В день платежа',
          'schedules.onDay.ask' => 'Спросить меня',
          'schedules.onDay.post' => 'Провести само',
          'schedules.askNote' =>
            'Подойдёт, если сумма меняется, как у ЖКХ: в этот день платёж подождёт вашего «Провести».',
          'schedules.postNote' =>
            'Для подписок с одной суммой. Придёт в выписке банка — копии не будет.',
          'schedules.save' => 'Сохранить',
          'schedules.saveNote' =>
            'Появится в «Ближайших платежах» и в «Можно тратить сегодня»',
          'schedules.changeNote' =>
            ({required Object date}) => 'Изменится со следующего раза: ${date}',
          'schedules.done' => 'Готово',
          'schedules.delete' => 'Удалить платёж',
          'schedules.deleteNote' => 'Прошлые операции останутся',
          'schedules.deleteTitle' =>
            ({required Object name}) => 'Удалить «${name}»?',
          'schedules.canSpend' => 'Можно тратить сегодня',
          'schedules.overToday' => 'Сегодня больше дневного',
          'schedules.ofPerDay' =>
            ({required Object amount}) => 'из ${amount} на день',
          'schedules.spentUntilPayday' =>
            ({required Object amount, required Object days}) =>
                'Потратили ${amount} · до зарплаты ${days}',
          'schedules.spentUntilMonth' =>
            ({required Object amount, required Object days}) =>
                'Потратили ${amount} · до конца месяца ${days}',
          'schedules.spentOver' =>
            ({required Object amount, required Object tomorrow}) =>
                'Потратили ${amount} · завтра можно ${tomorrow} в день',
          'schedules.short' =>
            ({required Object amount, required Object date}) =>
                'Не хватает ${amount} до ${date}',
          'schedules.upcoming' => 'Ближайшие платежи',
          'schedules.noPaydayLabel' => 'До зарплаты',
          'schedules.noPaydayTitle' => 'Сколько можно тратить в день?',
          'schedules.noPaydayText' =>
            'Укажите день зарплаты. Birka вычтет регулярные платежи до него и разделит остаток на дни.',
          'schedules.noPaydayAction' => 'Указать день зарплаты',
          'schedules.days' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${n} день',
                  few: '${n} дня',
                  many: '${n} дней',
                  other: '${n} дней',
                ),
          'schedules.paydayTitle' => 'Деньги до зарплаты',
          'schedules.perDay' =>
            ({required Object amount}) => '${amount} в день',
          'schedules.notEnough' =>
            ({required Object amount}) => 'Не хватает ${amount}',
          'schedules.untilPayday' =>
            ({required Object date, required Object days}) =>
                'до зарплаты ${date} · ${days}',
          'schedules.untilDate' =>
            ({required Object date, required Object days}) =>
                'до ${date} · ${days}',
          'schedules.morning' => 'Утром на счетах',
          'schedules.paymentsUntilPayday' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${n} платёж до зарплаты',
                  few: '${n} платежа до зарплаты',
                  many: '${n} платежей до зарплаты',
                  other: '${n} платежей до зарплаты',
                ),
          'schedules.paymentsUntilMonth' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: '${n} платёж до конца месяца',
                  few: '${n} платежа до конца месяца',
                  many: '${n} платежей до конца месяца',
                  other: '${n} платежей до конца месяца',
                ),
          'schedules.aside' => 'Отложить',
          'schedules.leftFor' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  one: 'Остаётся на ${n} день',
                  few: 'Остаётся на ${n} дня',
                  many: 'Остаётся на ${n} дней',
                  other: 'Остаётся на ${n} дней',
                ),
          'schedules.countUntil' => 'Считать до',
          'schedules.until.payday' => 'Дня зарплаты',
          'schedules.until.monthEnd' => 'Конца месяца',
          'schedules.payday' => 'День зарплаты',
          'schedules.paydayFrom' =>
            ({required Object name}) => 'из платежа «${name}»',
          'schedules.paydayNone' => 'добавьте регулярное поступление',
          'schedules.paydayDay' => ({required Object day}) => '${day}-е число',
          'schedules.accountsTitle' => 'Какие счета считать',
          'schedules.count' => ({required Object name}) => 'Считать «${name}»',
          'schedules.otherCurrency' => 'другая валюта, пока не считаем',
          'schedules.asideRow' => 'Отложить до зарплаты',
          'schedules.asideNote' => 'не тратим, даже если «можно»',
          'schedules.salaryName' => 'Зарплата',
          'schedules.monthsShort.0' => 'янв',
          'schedules.monthsShort.1' => 'фев',
          'schedules.monthsShort.2' => 'мар',
          'schedules.monthsShort.3' => 'апр',
          'schedules.monthsShort.4' => 'мая',
          'schedules.monthsShort.5' => 'июн',
          'schedules.monthsShort.6' => 'июл',
          'schedules.monthsShort.7' => 'авг',
          'schedules.monthsShort.8' => 'сен',
          'schedules.monthsShort.9' => 'окт',
          'schedules.monthsShort.10' => 'ноя',
          'schedules.monthsShort.11' => 'дек',
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
          'transactions.failedToRead' =>
            'Не удалось прочитать счета и категории.',
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
          'transactions.noAccountOperations' =>
            'По этому счёту операций пока нет.',
          'transactions.balanceChart' => 'Остаток за период',
          'transactions.accountGone' => 'Этого счёта больше нет.',
          'transactions.noOperationsHint' =>
            'Нажмите плюс, чтобы записать первую.',
          'transactions.nothingFound' => 'Ничего не нашлось',
          'transactions.failedToReadOperations' =>
            'Не удалось прочитать операции.',
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
