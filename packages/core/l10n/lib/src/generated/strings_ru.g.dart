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
  late final _Translations$ask$ru ask = _Translations$ask$ru._(_root);
  @override
  late final _Translations$backup$ru backup = _Translations$backup$ru._(_root);
  @override
  late final _Translations$categories$ru categories =
      _Translations$categories$ru._(_root);
  @override
  late final _Translations$debts$ru debts = _Translations$debts$ru._(_root);
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
  late final _Translations$notifications$ru notifications =
      _Translations$notifications$ru._(_root);
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
  late final _Translations$tags$ru tags = _Translations$tags$ru._(_root);
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
        zero: 'в ${n} счетах',
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

// Path: ask
class _Translations$ask$ru extends Translations$ask$en {
  _Translations$ask$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Спросить';
  @override
  String get open => 'Спросить';
  @override
  String get hint => 'Спросите про деньги';
  @override
  String get clear => 'Стереть вопрос';
  @override
  String get back => 'Назад';
  @override
  String get examples => 'Можно спросить';
  @override
  String get recent => 'Недавние';
  @override
  String get forget => 'Очистить';
  @override
  String get private =>
      'Отвечает само приложение: вопросы и ответы остаются на этом устройстве.';
  @override
  String get failed => 'Не удалось прочитать данные для ответа.';
  @override
  String get privateWeb =>
      'Отвечает само приложение: вопросы и ответы остаются в этом браузере.';
  @override
  String get slash => 'Клавиша / открывает «Спросить» с любой страницы.';
  @override
  late final _Translations$ask$start$ru start = _Translations$ask$start$ru._(
    _root,
  );
  @override
  late final _Translations$ask$example$ru example =
      _Translations$ask$example$ru._(_root);
  @override
  String get understood => 'Понял так';
  @override
  late final _Translations$ask$side$ru side = _Translations$ask$side$ru._(
    _root,
  );
  @override
  String above({required Object amount}) => 'Больше ${amount}';
  @override
  String below({required Object amount}) => 'Меньше ${amount}';
  @override
  String word({required Object word}) => '«${word}»';
  @override
  String get allTime => 'За всё время';
  @override
  late final _Translations$ask$answer$ru answer = _Translations$ask$answer$ru._(
    _root,
  );
  @override
  late final _Translations$ask$before$ru before = _Translations$ask$before$ru._(
    _root,
  );
  @override
  late final _Translations$ask$period$ru period = _Translations$ask$period$ru._(
    _root,
  );
  @override
  late final _Translations$ask$fact$ru fact = _Translations$ask$fact$ru._(
    _root,
  );
  @override
  late final _Translations$ask$help$ru help = _Translations$ask$help$ru._(
    _root,
  );
  @override
  late final _Translations$ask$places$ru places = _Translations$ask$places$ru._(
    _root,
  );
  @override
  late final _Translations$ask$refused$ru refused =
      _Translations$ask$refused$ru._(_root);
  @override
  late final _Translations$ask$suggest$ru suggest =
      _Translations$ask$suggest$ru._(_root);
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
        zero: '${count} операций',
        one: '${count} операция',
        few: '${count} операции',
        many: '${count} операций',
        other: '${count} операции',
      );
  @override
  String accountsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} счетов',
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
        zero: '${n} подкатегорий',
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
  @override
  String get howTitle => 'Как это устроено';
  @override
  List<String> get how => [
    'Нажмите категорию — она откроется здесь, рядом со списком.',
    'Расходы и доходы — отдельные списки: переключатель над ними.',
    'Категории видны в операциях, отчётах и регулярных платежах.',
  ];
}

// Path: debts
class _Translations$debts$ru extends Translations$debts$en {
  _Translations$debts$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Долги';
  @override
  String get toMore => 'Ещё';
  @override
  String get close => 'Закрыть';
  @override
  String get done => 'Готово';
  @override
  String get foldClosed => 'Показать закрытые';
  @override
  String get moreHint => 'Кто кому должен и до какого дня';
  @override
  String moreBoth({required Object owed, required Object mine}) =>
      'Мне должны ${owed} · мои ${mine}';
  @override
  String moreOwed({required Object owed}) => 'Мне должны ${owed}';
  @override
  String moreMine({required Object mine}) => 'Мои долги ${mine}';
  @override
  String get owedToMe => 'Мне должны';
  @override
  String get myDebts => 'Мои долги';
  @override
  String people({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} человек',
        one: '${n} человек',
        few: '${n} человека',
        many: '${n} человек',
        other: '${n} человека',
      );
  @override
  String closed({required Object n}) => 'Закрытые · ${n}';
  @override
  String get caption =>
      'Долги не входят в капитал: этих денег сейчас нет на ваших счетах.';
  @override
  String get captionRates =>
      'Долги не входят в капитал: этих денег сейчас нет на ваших счетах. Другие валюты — по курсу ЦБ на сегодня.';
  @override
  String get failed => 'Не удалось прочитать долги.';
  @override
  String get gone => 'Этого долга больше нет.';
  @override
  String get emptyTitle => 'Долгов нет';
  @override
  String get emptyText =>
      'Запишите, кому одолжили или у кого заняли: Birka покажет, сколько осталось и до какого дня.';
  @override
  String get add => 'Записать долг';
  @override
  String get newDebt => 'Новый долг';
  @override
  late final _Translations$debts$line$ru line = _Translations$debts$line$ru._(
    _root,
  );
  @override
  late final _Translations$debts$card$ru card = _Translations$debts$card$ru._(
    _root,
  );
  @override
  String inDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'через ${n} дней',
        one: 'через ${n} день',
        few: 'через ${n} дня',
        many: 'через ${n} дней',
        other: 'через ${n} дня',
      );
  @override
  late final _Translations$debts$form$ru form = _Translations$debts$form$ru._(
    _root,
  );
  @override
  late final _Translations$debts$back$ru back = _Translations$debts$back$ru._(
    _root,
  );
  @override
  late final _Translations$debts$steps$ru steps =
      _Translations$debts$steps$ru._(_root);
  @override
  String get howItWorks => 'Как это устроено';
  @override
  late final _Translations$debts$move$ru move = _Translations$debts$move$ru._(
    _root,
  );
  @override
  late final _Translations$debts$person$ru person =
      _Translations$debts$person$ru._(_root);
  @override
  late final _Translations$debts$remind$ru remind =
      _Translations$debts$remind$ru._(_root);
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
  @override
  late final _Translations$demo$people$ru people =
      _Translations$demo$people$ru._(_root);
  @override
  late final _Translations$demo$debtNotes$ru debtNotes =
      _Translations$demo$debtNotes$ru._(_root);
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
        zero: '${count} операций',
        one: '${count} операция',
        few: '${count} операции',
        many: '${count} операций',
        other: '${count} операции',
      );
  @override
  String accounts({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} счетов',
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
        zero: 'Убрать ${count} операций этого файла?',
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
    zero:
        'Совпали ${n} колонок из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
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
        zero: 'Импортировать ${count} операций',
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
        zero: '${count} строк не прочитались',
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
        zero: '${count} операций уже есть в учёте',
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
        zero: '${count} операций не попадут в учёт',
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
        zero: 'Добавили ${count} операций',
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
        zero: '${count} ждут вашего решения во «Входящих»',
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
    zero:
        'Отмена уберёт ${count} операций этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
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
        zero: '${count} колонок',
        one: '${count} колонка',
        few: '${count} колонки',
        many: '${count} колонок',
        other: '${count} колонки',
      );
  @override
  String rowsCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} строк',
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
        zero: '${count} категорий в выписке',
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
  String get foundHeading => 'Регулярные платежи';
  @override
  String foundLine({required Object count, required Object names}) =>
      'нашли ${count}: ${names}';
  @override
  String foundDone({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Провели ${count} платежей',
        one: 'Провели ${count} платёж',
        few: 'Провели ${count} платежа',
        many: 'Провели ${count} платежей',
        other: 'Провели ${count} платежа',
      );
  @override
  String foundDoneText({required Object names}) => '${names} — из выписки';
  @override
  String repeatsTitle({required Object count}) =>
      'Похоже на регулярные · ${count}';
  @override
  String namesAnd({required Object names, required Object last}) =>
      '${names} и ${last}';
  @override
  String rowsLeft({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} строк не попадут в учёт',
        one: '${count} строка не попадёт в учёт',
        few: '${count} строки не попадут в учёт',
        many: '${count} строк не попадут в учёт',
        other: '${count} строки не попадут в учёт',
      );
  @override
  String unreadCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} не прочитались',
        one: '${count} не прочиталась',
        few: '${count} не прочитались',
        many: '${count} не прочитались',
        other: '${count} не прочитались',
      );
  @override
  String declinedCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} не прошли в банке',
        one: '${count} не прошла в банке',
        few: '${count} не прошли в банке',
        many: '${count} не прошли в банке',
        other: '${count} не прошли в банке',
      );
  @override
  String unfitCount({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} не подходят счёту',
        one: '${count} не подходит счёту',
        few: '${count} не подходят счёту',
        many: '${count} не подходят счёту',
        other: '${count} не подходят счёту',
      );
  @override
  String restFine({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'остальные ${count} в порядке',
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
    zero: '${count} строк из ${total} не прочитались',
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
        zero: '${count} операций не прошли в банке',
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
        zero: '${count} ждут решения',
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
    zero: 'так вы отметили его ${count} раз ${when}',
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
        zero: 'и ещё ${count} операций',
        one: 'и ещё ${count} операция',
        few: 'и ещё ${count} операции',
        many: 'и ещё ${count} операций',
        other: 'и ещё ${count} операции',
      );
  @override
  String picked({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Выбрано ${count} операций',
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
        zero: '${count} ждут решения во «Входящих»',
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
        zero: '${count} переводов между счетами',
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

// Path: notifications
class _Translations$notifications$ru extends Translations$notifications$en {
  _Translations$notifications$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Уведомления';
  @override
  String get back => 'Назад';
  @override
  String get bell => 'Уведомления';
  @override
  String bellNew({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Уведомления, ${count} новых',
        one: 'Уведомления, ${count} новое',
        few: 'Уведомления, ${count} новых',
        many: 'Уведомления, ${count} новых',
        other: 'Уведомления, ${count} нового',
      );
  @override
  String fresh({required Object count}) => 'Новые · ${count}';
  @override
  String get readAll => 'Прочитать все';
  @override
  String subtitleNew({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${count} новых · история за 90 дней',
        one: '${count} новое · история за 90 дней',
        few: '${count} новых · история за 90 дней',
        many: '${count} новых · история за 90 дней',
        other: '${count} нового · история за 90 дней',
      );
  @override
  String get subtitleRead => 'Всё прочитано · история за 90 дней';
  @override
  Map<String, String> get filters => {
    'all': 'Все',
    'payment': 'Платежи',
    'debt': 'Долги',
    'import': 'Импорт',
  };
  @override
  String get filtersLabel => 'Чьи уведомления';
  @override
  String get emptyTitle => 'Пока тихо';
  @override
  String get emptyText =>
      'Здесь появятся напоминания о платежах и сроках долгов и итоги импорта.';
  @override
  String get emptyImports => 'Здесь появятся итоги импорта выписок.';
  @override
  String get failed => 'Не удалось прочитать уведомления.';
  @override
  String get keeps => 'Birka хранит уведомления 90 дней';
  @override
  String get yesterday => 'вчера';
  @override
  String tomorrow({required Object date}) => 'Завтра, ${date}';
  @override
  String get waitsToday => 'Сегодня, ждёт подтверждения';
  @override
  String get waits => 'Ждёт подтверждения';
  @override
  String get postsToday => 'Сегодня, проведётся сам';
  @override
  String get posts => 'Проведётся сам';
  @override
  String posted({required Object time}) => 'Провели в ${time}';
  @override
  String postedOn({required Object date}) => 'Провели ${date}';
  @override
  String get postedItself => 'Провёлся сам';
  @override
  String skipped({required Object date}) => 'Пропустили · следующий ${date}';
  @override
  String get found => 'Нашли в выписке';
  @override
  String importTitle({required Object bank, required Object period}) =>
      '${bank} · ${period}';
  @override
  String importWaiting({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} из ${count} ждут во «Входящих»',
        one: '${n} из ${count} ждёт во «Входящих»',
        few: '${n} из ${count} ждут во «Входящих»',
        many: '${n} из ${count} ждут во «Входящих»',
        other: '${n} из ${count} ждут во «Входящих»',
      );
  @override
  String importAdded({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Добавили ${count} операций',
        one: 'Добавили ${count} операцию',
        few: 'Добавили ${count} операции',
        many: 'Добавили ${count} операций',
        other: 'Добавили ${count} операции',
      );
  @override
  String get importUndone => 'Импорт отменён';
  @override
  String debtTitle({required Object name, required Object amount}) =>
      'Срок · ${name}, ${amount}';
  @override
  String debtTitleToday({required Object name, required Object amount}) =>
      'Срок сегодня · ${name}, ${amount}';
  @override
  String debtSince({required Object date}) => 'с ${date}';
  @override
  String debtNoteSince({required Object note, required Object date}) =>
      '${note} · с ${date}';
  @override
  String debtReturned({required Object date}) => 'Вернули ${date}';
  @override
  String debtRepaid({required Object date}) => 'Отдали ${date}';
  @override
  String debtReturnedPart({required Object left}) =>
      'Вернули часть · осталось ${left}';
  @override
  String debtRepaidPart({required Object left}) =>
      'Отдали часть · осталось ${left}';
  @override
  String debtWaits({required Object left}) =>
      'Ещё не вернули · осталось ${left}';
  @override
  String debtWaitsRepaid({required Object left}) =>
      'Ещё не отдали · осталось ${left}';
  @override
  String get debtGone => 'Этого долга больше нет';
  @override
  String get today => 'сегодня';
  @override
  List<String> get months => [
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
  String get howTitle => 'Что сюда приходит';
  @override
  List<String> get how => [
    '«Платежи» — регулярный платёж, который ждёт вашего «Провести».',
    '«Импорт» — итоги выписок: что добавили и что ждёт во «Входящих».',
    '«Birka» — что нового в самой Birka.',
    'Новые стоят сверху; прочитанные уходят в историю по дням.',
  ];
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
        zero: '${n} валют',
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
  @override
  List<String> get monthReport => [
    'Отчёт за январь',
    'Отчёт за февраль',
    'Отчёт за март',
    'Отчёт за апрель',
    'Отчёт за май',
    'Отчёт за июнь',
    'Отчёт за июль',
    'Отчёт за август',
    'Отчёт за сентябрь',
    'Отчёт за октябрь',
    'Отчёт за ноябрь',
    'Отчёт за декабрь',
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
  String leftAfterPaydayAdvance({
    required Object date,
    required Object amount,
  }) =>
      'К зарплате ${date} на счетах останется ≈ ${amount} с авансом, если не считать ежедневных трат.';
  @override
  String leftAfterMonthAdvance({required Object amount}) =>
      'К концу месяца на счетах останется ≈ ${amount} с авансом, если не считать ежедневных трат.';
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
        zero: '${n} дней',
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
        zero: '${n} платежей до зарплаты',
        one: '${n} платёж до зарплаты',
        few: '${n} платежа до зарплаты',
        many: '${n} платежей до зарплаты',
        other: '${n} платежей до зарплаты',
      );
  @override
  String paymentsUntilMonth({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} платежей до конца месяца',
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
        zero: 'Остаётся на ${n} дней',
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
  @override
  String get advance => 'Аванс';
  @override
  String everyTwice({required Object advance, required Object day}) =>
      'аванс ${advance}-го и зарплата ${day}-го';
  @override
  String advancePosted({required Object date}) =>
      'аванс проведён сегодня · зарплата ${date}';
  @override
  String advanceSkipped({required Object date}) =>
      'аванс пропущен · зарплата ${date}';
  @override
  String advanceFound({required Object date}) =>
      'аванс нашли в выписке · зарплата ${date}';
  @override
  String restPosted({required Object date}) =>
      'зарплата проведена сегодня · аванс ${date}';
  @override
  String restSkipped({required Object date}) =>
      'зарплата пропущена · аванс ${date}';
  @override
  String restFound({required Object date}) =>
      'зарплату нашли в выписке · аванс ${date}';
  @override
  String advanceOn({required Object date}) => 'Аванс ${date}';
  @override
  String nearEnough({
    required Object date,
    required Object amount,
    required Object days,
  }) => 'До аванса ${date} хватает: ${amount} на ${days}';
  @override
  String nearShort({required Object date, required Object amount}) =>
      'До аванса ${date} не хватает ${amount}';
  @override
  String get paydayTwice => 'Аванс и зарплата';
  @override
  String paydayTwiceDays({required Object advance, required Object day}) =>
      '${advance}-го и ${day}-го';
  @override
  String get partsTitle => 'Как приходит';
  @override
  Map<String, String> get parts => {
    'one': 'Одной суммой',
    'two': 'С авансом',
  };
  @override
  String get partsOne => 'Вся сумма приходит в один день.';
  @override
  String partsTwo({required Object advance, required Object day}) =>
      'Пополам: аванс ${advance}-го, зарплата ${day}-го.';
  @override
  String partsOwn({
    required Object advanceAmount,
    required Object advance,
    required Object restAmount,
    required Object day,
  }) =>
      'Аванс ${advanceAmount} ${advance}-го, зарплата ${restAmount} ${day}-го.';
  @override
  String get amountMonthly => 'Сумма в месяц';
  @override
  String halves({required Object amount}) => 'по ${amount} авансом и зарплатой';
  @override
  String halvesOwn({required Object advance, required Object rest}) =>
      'аванс ${advance} и зарплата ${rest}';
  @override
  String get halvesUneven => 'Сумма не делится пополам — поправьте копейки';
  @override
  String get advanceDay => 'Аванс';
  @override
  String get restDay => 'Зарплата';
  @override
  String get advanceAmount => 'Сумма аванса';
  @override
  String get advanceHalf => 'половина';
  @override
  String advanceRest({required Object amount, required Object day}) =>
      'Зарплатой придёт остальное: ${amount} ${day}-го.';
  @override
  String advanceHalfChip({required Object amount}) => 'Пополам · ${amount}';
  @override
  String nextAdvance({required Object date}) => 'аванс, ${date}';
  @override
  String monthStartHint({
    required Object day,
    required Object month,
    required Object from,
    required Object to,
  }) =>
      'Зарплата приходит ${day}-го: месяц можно начинать с этого дня, тогда ${month} — с ${from} по ${to}.';
  @override
  String get remindTitle => 'Напоминания';
  @override
  String get remindNotify => 'Уведомления от Birka';
  @override
  String get remindNotifyOff => 'пока Birka на телефоне';
  @override
  String remindNotifyOn({required num n, required Object time}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} платежей · в ${time}',
        one: '${n} платёж · в ${time}',
        few: '${n} платежа · в ${time}',
        many: '${n} платежей · в ${time}',
        other: '${n} платежей · в ${time}',
      );
  @override
  String remindNotifyDebts({required num n, required Object time}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} долгов · в ${time}',
        one: '${n} долг · в ${time}',
        few: '${n} долга · в ${time}',
        many: '${n} долгов · в ${time}',
        other: '${n} долгов · в ${time}',
      );
  @override
  String remindNotifyBoth({
    required Object payments,
    required Object debts,
    required Object time,
  }) => '${payments} и ${debts} · в ${time}';
  @override
  String remindPayments({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} платежей',
        one: '${n} платёж',
        few: '${n} платежа',
        many: '${n} платежей',
        other: '${n} платежей',
      );
  @override
  String remindDebtCount({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} долгов',
        one: '${n} долг',
        few: '${n} долга',
        many: '${n} долгов',
        other: '${n} долгов',
      );
  @override
  String get remindNotifyDenied => 'нет доступа к уведомлениям';
  @override
  String get remindCalendar => 'События в календаре';
  @override
  String remindCalendarOn({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'календарь «Birka» · ${n} событий',
        one: 'календарь «Birka» · ${n} событие',
        few: 'календарь «Birka» · ${n} события',
        many: 'календарь «Birka» · ${n} событий',
        other: 'календарь «Birka» · ${n} событий',
      );
  @override
  String get remindCalendarOff => 'напомнит и без Birka';
  @override
  String get remindCalendarDenied => 'нет доступа к календарю';
  @override
  String get remindTime => 'Время';
  @override
  String get remindSums => 'Суммы в напоминаниях';
  @override
  String get remindSumsNote => 'на экране блокировки и в календаре';
  @override
  String get remindNoteOff =>
      'Напомнить можно в день платежа или накануне: это выбирается у каждого платежа. О долге Birka напомнит в день срока.';
  @override
  String get remindNoteOn =>
      'Удалите Birka — напоминания исчезнут вместе с ней. Календарь напомнит и без неё.';
  @override
  String get remindNoteDenied =>
      'Чтобы Birka напоминала, разрешите ей уведомления в настройках телефона.';
  @override
  String get remindNoteCalendar =>
      'Если календарь синхронизируется с iCloud или Google, названия и суммы платежей попадут туда.';
  @override
  String get remindNoteBoth => 'О платеже напомнят дважды: Birka и календарь.';
  @override
  String get remindNoteCalendarDenied =>
      'Чтобы календарь напоминал, откройте ему доступ в настройках телефона.';
  @override
  String get remindAskTitle => 'Напоминания от Birka';
  @override
  String remindAskText({required Object time}) =>
      'Birka напомнит о платеже в ${time} — в день платежа или накануне, как выбрано у платежа. Напоминания ставятся на этом телефоне, сервер для них не нужен.';
  @override
  String remindAskExample({required Object date, required Object time}) =>
      '${date}, ${time} · нажмёте — откроется платёж';
  @override
  String get remindAskLocalTitle => 'Живут вместе с Birka';
  @override
  String get remindAskLocalText =>
      'Удалите приложение — исчезнут и напоминания. Календарь напомнит и без него.';
  @override
  String get remindAllow => 'Разрешить уведомления';
  @override
  String get remindNotNow => 'Не сейчас';
  @override
  String get remindCalendarAskText =>
      'Birka заведёт календарь «Birka» и добавит в него регулярные платежи. Напоминать будет сам календарь — даже если удалить Birka.';
  @override
  String get remindCalendarAskOwnTitle => 'Календарь «Birka»';
  @override
  String remindCalendarAskOwn({required num n, required Object time}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} платежей · напомнит в ${time}',
        one: '${n} платёж · напомнит в ${time}',
        few: '${n} платежа · напомнит в ${time}',
        many: '${n} платежей · напомнит в ${time}',
        other: '${n} платежей · напомнит в ${time}',
      );
  @override
  String get remindCalendarAskSyncTitle => 'Если календарь синхронизируется';
  @override
  String get remindCalendarAskSyncText =>
      'Названия и суммы платежей попадут в iCloud или Google. Суммы можно убрать в настройках.';
  @override
  String get remindCalendarAskOthersTitle => 'Чужие события Birka не читает';
  @override
  String get remindCalendarAskOthersText =>
      'Телефон спросит полный доступ: без него Birka не сможет менять и удалять свои события.';
  @override
  String get remindCalendarAllow => 'Разрешить доступ к календарю';
  @override
  String get remindCalendarRemoveTitle => 'Убрать календарь «Birka»?';
  @override
  String remindCalendarRemoveText({
    required num n,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    zero:
        'Календарь «Birka» и ${n} событий в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
    one:
        'Календарь «Birka» и ${n} событие в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
    few:
        'Календарь «Birka» и ${n} события в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
    many:
        'Календарь «Birka» и ${n} событий в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
    other:
        'Календарь «Birka» и ${n} событий в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
  );
  @override
  String get remindCalendarRemove => 'Убрать календарь';
  @override
  String get remindCalendarDeniedTitle => 'Нет доступа к календарю';
  @override
  String get remindCalendarDeniedText =>
      'Доступ выключен в настройках телефона. Откройте «Настройки» → «Birka» → «Календари» и выберите «Полный доступ».';
  @override
  String get remindCalendarOnToast => 'Платежи в календаре «Birka»';
  @override
  String get remindCalendarOffToast => 'Календарь «Birka» убран';
  @override
  String get remindDeniedTitle => 'Нет доступа к уведомлениям';
  @override
  String get remindDeniedText =>
      'Уведомления Birka выключены в настройках телефона. Откройте «Настройки» → «Birka» → «Уведомления» и включите их.';
  @override
  String get remindOpenSettings => 'Открыть настройки';
  @override
  String get remindCancel => 'Отмена';
  @override
  String get remindOnTitle => 'Напоминания включены';
  @override
  String remindOnText({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Birka напомнит о ${n} платежах',
        one: 'Birka напомнит о ${n} платеже',
        few: 'Birka напомнит о ${n} платежах',
        many: 'Birka напомнит о ${n} платежах',
        other: 'Birka напомнит о ${n} платежах',
      );
  @override
  String get remindOnNone => 'Отметьте «Напомнить» у платежей';
  @override
  String get remindToday => 'Сегодня. Нажмите, чтобы провести или пропустить.';
  @override
  String get remindTodayAuto => 'Сегодня, проведётся само.';
  @override
  String remindTomorrow({required Object date}) =>
      'Завтра, ${date}. Нажмите, чтобы открыть платёж.';
  @override
  String remindDebtTitle({required Object name, required Object amount}) =>
      'Срок сегодня · ${name}, ${amount}';
  @override
  String remindDebtTitleNoSum({required Object name}) =>
      'Срок сегодня · ${name}';
  @override
  String get remindDebtLent =>
      'Сегодня вам должны вернуть долг. Нажмите, чтобы открыть его.';
  @override
  String get remindDebtBorrowed =>
      'Сегодня срок отдать долг. Нажмите, чтобы открыть его.';
  @override
  String get remindChannel => 'Напоминания о платежах и долгах';
  @override
  String get remindChannelNote =>
      'Регулярные платежи в их день или накануне и сроки долгов';
  @override
  String get remindSection => 'Напомнить';
  @override
  Map<String, String> get reminder => {
    'onDay': 'В день',
    'dayBefore': 'За день',
    'none': 'Не напоминать',
  };
  @override
  String remindLine({
    required Object date,
    required Object time,
    required Object who,
  }) => '${date} в ${time} · ${who}';
  @override
  String get remindByBirka => 'напомнит Birka';
  @override
  String get remindByCalendar => 'напомнит календарь «Birka»';
  @override
  String get remindByBoth => 'напомнят Birka и календарь';
  @override
  String get remindLineNone => 'Без напоминания';
  @override
  String get remindLineOff => 'Напоминания выключены в «Ещё»';
  @override
  String get remindEnable => 'Включить напоминания';
  @override
  String get makeRegular => 'Сделать регулярным';
  @override
  String makeRegularLine({required Object every}) => 'Повторять ${every}';
  @override
  String get regularPayment => 'Регулярный платёж';
  @override
  String fromOperation({required Object date}) => 'Из операции ${date}';
  @override
  String madeRegular({required Object name}) =>
      'Добавили в регулярные: «${name}»';
  @override
  String get findsTitle => 'Похоже на регулярные';
  @override
  String get findsTitleEmpty => 'Нашли в ваших операциях';
  @override
  String get findsNote =>
      'Повторялись каждый месяц. Нажмите, чтобы добавить, или ✕, если повтор случайный.';
  @override
  String findLine({
    required num n,
    required Object day,
    required Object count,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    zero: '${day}-го · ${count} раз подряд',
    one: '${day}-го · ${count} раз подряд',
    few: '${day}-го · ${count} раза подряд',
    many: '${day}-го · ${count} раз подряд',
    other: '${day}-го · ${count} раза подряд',
  );
  @override
  String findLineVaries({
    required num n,
    required Object day,
    required Object count,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    zero: 'около ${day}-го · ${count} раз',
    one: 'около ${day}-го · ${count} раз',
    few: 'около ${day}-го · ${count} раза',
    many: 'около ${day}-го · ${count} раз',
    other: 'около ${day}-го · ${count} раза',
  );
  @override
  String findDismiss({required Object name}) => 'Не регулярный: ${name}';
  @override
  String findDismissed({required Object name}) =>
      'Не будем предлагать «${name}»';
  @override
  String get findRestore => 'Вернуть';
  @override
  String foundIn({required num n, required Object count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Нашли в операциях · ${count} раз',
        one: 'Нашли в операциях · ${count} раз',
        few: 'Нашли в операциях · ${count} раза',
        many: 'Нашли в операциях · ${count} раз',
        other: 'Нашли в операциях · ${count} раза',
      );
  @override
  String amountRange({required Object min, required Object max}) =>
      'последняя сумма · бывало от ${min} до ${max}';
  @override
  String get forecast => 'Если тратить как обычно';
  @override
  String forecastRunsOut({required Object date}) => 'Деньги кончатся ${date}';
  @override
  String get forecastLastsPayday => 'Хватит до зарплаты';
  @override
  String get forecastLastsMonth => 'Хватит до конца месяца';
  @override
  String get forecastNone => 'Денег не хватает уже сейчас';
  @override
  String get forecastNonePayday => 'Платежи до зарплаты больше, чем на счетах.';
  @override
  String get forecastNoneMonth =>
      'Платежи до конца месяца больше, чем на счетах.';
  @override
  String forecastShortText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object amount,
  }) =>
      'Обычно вы тратите ≈ ${usual} в день, а можно ${perDay}. К ${date} не хватит ≈ ${amount}.';
  @override
  String forecastLeftText({
    required Object usual,
    required Object date,
    required Object amount,
  }) => 'Обычно вы тратите ≈ ${usual} в день: к ${date} останется ≈ ${amount}.';
  @override
  String get forecastToday => 'сегодня';
  @override
  String forecastPayday({required Object date}) => '${date} · зарплата';
  @override
  String get forecastUsual => 'как обычно';
  @override
  String forecastPlan({required Object amount}) => 'по плану: ${amount} в день';
  @override
  String get forecastPlanBare => 'по плану';
  @override
  String get forecastNote =>
      'Обычные траты — среднее за 3 месяца по этим счетам, без регулярных платежей и переводов.';
  @override
  String forecastLineRunsOut({required Object date}) =>
      'Как обычно — деньги кончатся ${date}';
  @override
  String get forecastLinePayday => 'Как обычно — хватит до зарплаты';
  @override
  String get forecastLineMonth => 'Как обычно — хватит до конца месяца';
  @override
  String forecastAdvanceLastsText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object end,
    required Object amount,
  }) =>
      'Обычно вы тратите ≈ ${usual} в день, а до аванса можно ${perDay}. После аванса ${date} хватит: к ${end} останется ≈ ${amount}.';
  @override
  String forecastAdvanceAgainText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object again,
    required Object end,
    required Object amount,
  }) =>
      'Обычно вы тратите ≈ ${usual} в день, а до аванса можно ${perDay}. С авансом ${date} деньги кончатся снова ${again}, к ${end} не хватит ≈ ${amount}.';
  @override
  String forecastAdvanceShortText({
    required Object usual,
    required Object perDay,
    required Object date,
    required Object end,
    required Object amount,
  }) =>
      'Обычно вы тратите ≈ ${usual} в день, а до аванса можно ${perDay}. Аванса ${date} не хватит на эти дни: к ${end} не хватит ≈ ${amount}.';
  @override
  String forecastNoneAdvance({required Object date}) =>
      'До аванса ${date} платежи и отложенное больше, чем на счетах.';
  @override
  String forecastPlanAdvance({required Object amount}) =>
      'по плану: ${amount} в день до аванса';
  @override
  String forecastAdvance({required Object date}) => '${date} · аванс';
  @override
  String subtitleNext({required Object date, required Object count}) =>
      'Ближайший ${date} · ${count}';
  @override
  String subtitleToday({required num n, required Object date}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Сегодня ${date} · ${n} ждут подтверждения',
        one: 'Сегодня ${date} · ${n} ждёт подтверждения',
        few: 'Сегодня ${date} · ${n} ждут подтверждения',
        many: 'Сегодня ${date} · ${n} ждут подтверждения',
        other: 'Сегодня ${date} · ${n} ждут подтверждения',
      );
  @override
  String get subtitleNone => 'Пока ни одного';
  @override
  String paymentsCount({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} платежей',
        one: '${n} платёж',
        few: '${n} платежа',
        many: '${n} платежей',
        other: '${n} платежей',
      );
  @override
  String get perDayTitle => 'Можно тратить в день';
  @override
  String paidAheadPayday({required Object amount}) =>
      'Платежи до зарплаты уже вычтены: ${amount}.';
  @override
  String paidAheadMonth({required Object amount}) =>
      'Платежи до конца месяца уже вычтены: ${amount}.';
  @override
  String get howTitle => 'Как это устроено';
  @override
  List<String> get how => [
    'Платёж стоит в плане на свой день — его уже нет в «Можно тратить сегодня».',
    'В день платежа он ждёт вашего «Провести» или проводится сам — как выбрано в платеже.',
    'Придёт в выписке банка — Birka не задвоит его.',
    'Повторы в операциях Birka находит сама и предлагает добавить.',
  ];
  @override
  String get failed => 'Не удалось прочитать платежи.';
  @override
  String get previewTitle => 'В списке платежей';
  @override
  String get previewNext => 'Следующие разы';
  @override
  String get cancel => 'Отмена';
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
  @override
  String get monthStart => 'Начало месяца';
  @override
  String monthStartDay({required Object day}) => '${day} число';
  @override
  String get monthStartNote => 'для обзора и отчётов';
  @override
  String get monthStartCalendar => 'как в календаре';
}

// Path: tags
class _Translations$tags$ru extends Translations$tags$en {
  _Translations$tags$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Метки';
  @override
  String get back => 'Назад';
  @override
  String get add => 'Новая метка';
  @override
  String get close => 'Закрыть';
  @override
  String get edit => 'Изменить';
  @override
  String get now => 'Сейчас';
  @override
  String get trips => 'Поездки';
  @override
  String get plain => 'Метки';
  @override
  String get trip => 'Поездка';
  @override
  String get tag => 'Метка';
  @override
  String get note => 'Суммы — расходы по курсу ЦБ на день каждой операции.';
  @override
  String get emptyTitle => 'Меток пока нет';
  @override
  String get emptyText =>
      'Отметьте поездку, ремонт или праздник — и увидите, сколько на них ушло, во всех валютах сразу.';
  @override
  String get failed => 'Не удалось прочитать метки.';
  @override
  String get lastDay => 'Последний день';
  @override
  String dayOf({required Object day, required Object total}) =>
      'День ${day} из ${total}';
  @override
  String days({required Object from, required Object to}) => '${from}–${to}';
  @override
  String daysApart({required Object from, required Object to}) =>
      '${from} — ${to}';
  @override
  String inDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'через ${n} дней',
        one: 'через ${n} день',
        few: 'через ${n} дня',
        many: 'через ${n} дней',
        other: 'через ${n} дня',
      );
  @override
  String operations({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} операций',
        one: '${n} операция',
        few: '${n} операции',
        many: '${n} операций',
        other: '${n} операции',
      );
  @override
  String since({required Object date}) => 'с ${date}';
  @override
  String get howItWorks => 'Как это устроено';
  @override
  late final _Translations$tags$steps$ru steps = _Translations$tags$steps$ru._(
    _root,
  );
  @override
  late final _Translations$tags$report$ru report =
      _Translations$tags$report$ru._(_root);
  @override
  late final _Translations$tags$form$ru form = _Translations$tags$form$ru._(
    _root,
  );
  @override
  String addedTrip({required Object name}) => 'Добавили поездку «${name}»';
  @override
  String addedTag({required Object name}) => 'Добавили метку «${name}»';
  @override
  String saved({required Object name}) => 'Сохранили «${name}»';
  @override
  String marked({required num n, required Object name}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Отметили ${n} расходов: «${name}»',
        one: 'Отметили ${n} расход: «${name}»',
        few: 'Отметили ${n} расхода: «${name}»',
        many: 'Отметили ${n} расходов: «${name}»',
        other: 'Отметили ${n} расхода: «${name}»',
      );
  @override
  String unmarked({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Сняли метку с ${n} расходов',
        one: 'Сняли метку с ${n} расхода',
        few: 'Сняли метку с ${n} расходов',
        many: 'Сняли метку с ${n} расходов',
        other: 'Сняли метку с ${n} расхода',
      );
  @override
  String get undo => 'Вернуть';
  @override
  late final _Translations$tags$picker$ru picker =
      _Translations$tags$picker$ru._(_root);
  @override
  late final _Translations$tags$row$ru row = _Translations$tags$row$ru._(_root);
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
  String get addTag => 'Метка';
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
  String get fromQuestion => 'Из вопроса';
  @override
  String get toAnswer => 'К ответу';
  @override
  String dropFocus({required Object title}) => 'Снять «${title}»';
  @override
  String get focusText =>
      'Список показывает только то, о чём был вопрос. Снимите плашку — вернутся все операции месяца.';
  @override
  String get backToAnswer => 'Вернуться к ответу';
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
  late final _Translations$transactions$debt$ru debt =
      _Translations$transactions$debt$ru._(_root);
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
  @override
  String allOperations({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Все ${n} операций',
        one: 'Все ${n} операция',
        few: 'Все ${n} операции',
        many: 'Все ${n} операций',
        other: 'Все ${n} операции',
      );
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

// Path: ask.start
class _Translations$ask$start$ru extends Translations$ask$start$en {
  _Translations$ask$start$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Спросите про деньги словами';
  @override
  String get text =>
      'Что, когда и сколько: «кафе в октябре», «траты в поездке», «больше 5000 в этом месяце». Birka поймёт вопрос, покажет, как поняла, и посчитает ответ сама.';
}

// Path: ask.example
class _Translations$ask$example$ru extends Translations$ask$example$en {
  _Translations$ask$example$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String category({required Object category, required Object month}) =>
      '${category} ${month}';
  @override
  String get categoryText => 'Сумма, сравнение и самые крупные';
  @override
  String trip({required Object name}) => 'Траты в поездке «${name}»';
  @override
  String get tripText => 'Итог поездки во всех валютах';
  @override
  String get big => 'Больше 5000 в этом месяце';
  @override
  String get bigText => 'Крупные траты месяца';
  @override
  String get allowance => 'Сколько можно тратить';
  @override
  String get allowanceText => 'Сегодня и до зарплаты';
  @override
  String get payments => 'Когда следующий платёж';
  @override
  String get paymentsText => 'Регулярные платежи по датам';
  @override
  String get move => 'Как перенести данные';
  @override
  String get moveText => 'Ответ из справки';
}

// Path: ask.side
class _Translations$ask$side$ru extends Translations$ask$side$en {
  _Translations$ask$side$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get expenses => 'Траты';
  @override
  String get income => 'Доходы';
}

// Path: ask.answer
class _Translations$ask$answer$ru extends Translations$ask$answer$en {
  _Translations$ask$answer$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String of({required Object what, required Object when}) =>
      '${what} · ${when}';
  @override
  String everything({required Object what}) => '${what}';
  @override
  String operations({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} операций',
        one: '${n} операция',
        few: '${n} операции',
        many: '${n} операций',
        other: '${n} операции',
      );
  @override
  String incomes({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} поступлений',
        one: '${n} поступление',
        few: '${n} поступления',
        many: '${n} поступлений',
        other: '${n} поступления',
      );
  @override
  String average({required Object amount}) => 'в среднем ${amount}';
  @override
  String share({required Object percent, required Object when}) =>
      '${percent}% всех трат ${when}';
  @override
  String get none => 'Таких операций нет';
  @override
  String get noneText =>
      'Попробуйте другой период или уберите лишнее из вопроса.';
  @override
  String show({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Показать ${n} операций',
        one: 'Показать ${n} операцию',
        few: 'Показать ${n} операции',
        many: 'Показать ${n} операций',
        other: 'Показать ${n} операции',
      );
  @override
  String get biggest => 'Самые крупные';
  @override
  String get operationsTitle => 'Операции';
  @override
  String get sharesExpenses => 'По категориям';
  @override
  String get sharesIncome => 'Откуда';
  @override
  String get noCategory => 'Без категории';
  @override
  String get counted =>
      'Посчитано на этом устройстве по курсу ЦБ на день каждой операции.';
  @override
  String get countedWeb =>
      'Посчитано в этом браузере по курсу ЦБ на день каждой операции.';
  @override
  String get partial => 'Часть сумм пока без курса и не вошла в итог.';
  @override
  String get trip => 'Отчёт поездки';
  @override
  String get tripText => 'Валюты, категории и дни';
}

// Path: ask.before
class _Translations$ask$before$ru extends Translations$ask$before$en {
  _Translations$ask$before$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String month({required Object month}) => 'к ${month}';
  @override
  String months({required Object period}) => 'к ${period}';
  @override
  String days({required Object period}) => 'к ${period}';
  @override
  String year({required Object year}) => 'к тем же дням ${year}';
  @override
  String wholeYear({required Object year}) => 'к ${year}';
  @override
  String day({required Object day}) => 'к ${day}';
  @override
  String get week => 'к прошлой неделе';
}

// Path: ask.period
class _Translations$ask$period$ru extends Translations$ask$period$en {
  _Translations$ask$period$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Период';
  @override
  String get subtitle => 'Ответ посчитается заново';
  @override
  String get today => 'Сегодня';
  @override
  String get yesterday => 'Вчера';
  @override
  String get thisWeek => 'Эта неделя';
  @override
  String get lastWeek => 'Прошлая неделя';
  @override
  String get thisMonth => 'Этот месяц';
  @override
  String lastMonths({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Последние ${n} месяцев',
        one: 'Последний ${n} месяц',
        few: 'Последние ${n} месяца',
        many: 'Последние ${n} месяцев',
        other: 'Последние ${n} месяца',
      );
  @override
  String get thisYear => 'Этот год';
  @override
  String lastDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'Последние ${n} дней',
        one: 'Последний ${n} день',
        few: 'Последние ${n} дня',
        many: 'Последние ${n} дней',
        other: 'Последние ${n} дня',
      );
  @override
  String months({required Object from, required Object to}) =>
      '${from} – ${to}';
  @override
  String get sinceYear => 'С 1 января';
  @override
  String days({required Object from, required Object to}) => '${from}–${to}';
  @override
  String daysApart({required Object from, required Object to}) =>
      '${from} — ${to}';
}

// Path: ask.fact
class _Translations$ask$fact$ru extends Translations$ask$fact$en {
  _Translations$ask$fact$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String capital({required Object currencies}) => 'Капитал · ${currencies}';
  @override
  String accounts({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} счетов',
        one: '${n} счёт',
        few: '${n} счёта',
        many: '${n} счетов',
        other: '${n} счёта',
      );
  @override
  String get allAccounts => 'Все счета';
  @override
  String get allAccountsText => 'Балансы и история';
  @override
  String rate({required Object day}) => 'Курс ЦБ на ${day}';
  @override
  String rateFor({required Object sign}) => 'за 1 ${sign}';
  @override
  String get rateKept =>
      'Курсы обновляются раз в день и хранятся на устройстве.';
  @override
  String get rateKeptWeb =>
      'Курсы обновляются раз в день и хранятся в этом браузере.';
  @override
  String get rateMissing => 'Курса этой валюты пока нет.';
  @override
  String get rateHelp => 'Откуда берётся курс';
  @override
  String get rateHelpText => 'Ответ из справки';
}

// Path: ask.help
class _Translations$ask$help$ru extends Translations$ask$help$en {
  _Translations$ask$help$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Из справки';
  @override
  String get all => 'Вся справка';
}

// Path: ask.places
class _Translations$ask$places$ru extends Translations$ask$places$en {
  _Translations$ask$places$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Экраны';
  @override
  String get payday => 'Деньги до зарплаты';
  @override
  String get paydayText => 'Сколько можно тратить в день и прогноз';
  @override
  String get schedules => 'Регулярные платежи';
  @override
  String get schedulesText => 'Подписки, аренда и зарплата';
  @override
  String get tags => 'Метки и поездки';
  @override
  String get tagsText => 'Траты поездок и проектов';
  @override
  String get accounts => 'Счета';
  @override
  String get accountsText => 'Балансы и история';
  @override
  String get categories => 'Категории';
  @override
  String get categoriesText => 'Расходы и доходы';
  @override
  String get imports => 'Импорт выписки';
  @override
  String get importsText => 'Операции из файла банка';
  @override
  String get inbox => 'Входящие';
  @override
  String get inboxText => 'Что ждёт решения после импорта';
  @override
  String get backup => 'Данные';
  @override
  String get backupText => 'Копия, восстановление и экспорт';
  @override
  String get help => 'Помощь и отзыв';
  @override
  String get helpText => 'Частые вопросы и письмо разработчику';
  @override
  String get notifications => 'Уведомления';
  @override
  String get notificationsText => 'Что сообщала Birka';
  @override
  String get reports => 'Отчёты';
  @override
  String get reportsText => 'Траты и доходы по месяцам';
  @override
  String get settings => 'Ещё';
  @override
  String get settingsText => 'Базовая валюта, начало месяца, язык';
}

// Path: ask.refused
class _Translations$ask$refused$ru extends Translations$ask$refused$en {
  _Translations$ask$refused$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get advice => 'Советов о вложениях и курсах не даю';
  @override
  String get adviceText =>
      'Birka считает ваши деньги, но не предсказывает курсы и не говорит, что покупать.';
  @override
  String get offTopic => 'Отвечаю только про ваши деньги';
  @override
  String get offTopicText =>
      'Спросите про траты, доходы, счета, платежи или настройки Birka.';
  @override
  String get unknown => 'Не понял вопрос';
  @override
  String get unknownText =>
      'Попробуйте короче: что, когда и сколько. Например, «кафе в октябре».';
  @override
  String get suggest => 'Можно спросить так';
  @override
  String get write => 'Написать разработчику';
  @override
  String get writeText => 'Расскажите, что хотели узнать';
}

// Path: ask.suggest
class _Translations$ask$suggest$ru extends Translations$ask$suggest$en {
  _Translations$ask$suggest$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get capital => 'Сколько у меня денег';
  @override
  String get rate => 'Курс доллара';
  @override
  String get allowance => 'Сколько можно тратить';
  @override
  String get payments => 'Когда следующий платёж';
  @override
  String get income => 'Доходы в прошлом месяце';
  @override
  String get expenses => 'Траты в этом месяце';
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

// Path: debts.line
class _Translations$debts$line$ru extends Translations$debts$line$en {
  _Translations$debts$line$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get dueToday => 'срок сегодня';
  @override
  String dueOn({required Object day}) => 'до ${day}';
  @override
  String overdue({required Object day}) => 'срок был ${day}';
  @override
  String since({required Object day}) => 'с ${day}';
  @override
  String returned({required Object day}) => 'вернули ${day}';
  @override
  String repaid({required Object day}) => 'отдали ${day}';
  @override
  String of({required Object total}) => 'из ${total}';
  @override
  String approx({required Object amount}) => '≈ ${amount}';
}

// Path: debts.card
class _Translations$debts$card$ru extends Translations$debts$card$en {
  _Translations$debts$card$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Долг';
  @override
  String get edit => 'Изменить';
  @override
  String leftToMe({required Object total}) =>
      'осталось вернуть вам из ${total}';
  @override
  String leftToThem({required Object total}) => 'осталось отдать из ${total}';
  @override
  String allReturned({required Object day}) => 'вернули всё · ${day}';
  @override
  String allRepaid({required Object day}) => 'отдали всё · ${day}';
  @override
  String returned({required Object amount}) => 'Вернули ${amount}';
  @override
  String repaid({required Object amount}) => 'Отдали ${amount}';
  @override
  String dueRemind({required Object day}) =>
      'Срок ${day} · напомним в этот день';
  @override
  String dueIn({required Object day, required Object inDays}) =>
      'Срок ${day} · ${inDays}';
  @override
  String dueOn({required Object day}) => 'Срок ${day}';
  @override
  String get dueToday => 'Срок сегодня';
  @override
  String dueWas({required Object day}) => 'Срок был ${day}';
  @override
  String get noDue => 'Без срока';
  @override
  String get closed => 'Долг закрыт';
  @override
  String get closedRemind => 'Долг закрыт · напоминание снято';
  @override
  String get history => 'История';
  @override
  String get returnAction => 'Возврат';
  @override
  String get repayAction => 'Отдать';
  @override
  String get lendMore => 'Ещё в долг';
  @override
  String get borrowMore => 'Занять ещё';
  @override
  String get newDebt => 'Новый долг';
}

// Path: debts.form
class _Translations$debts$form$ru extends Translations$debts$form$en {
  _Translations$debts$form$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get lend => 'Одолжить';
  @override
  String get borrow => 'Занять';
  @override
  String get who => 'Кто';
  @override
  String get other => 'Другой';
  @override
  String get name => 'Имя';
  @override
  String get nameHint => 'Как зовут';
  @override
  String get nameMissing => 'Напишите, кто это';
  @override
  String get amount => 'Сумма';
  @override
  String get fromAccount => 'Со счёта';
  @override
  String get toAccount => 'На счёт';
  @override
  String get when => 'Когда';
  @override
  String get dueBy => 'Вернуть до';
  @override
  String get noDue => 'Без срока';
  @override
  String get note => 'Заметка';
  @override
  String get noteHint => 'Необязательно';
  @override
  String get remind => 'Напомнить в срок';
  @override
  String get lendCaption =>
      'Долг — не трата: деньги уйдут со счёта, но в расходы месяца не попадут.';
  @override
  String get borrowCaption =>
      'Долг — не доход: деньги придут на счёт, но в доходы месяца не попадут.';
  @override
  String noAccount({required Object currency}) =>
      'Долг в ${currency}, а счёта в этой валюте нет.';
  @override
  String get save => 'Сохранить';
  @override
  String saved({required Object name, required Object amount}) =>
      'Записали: ${name}, ${amount}';
  @override
  String get failed => 'Не удалось сохранить. Попробуйте ещё раз.';
  @override
  String moreTitle({required Object name}) => 'Ещё в долг · ${name}';
  @override
  String borrowMoreTitle({required Object name}) => 'Занять ещё · ${name}';
  @override
  late final _Translations$debts$form$dueChoices$ru dueChoices =
      _Translations$debts$form$dueChoices$ru._(_root);
  @override
  String get today => 'Сегодня';
  @override
  String get editTitle => 'Изменить долг';
}

// Path: debts.back
class _Translations$debts$back$ru extends Translations$debts$back$en {
  _Translations$debts$back$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String returnTitle({required Object name}) => 'Возврат · ${name}';
  @override
  String repayTitle({required Object name}) => 'Отдать · ${name}';
  @override
  String all({required Object amount}) => 'Всё · ${amount}';
  @override
  String get part => 'Часть';
  @override
  String get howMuchReturned => 'Сколько вернули';
  @override
  String get howMuchRepaid => 'Сколько отдали';
  @override
  String get tooMuch => 'Больше, чем осталось';
  @override
  String get returnClosing =>
      'Долг закроется. Деньги придут на счёт, но не в доходы.';
  @override
  String get returnClosingRemind =>
      'Долг закроется, и напоминание о нём уйдёт. Деньги придут на счёт, но не в доходы.';
  @override
  String returnLeft({required Object left}) =>
      'Останется ${left}. Деньги придут на счёт, но не в доходы.';
  @override
  String returnLeftDue({required Object left, required Object day}) =>
      'Останется ${left} до ${day}. Деньги придут на счёт, но не в доходы.';
  @override
  String get repayClosing =>
      'Долг закроется. Деньги уйдут со счёта, но не в расходы.';
  @override
  String get repayClosingRemind =>
      'Долг закроется, и напоминание о нём уйдёт. Деньги уйдут со счёта, но не в расходы.';
  @override
  String repayLeft({required Object left}) =>
      'Останется ${left}. Деньги уйдут со счёта, но не в расходы.';
  @override
  String repayLeftDue({required Object left, required Object day}) =>
      'Останется ${left} до ${day}. Деньги уйдут со счёта, но не в расходы.';
  @override
  String get save => 'Сохранить возврат';
  @override
  String closedToast({required Object name}) => '${name}: долг закрыт';
  @override
  String returnedToast({required Object amount, required Object left}) =>
      'Возврат ${amount} · осталось ${left}';
  @override
  String repaidToast({required Object amount, required Object left}) =>
      'Отдали ${amount} · осталось ${left}';
}

// Path: debts.steps
class _Translations$debts$steps$ru extends Translations$debts$steps$en {
  _Translations$debts$steps$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get first =>
      'Запишите, кому одолжили и у кого заняли: деньги уйдут со счёта или придут на него.';
  @override
  String get second =>
      'Долг — не трата и не доход: в отчёты месяца он не попадёт.';
  @override
  String get third =>
      'Возвраты закрывают долг частями, и список покажет, сколько осталось и до какого дня.';
}

// Path: debts.move
class _Translations$debts$move$ru extends Translations$debts$move$en {
  _Translations$debts$move$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get lent => 'В долг';
  @override
  String get returned => 'Возврат';
  @override
  String get borrowed => 'Заняли';
  @override
  String get repaid => 'Отдали';
}

// Path: debts.person
class _Translations$debts$person$ru extends Translations$debts$person$en {
  _Translations$debts$person$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get newTitle => 'Новый человек';
  @override
  String get fromContacts => 'Выбрать из контактов';
  @override
  String get fromContactsNote => 'Имя и номер подставятся сами';
  @override
  String get about => 'Кто это';
  @override
  String get aboutHint => 'Необязательно · коллега, сосед';
  @override
  String get phone => 'Телефон';
  @override
  String get optional => 'Необязательно';
  @override
  String get number => 'Номер';
  @override
  String get noNumber => 'Без номера';
  @override
  String get noNumberNote => 'Напомнить можно будет через другое приложение';
  @override
  String get hint =>
      'Имя видно в списке и в напоминаниях. «Кто это» поможет различить тёзок.';
  @override
  String fromContact({required Object contact}) =>
      'Из контактов: ${contact}. Birka взяла только этот контакт, а номер хранит на этом телефоне.';
  @override
  String get contactsRow => 'Взять номер из контактов';
  @override
  String get shared =>
      'Имя, «кто это» и номер — общие для всех долгов этого человека. Номер хранится только на этом телефоне и в ваших копиях.';
  @override
  String twin({required Object name, required Object about}) =>
      '${name} уже есть — ${about}. Напишите, кто это, чтобы их различать.';
  @override
  String twinPlain({required Object name}) =>
      '${name} уже есть. Напишите, кто это, чтобы их различать.';
  @override
  String twinPick({required Object name, required Object about}) =>
      '${name} уже есть — ${about}. Если это тот же человек, выберите его выше; если другой — напишите, кто это.';
  @override
  String twinPickPlain({required Object name}) =>
      '${name} уже есть. Если это тот же человек, выберите его выше; если другой — напишите, кто это.';
}

// Path: debts.remind
class _Translations$debts$remind$ru extends Translations$debts$remind$en {
  _Translations$debts$remind$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get action => 'Напомнить';
  @override
  String get title => 'Напомнить';
  @override
  String get message => 'Сообщение';
  @override
  String get sms => 'Отправить SMS';
  @override
  String get otherApp => 'Другое приложение';
  @override
  String get share => 'Поделиться';
  @override
  String get caption =>
      'Birka только откроет сообщение, а отправите его вы. Текст можно поправить.';
  @override
  String get captionShare =>
      'Birka откроет окно «Поделиться»: выберите, где написать. Текст можно поправить.';
  @override
  String get noPhone => 'Номера нет · добавьте в «Изменить»';
  @override
  String text({required Object amount, required Object day}) =>
      'Привет! Напоминаю про ${amount} — договаривались вернуть до ${day}.';
  @override
  String textNoDue({required Object amount}) =>
      'Привет! Напоминаю про ${amount}.';
}

// Path: demo.people
class _Translations$demo$people$ru extends Translations$demo$people$en {
  _Translations$demo$people$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get masha => 'Маша';
  @override
  String get dima => 'Дима';
  @override
  String get sasha => 'Саша';
  @override
  String get ira => 'Ира';
  @override
  String get dad => 'Папа';
}

// Path: demo.debtNotes
class _Translations$demo$debtNotes$ru extends Translations$demo$debtNotes$en {
  _Translations$demo$debtNotes$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get tickets => 'на билеты';
  @override
  String get flat => 'за квартиру';
  @override
  String get salary => 'до зарплаты';
  @override
  String get concert => 'на концерт';
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
        zero: '${n} категорий',
        one: '${n} категория',
        few: '${n} категории',
        many: '${n} категорий',
        other: '${n} категории',
      );
  @override
  String get finish => 'Готово';
}

// Path: tags.steps
class _Translations$tags$steps$ru extends Translations$tags$steps$en {
  _Translations$tags$steps$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get first =>
      'Метка собирает траты поездки или проекта во всех валютах — по курсу дня.';
  @override
  String get second =>
      'У поездки есть даты: расходы этих дней получают её метку сами, кроме регулярных платежей.';
  @override
  String get third =>
      'Билеты и жильё, купленные заранее, отметьте в карточке операции.';
}

// Path: tags.report
class _Translations$tags$report$ru extends Translations$tags$report$en {
  _Translations$tags$report$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get todayLast => 'сегодня последний день';
  @override
  String get perDay => 'На месте в день';
  @override
  String get perMonth => 'В месяц';
  @override
  String forDays({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: 'за ${n} дней',
        one: 'за ${n} день',
        few: 'за ${n} дня',
        many: 'за ${n} дней',
        other: 'за ${n} дня',
      );
  @override
  String get count => 'Операций';
  @override
  String there({required Object n}) => '${n} там';
  @override
  String before({required Object n}) => '${n} заранее';
  @override
  String after({required Object n}) => '${n} после';
  @override
  String last({required Object date}) => 'последняя ${date}';
  @override
  String get currencies => 'Валюты';
  @override
  String get ratesNote => 'По курсу ЦБ на день каждой операции.';
  @override
  String onTheSpot({required num n}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
        n,
        zero: '${n} операций на месте',
        one: '${n} операция на месте',
        few: '${n} операции на месте',
        many: '${n} операций на месте',
        other: '${n} операции на месте',
      );
  @override
  String get noRate => 'Нет курса на день части операций — итог без них.';
  @override
  String get categories => 'Категории';
  @override
  String get operations => 'Операции';
  @override
  String get nothing => 'На эту метку пока нет операций.';
  @override
  String get noCategory => 'Без категории';
}

// Path: tags.form
class _Translations$tags$form$ru extends Translations$tags$form$en {
  _Translations$tags$form$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get newTitle => 'Новая метка';
  @override
  String get trip => 'Поездка';
  @override
  String get plain => 'Метка';
  @override
  String get name => 'Название';
  @override
  String get namePlaceholder => 'Батуми';
  @override
  String get dates => 'Даты';
  @override
  String get from => 'С';
  @override
  String get to => 'По';
  @override
  String get marks => 'Отмечать расходы';
  @override
  String get marksOn => 'За эти дни';
  @override
  String get marksOff => 'Только вручную';
  @override
  String get marksAhead =>
      'Расходы этих дней получат метку сами. Регулярные платежи не трогаем.';
  @override
  String marksPast({
    required num n,
  }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
    n,
    zero:
        'За эти дни уже ${n} расходов — отметим их сразу. Регулярные платежи не трогаем.',
    one:
        'За эти дни уже ${n} расход — отметим его сразу. Регулярные платежи не трогаем.',
    few:
        'За эти дни уже ${n} расхода — отметим их сразу. Регулярные платежи не трогаем.',
    many:
        'За эти дни уже ${n} расходов — отметим их сразу. Регулярные платежи не трогаем.',
    other:
        'За эти дни уже ${n} расхода — отметим их сразу. Регулярные платежи не трогаем.',
  );
  @override
  String get manual =>
      'Метку ставите сами — при вводе операции или в её карточке.';
  @override
  String get plainNote =>
      'Метку ставите сами — при вводе операции или в её карточке. Отчёт соберёт траты во всех валютах.';
  @override
  String get footTrip => 'Метку можно поставить и на билеты, купленные заранее';
  @override
  String get footPlain => 'Метки живут в «Ещё» → «Метки»';
  @override
  String get save => 'Сохранить';
  @override
  String get done => 'Готово';
  @override
  String get nameMissing => 'Дайте метке название.';
  @override
  String get failed => 'Не удалось сохранить. Попробуйте ещё раз.';
}

// Path: tags.picker
class _Translations$tags$picker$ru extends Translations$tags$picker$en {
  _Translations$tags$picker$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Метки';
  @override
  String get search => 'Найти или создать';
  @override
  String get clear => 'Очистить поиск';
  @override
  String create({required Object name}) => 'Новая метка «${name}»';
  @override
  String get createText => 'Поездка с датами или просто метка';
  @override
  String get tripsNote =>
      'Пока идёт поездка, её метка сама встаёт на расходы этих дней.';
  @override
  String get now => 'сейчас';
  @override
  String get emptyTitle => 'Меток пока нет';
  @override
  String get emptyText =>
      'Наберите название: поездку, ремонт или праздник. Метка соберёт их траты во всех валютах.';
}

// Path: tags.row
class _Translations$tags$row$ru extends Translations$tags$row$en {
  _Translations$tags$row$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get add => 'Добавить метку';
  @override
  String get addText => 'Поездка, ремонт или праздник';
  @override
  String trip({required Object days}) => 'Поездка · ${days}';
  @override
  String byDays({required Object days}) => 'Поездка · ${days} · по датам';
  @override
  String get plain => 'Метка';
  @override
  String more({required Object n}) => 'и ещё ${n}';
}

// Path: transactions.debt
class _Translations$transactions$debt$ru
    extends Translations$transactions$debt$en {
  _Translations$transactions$debt$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'Долг';
  @override
  String get lent => 'в долг';
  @override
  String get returned => 'возврат';
  @override
  String get borrowed => 'заняли';
  @override
  String get repaid => 'отдали';
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

// Path: debts.form.dueChoices
class _Translations$debts$form$dueChoices$ru
    extends Translations$debts$form$dueChoices$en {
  _Translations$debts$form$dueChoices$ru._(TranslationsRu root)
    : this._root = root,
      super.internal(root);

  final TranslationsRu _root; // ignore: unused_field

  // Translations
  @override
  String get none => 'Без срока';
  @override
  String get week => 'Через неделю';
  @override
  String get twoWeeks => 'Через две недели';
  @override
  String get month => 'Через месяц';
  @override
  String get pick => 'Выбрать день';
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
                  zero: 'в ${n} счетах',
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
          'ask.title' => 'Спросить',
          'ask.open' => 'Спросить',
          'ask.hint' => 'Спросите про деньги',
          'ask.clear' => 'Стереть вопрос',
          'ask.back' => 'Назад',
          'ask.examples' => 'Можно спросить',
          'ask.recent' => 'Недавние',
          'ask.forget' => 'Очистить',
          'ask.private' =>
            'Отвечает само приложение: вопросы и ответы остаются на этом устройстве.',
          'ask.failed' => 'Не удалось прочитать данные для ответа.',
          'ask.privateWeb' =>
            'Отвечает само приложение: вопросы и ответы остаются в этом браузере.',
          'ask.slash' => 'Клавиша / открывает «Спросить» с любой страницы.',
          'ask.start.title' => 'Спросите про деньги словами',
          'ask.start.text' =>
            'Что, когда и сколько: «кафе в октябре», «траты в поездке», «больше 5000 в этом месяце». Birka поймёт вопрос, покажет, как поняла, и посчитает ответ сама.',
          'ask.example.category' =>
            ({required Object category, required Object month}) =>
                '${category} ${month}',
          'ask.example.categoryText' => 'Сумма, сравнение и самые крупные',
          'ask.example.trip' =>
            ({required Object name}) => 'Траты в поездке «${name}»',
          'ask.example.tripText' => 'Итог поездки во всех валютах',
          'ask.example.big' => 'Больше 5000 в этом месяце',
          'ask.example.bigText' => 'Крупные траты месяца',
          'ask.example.allowance' => 'Сколько можно тратить',
          'ask.example.allowanceText' => 'Сегодня и до зарплаты',
          'ask.example.payments' => 'Когда следующий платёж',
          'ask.example.paymentsText' => 'Регулярные платежи по датам',
          'ask.example.move' => 'Как перенести данные',
          'ask.example.moveText' => 'Ответ из справки',
          'ask.understood' => 'Понял так',
          'ask.side.expenses' => 'Траты',
          'ask.side.income' => 'Доходы',
          'ask.above' => ({required Object amount}) => 'Больше ${amount}',
          'ask.below' => ({required Object amount}) => 'Меньше ${amount}',
          'ask.word' => ({required Object word}) => '«${word}»',
          'ask.allTime' => 'За всё время',
          'ask.answer.of' =>
            ({required Object what, required Object when}) =>
                '${what} · ${when}',
          'ask.answer.everything' => ({required Object what}) => '${what}',
          'ask.answer.operations' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} операций',
                  one: '${n} операция',
                  few: '${n} операции',
                  many: '${n} операций',
                  other: '${n} операции',
                ),
          'ask.answer.incomes' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} поступлений',
                  one: '${n} поступление',
                  few: '${n} поступления',
                  many: '${n} поступлений',
                  other: '${n} поступления',
                ),
          'ask.answer.average' =>
            ({required Object amount}) => 'в среднем ${amount}',
          'ask.answer.share' =>
            ({required Object percent, required Object when}) =>
                '${percent}% всех трат ${when}',
          'ask.answer.none' => 'Таких операций нет',
          'ask.answer.noneText' =>
            'Попробуйте другой период или уберите лишнее из вопроса.',
          'ask.answer.show' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Показать ${n} операций',
                  one: 'Показать ${n} операцию',
                  few: 'Показать ${n} операции',
                  many: 'Показать ${n} операций',
                  other: 'Показать ${n} операции',
                ),
          'ask.answer.biggest' => 'Самые крупные',
          'ask.answer.operationsTitle' => 'Операции',
          'ask.answer.sharesExpenses' => 'По категориям',
          'ask.answer.sharesIncome' => 'Откуда',
          'ask.answer.noCategory' => 'Без категории',
          'ask.answer.counted' =>
            'Посчитано на этом устройстве по курсу ЦБ на день каждой операции.',
          'ask.answer.countedWeb' =>
            'Посчитано в этом браузере по курсу ЦБ на день каждой операции.',
          'ask.answer.partial' =>
            'Часть сумм пока без курса и не вошла в итог.',
          'ask.answer.trip' => 'Отчёт поездки',
          'ask.answer.tripText' => 'Валюты, категории и дни',
          'ask.before.month' => ({required Object month}) => 'к ${month}',
          'ask.before.months' => ({required Object period}) => 'к ${period}',
          'ask.before.days' => ({required Object period}) => 'к ${period}',
          'ask.before.year' =>
            ({required Object year}) => 'к тем же дням ${year}',
          'ask.before.wholeYear' => ({required Object year}) => 'к ${year}',
          'ask.before.day' => ({required Object day}) => 'к ${day}',
          'ask.before.week' => 'к прошлой неделе',
          'ask.period.title' => 'Период',
          'ask.period.subtitle' => 'Ответ посчитается заново',
          'ask.period.today' => 'Сегодня',
          'ask.period.yesterday' => 'Вчера',
          'ask.period.thisWeek' => 'Эта неделя',
          'ask.period.lastWeek' => 'Прошлая неделя',
          'ask.period.thisMonth' => 'Этот месяц',
          'ask.period.lastMonths' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Последние ${n} месяцев',
                  one: 'Последний ${n} месяц',
                  few: 'Последние ${n} месяца',
                  many: 'Последние ${n} месяцев',
                  other: 'Последние ${n} месяца',
                ),
          'ask.period.thisYear' => 'Этот год',
          'ask.period.lastDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Последние ${n} дней',
                  one: 'Последний ${n} день',
                  few: 'Последние ${n} дня',
                  many: 'Последние ${n} дней',
                  other: 'Последние ${n} дня',
                ),
          'ask.period.months' =>
            ({required Object from, required Object to}) => '${from} – ${to}',
          'ask.period.sinceYear' => 'С 1 января',
          'ask.period.days' =>
            ({required Object from, required Object to}) => '${from}–${to}',
          'ask.period.daysApart' =>
            ({required Object from, required Object to}) => '${from} — ${to}',
          'ask.fact.capital' =>
            ({required Object currencies}) => 'Капитал · ${currencies}',
          'ask.fact.accounts' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} счетов',
                  one: '${n} счёт',
                  few: '${n} счёта',
                  many: '${n} счетов',
                  other: '${n} счёта',
                ),
          'ask.fact.allAccounts' => 'Все счета',
          'ask.fact.allAccountsText' => 'Балансы и история',
          'ask.fact.rate' => ({required Object day}) => 'Курс ЦБ на ${day}',
          'ask.fact.rateFor' => ({required Object sign}) => 'за 1 ${sign}',
          'ask.fact.rateKept' =>
            'Курсы обновляются раз в день и хранятся на устройстве.',
          'ask.fact.rateKeptWeb' =>
            'Курсы обновляются раз в день и хранятся в этом браузере.',
          'ask.fact.rateMissing' => 'Курса этой валюты пока нет.',
          'ask.fact.rateHelp' => 'Откуда берётся курс',
          'ask.fact.rateHelpText' => 'Ответ из справки',
          'ask.help.title' => 'Из справки',
          'ask.help.all' => 'Вся справка',
          'ask.places.title' => 'Экраны',
          'ask.places.payday' => 'Деньги до зарплаты',
          'ask.places.paydayText' => 'Сколько можно тратить в день и прогноз',
          'ask.places.schedules' => 'Регулярные платежи',
          'ask.places.schedulesText' => 'Подписки, аренда и зарплата',
          'ask.places.tags' => 'Метки и поездки',
          'ask.places.tagsText' => 'Траты поездок и проектов',
          'ask.places.accounts' => 'Счета',
          'ask.places.accountsText' => 'Балансы и история',
          'ask.places.categories' => 'Категории',
          'ask.places.categoriesText' => 'Расходы и доходы',
          'ask.places.imports' => 'Импорт выписки',
          'ask.places.importsText' => 'Операции из файла банка',
          'ask.places.inbox' => 'Входящие',
          'ask.places.inboxText' => 'Что ждёт решения после импорта',
          'ask.places.backup' => 'Данные',
          'ask.places.backupText' => 'Копия, восстановление и экспорт',
          'ask.places.help' => 'Помощь и отзыв',
          'ask.places.helpText' => 'Частые вопросы и письмо разработчику',
          'ask.places.notifications' => 'Уведомления',
          'ask.places.notificationsText' => 'Что сообщала Birka',
          'ask.places.reports' => 'Отчёты',
          'ask.places.reportsText' => 'Траты и доходы по месяцам',
          'ask.places.settings' => 'Ещё',
          'ask.places.settingsText' => 'Базовая валюта, начало месяца, язык',
          'ask.refused.advice' => 'Советов о вложениях и курсах не даю',
          'ask.refused.adviceText' =>
            'Birka считает ваши деньги, но не предсказывает курсы и не говорит, что покупать.',
          'ask.refused.offTopic' => 'Отвечаю только про ваши деньги',
          'ask.refused.offTopicText' =>
            'Спросите про траты, доходы, счета, платежи или настройки Birka.',
          'ask.refused.unknown' => 'Не понял вопрос',
          'ask.refused.unknownText' =>
            'Попробуйте короче: что, когда и сколько. Например, «кафе в октябре».',
          'ask.refused.suggest' => 'Можно спросить так',
          'ask.refused.write' => 'Написать разработчику',
          'ask.refused.writeText' => 'Расскажите, что хотели узнать',
          'ask.suggest.capital' => 'Сколько у меня денег',
          'ask.suggest.rate' => 'Курс доллара',
          'ask.suggest.allowance' => 'Сколько можно тратить',
          'ask.suggest.payments' => 'Когда следующий платёж',
          'ask.suggest.income' => 'Доходы в прошлом месяце',
          'ask.suggest.expenses' => 'Траты в этом месяце',
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
                  zero: '${count} операций',
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
                  zero: '${count} счетов',
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
                  zero: '${n} подкатегорий',
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
          'categories.howTitle' => 'Как это устроено',
          'categories.how.0' =>
            'Нажмите категорию — она откроется здесь, рядом со списком.',
          'categories.how.1' =>
            'Расходы и доходы — отдельные списки: переключатель над ними.',
          'categories.how.2' =>
            'Категории видны в операциях, отчётах и регулярных платежах.',
          'debts.title' => 'Долги',
          'debts.toMore' => 'Ещё',
          'debts.close' => 'Закрыть',
          'debts.done' => 'Готово',
          'debts.foldClosed' => 'Показать закрытые',
          'debts.moreHint' => 'Кто кому должен и до какого дня',
          'debts.moreBoth' =>
            ({required Object owed, required Object mine}) =>
                'Мне должны ${owed} · мои ${mine}',
          'debts.moreOwed' => ({required Object owed}) => 'Мне должны ${owed}',
          'debts.moreMine' => ({required Object mine}) => 'Мои долги ${mine}',
          'debts.owedToMe' => 'Мне должны',
          'debts.myDebts' => 'Мои долги',
          'debts.people' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} человек',
                  one: '${n} человек',
                  few: '${n} человека',
                  many: '${n} человек',
                  other: '${n} человека',
                ),
          'debts.closed' => ({required Object n}) => 'Закрытые · ${n}',
          'debts.caption' =>
            'Долги не входят в капитал: этих денег сейчас нет на ваших счетах.',
          'debts.captionRates' =>
            'Долги не входят в капитал: этих денег сейчас нет на ваших счетах. Другие валюты — по курсу ЦБ на сегодня.',
          'debts.failed' => 'Не удалось прочитать долги.',
          'debts.gone' => 'Этого долга больше нет.',
          'debts.emptyTitle' => 'Долгов нет',
          'debts.emptyText' =>
            'Запишите, кому одолжили или у кого заняли: Birka покажет, сколько осталось и до какого дня.',
          'debts.add' => 'Записать долг',
          'debts.newDebt' => 'Новый долг',
          'debts.line.dueToday' => 'срок сегодня',
          'debts.line.dueOn' => ({required Object day}) => 'до ${day}',
          'debts.line.overdue' => ({required Object day}) => 'срок был ${day}',
          'debts.line.since' => ({required Object day}) => 'с ${day}',
          'debts.line.returned' => ({required Object day}) => 'вернули ${day}',
          'debts.line.repaid' => ({required Object day}) => 'отдали ${day}',
          'debts.line.of' => ({required Object total}) => 'из ${total}',
          'debts.line.approx' => ({required Object amount}) => '≈ ${amount}',
          'debts.card.title' => 'Долг',
          'debts.card.edit' => 'Изменить',
          'debts.card.leftToMe' =>
            ({required Object total}) => 'осталось вернуть вам из ${total}',
          'debts.card.leftToThem' =>
            ({required Object total}) => 'осталось отдать из ${total}',
          'debts.card.allReturned' =>
            ({required Object day}) => 'вернули всё · ${day}',
          'debts.card.allRepaid' =>
            ({required Object day}) => 'отдали всё · ${day}',
          'debts.card.returned' =>
            ({required Object amount}) => 'Вернули ${amount}',
          'debts.card.repaid' =>
            ({required Object amount}) => 'Отдали ${amount}',
          'debts.card.dueRemind' =>
            ({required Object day}) => 'Срок ${day} · напомним в этот день',
          'debts.card.dueIn' =>
            ({required Object day, required Object inDays}) =>
                'Срок ${day} · ${inDays}',
          'debts.card.dueOn' => ({required Object day}) => 'Срок ${day}',
          'debts.card.dueToday' => 'Срок сегодня',
          'debts.card.dueWas' => ({required Object day}) => 'Срок был ${day}',
          'debts.card.noDue' => 'Без срока',
          'debts.card.closed' => 'Долг закрыт',
          'debts.card.closedRemind' => 'Долг закрыт · напоминание снято',
          'debts.card.history' => 'История',
          'debts.card.returnAction' => 'Возврат',
          'debts.card.repayAction' => 'Отдать',
          'debts.card.lendMore' => 'Ещё в долг',
          'debts.card.borrowMore' => 'Занять ещё',
          'debts.card.newDebt' => 'Новый долг',
          'debts.inDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'через ${n} дней',
                  one: 'через ${n} день',
                  few: 'через ${n} дня',
                  many: 'через ${n} дней',
                  other: 'через ${n} дня',
                ),
          'debts.form.lend' => 'Одолжить',
          'debts.form.borrow' => 'Занять',
          'debts.form.who' => 'Кто',
          'debts.form.other' => 'Другой',
          'debts.form.name' => 'Имя',
          'debts.form.nameHint' => 'Как зовут',
          'debts.form.nameMissing' => 'Напишите, кто это',
          'debts.form.amount' => 'Сумма',
          'debts.form.fromAccount' => 'Со счёта',
          'debts.form.toAccount' => 'На счёт',
          'debts.form.when' => 'Когда',
          'debts.form.dueBy' => 'Вернуть до',
          'debts.form.noDue' => 'Без срока',
          'debts.form.note' => 'Заметка',
          'debts.form.noteHint' => 'Необязательно',
          'debts.form.remind' => 'Напомнить в срок',
          'debts.form.lendCaption' =>
            'Долг — не трата: деньги уйдут со счёта, но в расходы месяца не попадут.',
          'debts.form.borrowCaption' =>
            'Долг — не доход: деньги придут на счёт, но в доходы месяца не попадут.',
          'debts.form.noAccount' =>
            ({required Object currency}) =>
                'Долг в ${currency}, а счёта в этой валюте нет.',
          'debts.form.save' => 'Сохранить',
          'debts.form.saved' =>
            ({required Object name, required Object amount}) =>
                'Записали: ${name}, ${amount}',
          'debts.form.failed' => 'Не удалось сохранить. Попробуйте ещё раз.',
          'debts.form.moreTitle' =>
            ({required Object name}) => 'Ещё в долг · ${name}',
          'debts.form.borrowMoreTitle' =>
            ({required Object name}) => 'Занять ещё · ${name}',
          'debts.form.dueChoices.none' => 'Без срока',
          'debts.form.dueChoices.week' => 'Через неделю',
          'debts.form.dueChoices.twoWeeks' => 'Через две недели',
          'debts.form.dueChoices.month' => 'Через месяц',
          'debts.form.dueChoices.pick' => 'Выбрать день',
          'debts.form.today' => 'Сегодня',
          'debts.form.editTitle' => 'Изменить долг',
          'debts.back.returnTitle' =>
            ({required Object name}) => 'Возврат · ${name}',
          'debts.back.repayTitle' =>
            ({required Object name}) => 'Отдать · ${name}',
          'debts.back.all' => ({required Object amount}) => 'Всё · ${amount}',
          'debts.back.part' => 'Часть',
          'debts.back.howMuchReturned' => 'Сколько вернули',
          'debts.back.howMuchRepaid' => 'Сколько отдали',
          'debts.back.tooMuch' => 'Больше, чем осталось',
          'debts.back.returnClosing' =>
            'Долг закроется. Деньги придут на счёт, но не в доходы.',
          'debts.back.returnClosingRemind' =>
            'Долг закроется, и напоминание о нём уйдёт. Деньги придут на счёт, но не в доходы.',
          'debts.back.returnLeft' =>
            ({required Object left}) =>
                'Останется ${left}. Деньги придут на счёт, но не в доходы.',
          'debts.back.returnLeftDue' =>
            ({required Object left, required Object day}) =>
                'Останется ${left} до ${day}. Деньги придут на счёт, но не в доходы.',
          'debts.back.repayClosing' =>
            'Долг закроется. Деньги уйдут со счёта, но не в расходы.',
          'debts.back.repayClosingRemind' =>
            'Долг закроется, и напоминание о нём уйдёт. Деньги уйдут со счёта, но не в расходы.',
          'debts.back.repayLeft' =>
            ({required Object left}) =>
                'Останется ${left}. Деньги уйдут со счёта, но не в расходы.',
          'debts.back.repayLeftDue' =>
            ({required Object left, required Object day}) =>
                'Останется ${left} до ${day}. Деньги уйдут со счёта, но не в расходы.',
          'debts.back.save' => 'Сохранить возврат',
          'debts.back.closedToast' =>
            ({required Object name}) => '${name}: долг закрыт',
          'debts.back.returnedToast' =>
            ({required Object amount, required Object left}) =>
                'Возврат ${amount} · осталось ${left}',
          'debts.back.repaidToast' =>
            ({required Object amount, required Object left}) =>
                'Отдали ${amount} · осталось ${left}',
          'debts.steps.first' =>
            'Запишите, кому одолжили и у кого заняли: деньги уйдут со счёта или придут на него.',
          'debts.steps.second' =>
            'Долг — не трата и не доход: в отчёты месяца он не попадёт.',
          'debts.steps.third' =>
            'Возвраты закрывают долг частями, и список покажет, сколько осталось и до какого дня.',
          'debts.howItWorks' => 'Как это устроено',
          'debts.move.lent' => 'В долг',
          'debts.move.returned' => 'Возврат',
          'debts.move.borrowed' => 'Заняли',
          'debts.move.repaid' => 'Отдали',
          'debts.person.newTitle' => 'Новый человек',
          'debts.person.fromContacts' => 'Выбрать из контактов',
          'debts.person.fromContactsNote' => 'Имя и номер подставятся сами',
          'debts.person.about' => 'Кто это',
          'debts.person.aboutHint' => 'Необязательно · коллега, сосед',
          'debts.person.phone' => 'Телефон',
          'debts.person.optional' => 'Необязательно',
          'debts.person.number' => 'Номер',
          'debts.person.noNumber' => 'Без номера',
          'debts.person.noNumberNote' =>
            'Напомнить можно будет через другое приложение',
          'debts.person.hint' =>
            'Имя видно в списке и в напоминаниях. «Кто это» поможет различить тёзок.',
          'debts.person.fromContact' =>
            ({required Object contact}) =>
                'Из контактов: ${contact}. Birka взяла только этот контакт, а номер хранит на этом телефоне.',
          'debts.person.contactsRow' => 'Взять номер из контактов',
          'debts.person.shared' =>
            'Имя, «кто это» и номер — общие для всех долгов этого человека. Номер хранится только на этом телефоне и в ваших копиях.',
          'debts.person.twin' =>
            ({required Object name, required Object about}) =>
                '${name} уже есть — ${about}. Напишите, кто это, чтобы их различать.',
          'debts.person.twinPlain' =>
            ({required Object name}) =>
                '${name} уже есть. Напишите, кто это, чтобы их различать.',
          'debts.person.twinPick' =>
            ({required Object name, required Object about}) =>
                '${name} уже есть — ${about}. Если это тот же человек, выберите его выше; если другой — напишите, кто это.',
          'debts.person.twinPickPlain' =>
            ({required Object name}) =>
                '${name} уже есть. Если это тот же человек, выберите его выше; если другой — напишите, кто это.',
          'debts.remind.action' => 'Напомнить',
          'debts.remind.title' => 'Напомнить',
          'debts.remind.message' => 'Сообщение',
          'debts.remind.sms' => 'Отправить SMS',
          'debts.remind.otherApp' => 'Другое приложение',
          'debts.remind.share' => 'Поделиться',
          'debts.remind.caption' =>
            'Birka только откроет сообщение, а отправите его вы. Текст можно поправить.',
          'debts.remind.captionShare' =>
            'Birka откроет окно «Поделиться»: выберите, где написать. Текст можно поправить.',
          'debts.remind.noPhone' => 'Номера нет · добавьте в «Изменить»',
          'debts.remind.text' =>
            ({required Object amount, required Object day}) =>
                'Привет! Напоминаю про ${amount} — договаривались вернуть до ${day}.',
          'debts.remind.textNoDue' =>
            ({required Object amount}) => 'Привет! Напоминаю про ${amount}.',
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
          'demo.people.masha' => 'Маша',
          'demo.people.dima' => 'Дима',
          'demo.people.sasha' => 'Саша',
          'demo.people.ira' => 'Ира',
          'demo.people.dad' => 'Папа',
          'demo.debtNotes.tickets' => 'на билеты',
          'demo.debtNotes.flat' => 'за квартиру',
          'demo.debtNotes.salary' => 'до зарплаты',
          'demo.debtNotes.concert' => 'на концерт',
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
          _ => null,
        } ??
        switch (path) {
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
                  zero: '${count} операций',
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
                  zero: '${count} счетов',
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
                  zero: 'Убрать ${count} операций этого файла?',
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
              zero:
                  'Совпали ${n} колонок из ${total}. По ним Birka разберёт файл, а вы проверите результат на следующем шаге.',
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
                  zero: 'Импортировать ${count} операций',
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
                  zero: '${count} строк не прочитались',
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
                  zero: '${count} операций уже есть в учёте',
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
                  zero: '${count} операций не попадут в учёт',
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
                  zero: 'Добавили ${count} операций',
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
                  zero: '${count} ждут вашего решения во «Входящих»',
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
              zero:
                  'Отмена уберёт ${count} операций этого файла. Ваши записи и другие импорты останутся. Отменить можно и позже, в «Прошлых импортах».',
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
                  zero: '${count} колонок',
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
                  zero: '${count} строк',
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
                  zero: '${count} категорий в выписке',
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
          'imports.categoriesDone' =>
            ({required Object count}) => 'Готово · ${count} во «Входящих»',
          'imports.categoriesKept' =>
            ({required Object source}) =>
                'Выбор запомним для выписок ${source}',
          'imports.foundHeading' => 'Регулярные платежи',
          'imports.foundLine' =>
            ({required Object count, required Object names}) =>
                'нашли ${count}: ${names}',
          'imports.foundDone' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Провели ${count} платежей',
                  one: 'Провели ${count} платёж',
                  few: 'Провели ${count} платежа',
                  many: 'Провели ${count} платежей',
                  other: 'Провели ${count} платежа',
                ),
          'imports.foundDoneText' =>
            ({required Object names}) => '${names} — из выписки',
          'imports.repeatsTitle' =>
            ({required Object count}) => 'Похоже на регулярные · ${count}',
          'imports.namesAnd' =>
            ({required Object names, required Object last}) =>
                '${names} и ${last}',
          'imports.rowsLeft' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${count} строк не попадут в учёт',
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
                  zero: '${count} не прочитались',
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
                  zero: '${count} не прошли в банке',
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
                  zero: '${count} не подходят счёту',
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
                  zero: 'остальные ${count} в порядке',
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
                  zero: '${count} строк из ${total} не прочитались',
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
                  zero: '${count} операций не прошли в банке',
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
                  zero: '${count} ждут решения',
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
                  zero: 'так вы отметили его ${count} раз ${when}',
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
                  zero: 'и ещё ${count} операций',
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
                  zero: 'Выбрано ${count} операций',
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
                  zero: '${count} ждут решения во «Входящих»',
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
                  zero: '${count} переводов между счетами',
                  one: '${count} перевод между счетами',
                  few: '${count} перевода между счетами',
                  many: '${count} переводов между счетами',
                  other: '${count} перевода между счетами',
                ),
          'inbox.entryBoth' =>
            ({required Object first, required Object second}) =>
                '${first} и ${second}',
          'inbox.unpick' => 'Снять',
          'notifications.title' => 'Уведомления',
          'notifications.back' => 'Назад',
          'notifications.bell' => 'Уведомления',
          'notifications.bellNew' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Уведомления, ${count} новых',
                  one: 'Уведомления, ${count} новое',
                  few: 'Уведомления, ${count} новых',
                  many: 'Уведомления, ${count} новых',
                  other: 'Уведомления, ${count} нового',
                ),
          'notifications.fresh' =>
            ({required Object count}) => 'Новые · ${count}',
          'notifications.readAll' => 'Прочитать все',
          'notifications.subtitleNew' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${count} новых · история за 90 дней',
                  one: '${count} новое · история за 90 дней',
                  few: '${count} новых · история за 90 дней',
                  many: '${count} новых · история за 90 дней',
                  other: '${count} нового · история за 90 дней',
                ),
          'notifications.subtitleRead' => 'Всё прочитано · история за 90 дней',
          'notifications.filters.all' => 'Все',
          'notifications.filters.payment' => 'Платежи',
          'notifications.filters.debt' => 'Долги',
          'notifications.filters.import' => 'Импорт',
          'notifications.filtersLabel' => 'Чьи уведомления',
          'notifications.emptyTitle' => 'Пока тихо',
          'notifications.emptyText' =>
            'Здесь появятся напоминания о платежах и сроках долгов и итоги импорта.',
          'notifications.emptyImports' =>
            'Здесь появятся итоги импорта выписок.',
          'notifications.failed' => 'Не удалось прочитать уведомления.',
          'notifications.keeps' => 'Birka хранит уведомления 90 дней',
          'notifications.yesterday' => 'вчера',
          'notifications.tomorrow' =>
            ({required Object date}) => 'Завтра, ${date}',
          'notifications.waitsToday' => 'Сегодня, ждёт подтверждения',
          'notifications.waits' => 'Ждёт подтверждения',
          'notifications.postsToday' => 'Сегодня, проведётся сам',
          'notifications.posts' => 'Проведётся сам',
          'notifications.posted' =>
            ({required Object time}) => 'Провели в ${time}',
          'notifications.postedOn' =>
            ({required Object date}) => 'Провели ${date}',
          'notifications.postedItself' => 'Провёлся сам',
          'notifications.skipped' =>
            ({required Object date}) => 'Пропустили · следующий ${date}',
          'notifications.found' => 'Нашли в выписке',
          'notifications.importTitle' =>
            ({required Object bank, required Object period}) =>
                '${bank} · ${period}',
          'notifications.importWaiting' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} из ${count} ждут во «Входящих»',
                  one: '${n} из ${count} ждёт во «Входящих»',
                  few: '${n} из ${count} ждут во «Входящих»',
                  many: '${n} из ${count} ждут во «Входящих»',
                  other: '${n} из ${count} ждут во «Входящих»',
                ),
          'notifications.importAdded' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Добавили ${count} операций',
                  one: 'Добавили ${count} операцию',
                  few: 'Добавили ${count} операции',
                  many: 'Добавили ${count} операций',
                  other: 'Добавили ${count} операции',
                ),
          'notifications.importUndone' => 'Импорт отменён',
          'notifications.debtTitle' =>
            ({required Object name, required Object amount}) =>
                'Срок · ${name}, ${amount}',
          'notifications.debtTitleToday' =>
            ({required Object name, required Object amount}) =>
                'Срок сегодня · ${name}, ${amount}',
          'notifications.debtSince' => ({required Object date}) => 'с ${date}',
          'notifications.debtNoteSince' =>
            ({required Object note, required Object date}) =>
                '${note} · с ${date}',
          'notifications.debtReturned' =>
            ({required Object date}) => 'Вернули ${date}',
          'notifications.debtRepaid' =>
            ({required Object date}) => 'Отдали ${date}',
          'notifications.debtReturnedPart' =>
            ({required Object left}) => 'Вернули часть · осталось ${left}',
          'notifications.debtRepaidPart' =>
            ({required Object left}) => 'Отдали часть · осталось ${left}',
          'notifications.debtWaits' =>
            ({required Object left}) => 'Ещё не вернули · осталось ${left}',
          'notifications.debtWaitsRepaid' =>
            ({required Object left}) => 'Ещё не отдали · осталось ${left}',
          'notifications.debtGone' => 'Этого долга больше нет',
          'notifications.today' => 'сегодня',
          'notifications.months.0' => 'январь',
          'notifications.months.1' => 'февраль',
          'notifications.months.2' => 'март',
          'notifications.months.3' => 'апрель',
          'notifications.months.4' => 'май',
          'notifications.months.5' => 'июнь',
          'notifications.months.6' => 'июль',
          'notifications.months.7' => 'август',
          'notifications.months.8' => 'сентябрь',
          'notifications.months.9' => 'октябрь',
          'notifications.months.10' => 'ноябрь',
          'notifications.months.11' => 'декабрь',
          'notifications.howTitle' => 'Что сюда приходит',
          'notifications.how.0' =>
            '«Платежи» — регулярный платёж, который ждёт вашего «Провести».',
          'notifications.how.1' =>
            '«Импорт» — итоги выписок: что добавили и что ждёт во «Входящих».',
          'notifications.how.2' => '«Birka» — что нового в самой Birka.',
          'notifications.how.3' =>
            'Новые стоят сверху; прочитанные уходят в историю по дням.',
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
                  zero: '${n} категорий',
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
                  zero: '${n} валют',
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
          'reports.monthReport.0' => 'Отчёт за январь',
          'reports.monthReport.1' => 'Отчёт за февраль',
          'reports.monthReport.2' => 'Отчёт за март',
          'reports.monthReport.3' => 'Отчёт за апрель',
          'reports.monthReport.4' => 'Отчёт за май',
          _ => null,
        } ??
        switch (path) {
          'reports.monthReport.5' => 'Отчёт за июнь',
          'reports.monthReport.6' => 'Отчёт за июль',
          'reports.monthReport.7' => 'Отчёт за август',
          'reports.monthReport.8' => 'Отчёт за сентябрь',
          'reports.monthReport.9' => 'Отчёт за октябрь',
          'reports.monthReport.10' => 'Отчёт за ноябрь',
          'reports.monthReport.11' => 'Отчёт за декабрь',
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
          'schedules.leftAfterPaydayAdvance' =>
            ({required Object date, required Object amount}) =>
                'К зарплате ${date} на счетах останется ≈ ${amount} с авансом, если не считать ежедневных трат.',
          'schedules.leftAfterMonthAdvance' =>
            ({required Object amount}) =>
                'К концу месяца на счетах останется ≈ ${amount} с авансом, если не считать ежедневных трат.',
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
                  zero: '${n} дней',
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
                  zero: '${n} платежей до зарплаты',
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
                  zero: '${n} платежей до конца месяца',
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
                  zero: 'Остаётся на ${n} дней',
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
          'schedules.advance' => 'Аванс',
          'schedules.everyTwice' =>
            ({required Object advance, required Object day}) =>
                'аванс ${advance}-го и зарплата ${day}-го',
          'schedules.advancePosted' =>
            ({required Object date}) =>
                'аванс проведён сегодня · зарплата ${date}',
          'schedules.advanceSkipped' =>
            ({required Object date}) => 'аванс пропущен · зарплата ${date}',
          'schedules.advanceFound' =>
            ({required Object date}) =>
                'аванс нашли в выписке · зарплата ${date}',
          'schedules.restPosted' =>
            ({required Object date}) =>
                'зарплата проведена сегодня · аванс ${date}',
          'schedules.restSkipped' =>
            ({required Object date}) => 'зарплата пропущена · аванс ${date}',
          'schedules.restFound' =>
            ({required Object date}) =>
                'зарплату нашли в выписке · аванс ${date}',
          'schedules.advanceOn' => ({required Object date}) => 'Аванс ${date}',
          'schedules.nearEnough' =>
            ({
              required Object date,
              required Object amount,
              required Object days,
            }) => 'До аванса ${date} хватает: ${amount} на ${days}',
          'schedules.nearShort' =>
            ({required Object date, required Object amount}) =>
                'До аванса ${date} не хватает ${amount}',
          'schedules.paydayTwice' => 'Аванс и зарплата',
          'schedules.paydayTwiceDays' =>
            ({required Object advance, required Object day}) =>
                '${advance}-го и ${day}-го',
          'schedules.partsTitle' => 'Как приходит',
          'schedules.parts.one' => 'Одной суммой',
          'schedules.parts.two' => 'С авансом',
          'schedules.partsOne' => 'Вся сумма приходит в один день.',
          'schedules.partsTwo' =>
            ({required Object advance, required Object day}) =>
                'Пополам: аванс ${advance}-го, зарплата ${day}-го.',
          'schedules.partsOwn' =>
            ({
              required Object advanceAmount,
              required Object advance,
              required Object restAmount,
              required Object day,
            }) =>
                'Аванс ${advanceAmount} ${advance}-го, зарплата ${restAmount} ${day}-го.',
          'schedules.amountMonthly' => 'Сумма в месяц',
          'schedules.halves' =>
            ({required Object amount}) => 'по ${amount} авансом и зарплатой',
          'schedules.halvesOwn' =>
            ({required Object advance, required Object rest}) =>
                'аванс ${advance} и зарплата ${rest}',
          'schedules.halvesUneven' =>
            'Сумма не делится пополам — поправьте копейки',
          'schedules.advanceDay' => 'Аванс',
          'schedules.restDay' => 'Зарплата',
          'schedules.advanceAmount' => 'Сумма аванса',
          'schedules.advanceHalf' => 'половина',
          'schedules.advanceRest' =>
            ({required Object amount, required Object day}) =>
                'Зарплатой придёт остальное: ${amount} ${day}-го.',
          'schedules.advanceHalfChip' =>
            ({required Object amount}) => 'Пополам · ${amount}',
          'schedules.nextAdvance' =>
            ({required Object date}) => 'аванс, ${date}',
          'schedules.monthStartHint' =>
            ({
              required Object day,
              required Object month,
              required Object from,
              required Object to,
            }) =>
                'Зарплата приходит ${day}-го: месяц можно начинать с этого дня, тогда ${month} — с ${from} по ${to}.',
          'schedules.remindTitle' => 'Напоминания',
          'schedules.remindNotify' => 'Уведомления от Birka',
          'schedules.remindNotifyOff' => 'пока Birka на телефоне',
          'schedules.remindNotifyOn' =>
            ({required num n, required Object time}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} платежей · в ${time}',
                  one: '${n} платёж · в ${time}',
                  few: '${n} платежа · в ${time}',
                  many: '${n} платежей · в ${time}',
                  other: '${n} платежей · в ${time}',
                ),
          'schedules.remindNotifyDebts' =>
            ({required num n, required Object time}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} долгов · в ${time}',
                  one: '${n} долг · в ${time}',
                  few: '${n} долга · в ${time}',
                  many: '${n} долгов · в ${time}',
                  other: '${n} долгов · в ${time}',
                ),
          'schedules.remindNotifyBoth' =>
            ({
              required Object payments,
              required Object debts,
              required Object time,
            }) => '${payments} и ${debts} · в ${time}',
          'schedules.remindPayments' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} платежей',
                  one: '${n} платёж',
                  few: '${n} платежа',
                  many: '${n} платежей',
                  other: '${n} платежей',
                ),
          'schedules.remindDebtCount' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} долгов',
                  one: '${n} долг',
                  few: '${n} долга',
                  many: '${n} долгов',
                  other: '${n} долгов',
                ),
          'schedules.remindNotifyDenied' => 'нет доступа к уведомлениям',
          'schedules.remindCalendar' => 'События в календаре',
          'schedules.remindCalendarOn' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'календарь «Birka» · ${n} событий',
                  one: 'календарь «Birka» · ${n} событие',
                  few: 'календарь «Birka» · ${n} события',
                  many: 'календарь «Birka» · ${n} событий',
                  other: 'календарь «Birka» · ${n} событий',
                ),
          'schedules.remindCalendarOff' => 'напомнит и без Birka',
          'schedules.remindCalendarDenied' => 'нет доступа к календарю',
          'schedules.remindTime' => 'Время',
          'schedules.remindSums' => 'Суммы в напоминаниях',
          'schedules.remindSumsNote' => 'на экране блокировки и в календаре',
          'schedules.remindNoteOff' =>
            'Напомнить можно в день платежа или накануне: это выбирается у каждого платежа. О долге Birka напомнит в день срока.',
          'schedules.remindNoteOn' =>
            'Удалите Birka — напоминания исчезнут вместе с ней. Календарь напомнит и без неё.',
          'schedules.remindNoteDenied' =>
            'Чтобы Birka напоминала, разрешите ей уведомления в настройках телефона.',
          'schedules.remindNoteCalendar' =>
            'Если календарь синхронизируется с iCloud или Google, названия и суммы платежей попадут туда.',
          'schedules.remindNoteBoth' =>
            'О платеже напомнят дважды: Birka и календарь.',
          'schedules.remindNoteCalendarDenied' =>
            'Чтобы календарь напоминал, откройте ему доступ в настройках телефона.',
          'schedules.remindAskTitle' => 'Напоминания от Birka',
          'schedules.remindAskText' =>
            ({required Object time}) =>
                'Birka напомнит о платеже в ${time} — в день платежа или накануне, как выбрано у платежа. Напоминания ставятся на этом телефоне, сервер для них не нужен.',
          'schedules.remindAskExample' =>
            ({required Object date, required Object time}) =>
                '${date}, ${time} · нажмёте — откроется платёж',
          'schedules.remindAskLocalTitle' => 'Живут вместе с Birka',
          'schedules.remindAskLocalText' =>
            'Удалите приложение — исчезнут и напоминания. Календарь напомнит и без него.',
          'schedules.remindAllow' => 'Разрешить уведомления',
          'schedules.remindNotNow' => 'Не сейчас',
          'schedules.remindCalendarAskText' =>
            'Birka заведёт календарь «Birka» и добавит в него регулярные платежи. Напоминать будет сам календарь — даже если удалить Birka.',
          'schedules.remindCalendarAskOwnTitle' => 'Календарь «Birka»',
          'schedules.remindCalendarAskOwn' =>
            ({required num n, required Object time}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} платежей · напомнит в ${time}',
                  one: '${n} платёж · напомнит в ${time}',
                  few: '${n} платежа · напомнит в ${time}',
                  many: '${n} платежей · напомнит в ${time}',
                  other: '${n} платежей · напомнит в ${time}',
                ),
          'schedules.remindCalendarAskSyncTitle' =>
            'Если календарь синхронизируется',
          'schedules.remindCalendarAskSyncText' =>
            'Названия и суммы платежей попадут в iCloud или Google. Суммы можно убрать в настройках.',
          'schedules.remindCalendarAskOthersTitle' =>
            'Чужие события Birka не читает',
          'schedules.remindCalendarAskOthersText' =>
            'Телефон спросит полный доступ: без него Birka не сможет менять и удалять свои события.',
          'schedules.remindCalendarAllow' => 'Разрешить доступ к календарю',
          'schedules.remindCalendarRemoveTitle' => 'Убрать календарь «Birka»?',
          'schedules.remindCalendarRemoveText' =>
            ({
              required num n,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              zero:
                  'Календарь «Birka» и ${n} событий в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
              one:
                  'Календарь «Birka» и ${n} событие в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
              few:
                  'Календарь «Birka» и ${n} события в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
              many:
                  'Календарь «Birka» и ${n} событий в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
              other:
                  'Календарь «Birka» и ${n} событий в нём исчезнут с телефона, и календарь перестанет напоминать о платежах. Другие календари не изменятся.',
            ),
          'schedules.remindCalendarRemove' => 'Убрать календарь',
          'schedules.remindCalendarDeniedTitle' => 'Нет доступа к календарю',
          'schedules.remindCalendarDeniedText' =>
            'Доступ выключен в настройках телефона. Откройте «Настройки» → «Birka» → «Календари» и выберите «Полный доступ».',
          'schedules.remindCalendarOnToast' => 'Платежи в календаре «Birka»',
          'schedules.remindCalendarOffToast' => 'Календарь «Birka» убран',
          'schedules.remindDeniedTitle' => 'Нет доступа к уведомлениям',
          'schedules.remindDeniedText' =>
            'Уведомления Birka выключены в настройках телефона. Откройте «Настройки» → «Birka» → «Уведомления» и включите их.',
          'schedules.remindOpenSettings' => 'Открыть настройки',
          'schedules.remindCancel' => 'Отмена',
          'schedules.remindOnTitle' => 'Напоминания включены',
          'schedules.remindOnText' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Birka напомнит о ${n} платежах',
                  one: 'Birka напомнит о ${n} платеже',
                  few: 'Birka напомнит о ${n} платежах',
                  many: 'Birka напомнит о ${n} платежах',
                  other: 'Birka напомнит о ${n} платежах',
                ),
          'schedules.remindOnNone' => 'Отметьте «Напомнить» у платежей',
          'schedules.remindToday' =>
            'Сегодня. Нажмите, чтобы провести или пропустить.',
          'schedules.remindTodayAuto' => 'Сегодня, проведётся само.',
          'schedules.remindTomorrow' =>
            ({required Object date}) =>
                'Завтра, ${date}. Нажмите, чтобы открыть платёж.',
          'schedules.remindDebtTitle' =>
            ({required Object name, required Object amount}) =>
                'Срок сегодня · ${name}, ${amount}',
          'schedules.remindDebtTitleNoSum' =>
            ({required Object name}) => 'Срок сегодня · ${name}',
          'schedules.remindDebtLent' =>
            'Сегодня вам должны вернуть долг. Нажмите, чтобы открыть его.',
          'schedules.remindDebtBorrowed' =>
            'Сегодня срок отдать долг. Нажмите, чтобы открыть его.',
          'schedules.remindChannel' => 'Напоминания о платежах и долгах',
          'schedules.remindChannelNote' =>
            'Регулярные платежи в их день или накануне и сроки долгов',
          'schedules.remindSection' => 'Напомнить',
          'schedules.reminder.onDay' => 'В день',
          'schedules.reminder.dayBefore' => 'За день',
          'schedules.reminder.none' => 'Не напоминать',
          'schedules.remindLine' =>
            ({
              required Object date,
              required Object time,
              required Object who,
            }) => '${date} в ${time} · ${who}',
          'schedules.remindByBirka' => 'напомнит Birka',
          'schedules.remindByCalendar' => 'напомнит календарь «Birka»',
          'schedules.remindByBoth' => 'напомнят Birka и календарь',
          'schedules.remindLineNone' => 'Без напоминания',
          'schedules.remindLineOff' => 'Напоминания выключены в «Ещё»',
          'schedules.remindEnable' => 'Включить напоминания',
          'schedules.makeRegular' => 'Сделать регулярным',
          'schedules.makeRegularLine' =>
            ({required Object every}) => 'Повторять ${every}',
          'schedules.regularPayment' => 'Регулярный платёж',
          'schedules.fromOperation' =>
            ({required Object date}) => 'Из операции ${date}',
          'schedules.madeRegular' =>
            ({required Object name}) => 'Добавили в регулярные: «${name}»',
          'schedules.findsTitle' => 'Похоже на регулярные',
          'schedules.findsTitleEmpty' => 'Нашли в ваших операциях',
          'schedules.findsNote' =>
            'Повторялись каждый месяц. Нажмите, чтобы добавить, или ✕, если повтор случайный.',
          'schedules.findLine' =>
            ({required num n, required Object day, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${day}-го · ${count} раз подряд',
                  one: '${day}-го · ${count} раз подряд',
                  few: '${day}-го · ${count} раза подряд',
                  many: '${day}-го · ${count} раз подряд',
                  other: '${day}-го · ${count} раза подряд',
                ),
          'schedules.findLineVaries' =>
            ({required num n, required Object day, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'около ${day}-го · ${count} раз',
                  one: 'около ${day}-го · ${count} раз',
                  few: 'около ${day}-го · ${count} раза',
                  many: 'около ${day}-го · ${count} раз',
                  other: 'около ${day}-го · ${count} раза',
                ),
          'schedules.findDismiss' =>
            ({required Object name}) => 'Не регулярный: ${name}',
          'schedules.findDismissed' =>
            ({required Object name}) => 'Не будем предлагать «${name}»',
          'schedules.findRestore' => 'Вернуть',
          'schedules.foundIn' =>
            ({required num n, required Object count}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Нашли в операциях · ${count} раз',
                  one: 'Нашли в операциях · ${count} раз',
                  few: 'Нашли в операциях · ${count} раза',
                  many: 'Нашли в операциях · ${count} раз',
                  other: 'Нашли в операциях · ${count} раза',
                ),
          'schedules.amountRange' =>
            ({required Object min, required Object max}) =>
                'последняя сумма · бывало от ${min} до ${max}',
          'schedules.forecast' => 'Если тратить как обычно',
          'schedules.forecastRunsOut' =>
            ({required Object date}) => 'Деньги кончатся ${date}',
          'schedules.forecastLastsPayday' => 'Хватит до зарплаты',
          'schedules.forecastLastsMonth' => 'Хватит до конца месяца',
          'schedules.forecastNone' => 'Денег не хватает уже сейчас',
          'schedules.forecastNonePayday' =>
            'Платежи до зарплаты больше, чем на счетах.',
          'schedules.forecastNoneMonth' =>
            'Платежи до конца месяца больше, чем на счетах.',
          'schedules.forecastShortText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object amount,
            }) =>
                'Обычно вы тратите ≈ ${usual} в день, а можно ${perDay}. К ${date} не хватит ≈ ${amount}.',
          'schedules.forecastLeftText' =>
            ({
              required Object usual,
              required Object date,
              required Object amount,
            }) =>
                'Обычно вы тратите ≈ ${usual} в день: к ${date} останется ≈ ${amount}.',
          'schedules.forecastToday' => 'сегодня',
          'schedules.forecastPayday' =>
            ({required Object date}) => '${date} · зарплата',
          'schedules.forecastUsual' => 'как обычно',
          'schedules.forecastPlan' =>
            ({required Object amount}) => 'по плану: ${amount} в день',
          'schedules.forecastPlanBare' => 'по плану',
          'schedules.forecastNote' =>
            'Обычные траты — среднее за 3 месяца по этим счетам, без регулярных платежей и переводов.',
          'schedules.forecastLineRunsOut' =>
            ({required Object date}) => 'Как обычно — деньги кончатся ${date}',
          'schedules.forecastLinePayday' => 'Как обычно — хватит до зарплаты',
          'schedules.forecastLineMonth' =>
            'Как обычно — хватит до конца месяца',
          'schedules.forecastAdvanceLastsText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object end,
              required Object amount,
            }) =>
                'Обычно вы тратите ≈ ${usual} в день, а до аванса можно ${perDay}. После аванса ${date} хватит: к ${end} останется ≈ ${amount}.',
          'schedules.forecastAdvanceAgainText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object again,
              required Object end,
              required Object amount,
            }) =>
                'Обычно вы тратите ≈ ${usual} в день, а до аванса можно ${perDay}. С авансом ${date} деньги кончатся снова ${again}, к ${end} не хватит ≈ ${amount}.',
          'schedules.forecastAdvanceShortText' =>
            ({
              required Object usual,
              required Object perDay,
              required Object date,
              required Object end,
              required Object amount,
            }) =>
                'Обычно вы тратите ≈ ${usual} в день, а до аванса можно ${perDay}. Аванса ${date} не хватит на эти дни: к ${end} не хватит ≈ ${amount}.',
          'schedules.forecastNoneAdvance' =>
            ({required Object date}) =>
                'До аванса ${date} платежи и отложенное больше, чем на счетах.',
          'schedules.forecastPlanAdvance' =>
            ({required Object amount}) =>
                'по плану: ${amount} в день до аванса',
          'schedules.forecastAdvance' =>
            ({required Object date}) => '${date} · аванс',
          'schedules.subtitleNext' =>
            ({required Object date, required Object count}) =>
                'Ближайший ${date} · ${count}',
          'schedules.subtitleToday' =>
            ({required num n, required Object date}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Сегодня ${date} · ${n} ждут подтверждения',
                  one: 'Сегодня ${date} · ${n} ждёт подтверждения',
                  few: 'Сегодня ${date} · ${n} ждут подтверждения',
                  many: 'Сегодня ${date} · ${n} ждут подтверждения',
                  other: 'Сегодня ${date} · ${n} ждут подтверждения',
                ),
          'schedules.subtitleNone' => 'Пока ни одного',
          'schedules.paymentsCount' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} платежей',
                  one: '${n} платёж',
                  few: '${n} платежа',
                  many: '${n} платежей',
                  other: '${n} платежей',
                ),
          'schedules.perDayTitle' => 'Можно тратить в день',
          'schedules.paidAheadPayday' =>
            ({required Object amount}) =>
                'Платежи до зарплаты уже вычтены: ${amount}.',
          'schedules.paidAheadMonth' =>
            ({required Object amount}) =>
                'Платежи до конца месяца уже вычтены: ${amount}.',
          'schedules.howTitle' => 'Как это устроено',
          'schedules.how.0' =>
            'Платёж стоит в плане на свой день — его уже нет в «Можно тратить сегодня».',
          'schedules.how.1' =>
            'В день платежа он ждёт вашего «Провести» или проводится сам — как выбрано в платеже.',
          'schedules.how.2' => 'Придёт в выписке банка — Birka не задвоит его.',
          'schedules.how.3' =>
            'Повторы в операциях Birka находит сама и предлагает добавить.',
          'schedules.failed' => 'Не удалось прочитать платежи.',
          'schedules.previewTitle' => 'В списке платежей',
          'schedules.previewNext' => 'Следующие разы',
          'schedules.cancel' => 'Отмена',
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
          'settings.monthStart' => 'Начало месяца',
          'settings.monthStartDay' => ({required Object day}) => '${day} число',
          'settings.monthStartNote' => 'для обзора и отчётов',
          'settings.monthStartCalendar' => 'как в календаре',
          'tags.title' => 'Метки',
          'tags.back' => 'Назад',
          'tags.add' => 'Новая метка',
          'tags.close' => 'Закрыть',
          'tags.edit' => 'Изменить',
          'tags.now' => 'Сейчас',
          'tags.trips' => 'Поездки',
          'tags.plain' => 'Метки',
          'tags.trip' => 'Поездка',
          'tags.tag' => 'Метка',
          'tags.note' => 'Суммы — расходы по курсу ЦБ на день каждой операции.',
          'tags.emptyTitle' => 'Меток пока нет',
          'tags.emptyText' =>
            'Отметьте поездку, ремонт или праздник — и увидите, сколько на них ушло, во всех валютах сразу.',
          'tags.failed' => 'Не удалось прочитать метки.',
          'tags.lastDay' => 'Последний день',
          'tags.dayOf' =>
            ({required Object day, required Object total}) =>
                'День ${day} из ${total}',
          'tags.days' =>
            ({required Object from, required Object to}) => '${from}–${to}',
          'tags.daysApart' =>
            ({required Object from, required Object to}) => '${from} — ${to}',
          'tags.inDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'через ${n} дней',
                  one: 'через ${n} день',
                  few: 'через ${n} дня',
                  many: 'через ${n} дней',
                  other: 'через ${n} дня',
                ),
          'tags.operations' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} операций',
                  one: '${n} операция',
                  few: '${n} операции',
                  many: '${n} операций',
                  other: '${n} операции',
                ),
          'tags.since' => ({required Object date}) => 'с ${date}',
          'tags.howItWorks' => 'Как это устроено',
          'tags.steps.first' =>
            'Метка собирает траты поездки или проекта во всех валютах — по курсу дня.',
          'tags.steps.second' =>
            'У поездки есть даты: расходы этих дней получают её метку сами, кроме регулярных платежей.',
          'tags.steps.third' =>
            'Билеты и жильё, купленные заранее, отметьте в карточке операции.',
          'tags.report.todayLast' => 'сегодня последний день',
          'tags.report.perDay' => 'На месте в день',
          'tags.report.perMonth' => 'В месяц',
          'tags.report.forDays' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'за ${n} дней',
                  one: 'за ${n} день',
                  few: 'за ${n} дня',
                  many: 'за ${n} дней',
                  other: 'за ${n} дня',
                ),
          'tags.report.count' => 'Операций',
          'tags.report.there' => ({required Object n}) => '${n} там',
          'tags.report.before' => ({required Object n}) => '${n} заранее',
          'tags.report.after' => ({required Object n}) => '${n} после',
          'tags.report.last' => ({required Object date}) => 'последняя ${date}',
          'tags.report.currencies' => 'Валюты',
          'tags.report.ratesNote' => 'По курсу ЦБ на день каждой операции.',
          'tags.report.onTheSpot' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: '${n} операций на месте',
                  one: '${n} операция на месте',
                  few: '${n} операции на месте',
                  many: '${n} операций на месте',
                  other: '${n} операции на месте',
                ),
          'tags.report.noRate' =>
            'Нет курса на день части операций — итог без них.',
          'tags.report.categories' => 'Категории',
          'tags.report.operations' => 'Операции',
          'tags.report.nothing' => 'На эту метку пока нет операций.',
          'tags.report.noCategory' => 'Без категории',
          'tags.form.newTitle' => 'Новая метка',
          'tags.form.trip' => 'Поездка',
          'tags.form.plain' => 'Метка',
          'tags.form.name' => 'Название',
          'tags.form.namePlaceholder' => 'Батуми',
          'tags.form.dates' => 'Даты',
          'tags.form.from' => 'С',
          'tags.form.to' => 'По',
          'tags.form.marks' => 'Отмечать расходы',
          'tags.form.marksOn' => 'За эти дни',
          'tags.form.marksOff' => 'Только вручную',
          'tags.form.marksAhead' =>
            'Расходы этих дней получат метку сами. Регулярные платежи не трогаем.',
          'tags.form.marksPast' =>
            ({
              required num n,
            }) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(
              n,
              zero:
                  'За эти дни уже ${n} расходов — отметим их сразу. Регулярные платежи не трогаем.',
              one:
                  'За эти дни уже ${n} расход — отметим его сразу. Регулярные платежи не трогаем.',
              few:
                  'За эти дни уже ${n} расхода — отметим их сразу. Регулярные платежи не трогаем.',
              many:
                  'За эти дни уже ${n} расходов — отметим их сразу. Регулярные платежи не трогаем.',
              other:
                  'За эти дни уже ${n} расхода — отметим их сразу. Регулярные платежи не трогаем.',
            ),
          'tags.form.manual' =>
            'Метку ставите сами — при вводе операции или в её карточке.',
          'tags.form.plainNote' =>
            'Метку ставите сами — при вводе операции или в её карточке. Отчёт соберёт траты во всех валютах.',
          'tags.form.footTrip' =>
            'Метку можно поставить и на билеты, купленные заранее',
          'tags.form.footPlain' => 'Метки живут в «Ещё» → «Метки»',
          'tags.form.save' => 'Сохранить',
          'tags.form.done' => 'Готово',
          'tags.form.nameMissing' => 'Дайте метке название.',
          'tags.form.failed' => 'Не удалось сохранить. Попробуйте ещё раз.',
          'tags.addedTrip' =>
            ({required Object name}) => 'Добавили поездку «${name}»',
          'tags.addedTag' =>
            ({required Object name}) => 'Добавили метку «${name}»',
          'tags.saved' => ({required Object name}) => 'Сохранили «${name}»',
          'tags.marked' =>
            ({required num n, required Object name}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Отметили ${n} расходов: «${name}»',
                  one: 'Отметили ${n} расход: «${name}»',
                  few: 'Отметили ${n} расхода: «${name}»',
                  many: 'Отметили ${n} расходов: «${name}»',
                  other: 'Отметили ${n} расхода: «${name}»',
                ),
          'tags.unmarked' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Сняли метку с ${n} расходов',
                  one: 'Сняли метку с ${n} расхода',
                  few: 'Сняли метку с ${n} расходов',
                  many: 'Сняли метку с ${n} расходов',
                  other: 'Сняли метку с ${n} расхода',
                ),
          'tags.undo' => 'Вернуть',
          'tags.picker.title' => 'Метки',
          'tags.picker.search' => 'Найти или создать',
          'tags.picker.clear' => 'Очистить поиск',
          'tags.picker.create' =>
            ({required Object name}) => 'Новая метка «${name}»',
          'tags.picker.createText' => 'Поездка с датами или просто метка',
          'tags.picker.tripsNote' =>
            'Пока идёт поездка, её метка сама встаёт на расходы этих дней.',
          'tags.picker.now' => 'сейчас',
          'tags.picker.emptyTitle' => 'Меток пока нет',
          'tags.picker.emptyText' =>
            'Наберите название: поездку, ремонт или праздник. Метка соберёт их траты во всех валютах.',
          'tags.row.add' => 'Добавить метку',
          'tags.row.addText' => 'Поездка, ремонт или праздник',
          'tags.row.trip' => ({required Object days}) => 'Поездка · ${days}',
          'tags.row.byDays' =>
            ({required Object days}) => 'Поездка · ${days} · по датам',
          'tags.row.plain' => 'Метка',
          'tags.row.more' => ({required Object n}) => 'и ещё ${n}',
          'transactions.expense' => 'Расход',
          'transactions.income' => 'Доход',
          'transactions.transfer' => 'Перевод',
          'transactions.adjustment' => 'Корректировка',
          'transactions.today' => 'Сегодня',
          'transactions.yesterday' => 'Вчера',
          'transactions.pickDay' => 'Выбрать день',
          'transactions.note' => 'Заметка',
          'transactions.addNote' => 'Заметка',
          'transactions.addTag' => 'Метка',
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
          'transactions.fromQuestion' => 'Из вопроса',
          'transactions.toAnswer' => 'К ответу',
          'transactions.dropFocus' =>
            ({required Object title}) => 'Снять «${title}»',
          'transactions.focusText' =>
            'Список показывает только то, о чём был вопрос. Снимите плашку — вернутся все операции месяца.',
          'transactions.backToAnswer' => 'Вернуться к ответу',
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
          'transactions.debt.title' => 'Долг',
          'transactions.debt.lent' => 'в долг',
          'transactions.debt.returned' => 'возврат',
          'transactions.debt.borrowed' => 'заняли',
          'transactions.debt.repaid' => 'отдали',
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
          'transactions.allOperations' =>
            ({required num n}) =>
                (_root.$meta.cardinalResolver ??
                PluralResolvers.cardinal('ru'))(
                  n,
                  zero: 'Все ${n} операций',
                  one: 'Все ${n} операция',
                  few: 'Все ${n} операции',
                  many: 'Все ${n} операций',
                  other: 'Все ${n} операции',
                ),
          _ => null,
        };
  }
}
