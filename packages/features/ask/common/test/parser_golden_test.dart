import 'package:ask_common/ask_common.dart';
import 'package:ask_common/testing.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

/// The golden set of the parser (ADR 0028): each question and exactly what
/// it is read as, on the story of the boards. Today is Thursday, 12 November
/// 2026, and months start on the 1st.
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Map<String, Object>? read(String question) => AskParser(
    AskVocabulary(
      today: askToday,
      categories: askCategories(),
      tags: askTags(),
      accounts: [for (final balance in askBalances()) balance.account],
      base: Currency.rub,
    ),
    help: helpQuestions(),
  ).read(question)?.toJson();

  Map<String, Object> period(String span, String from, String to, [int? n]) => {
    'span': span,
    'from': from,
    'to': to,
    'count': ?n,
  };
  final november = period('month', '2026-11-01', '2026-11-12');
  final october = period('month', '2026-10-01', '2026-10-31');
  final september = period('month', '2026-09-01', '2026-09-30');

  Map<String, Object> data({
    String side = 'expenses',
    Map<String, Object>? when,
    List<String>? categories,
    String? tag,
    String? account,
    List<String>? words,
    String? above,
    String? below,
    String? focus,
    List<String>? places,
    bool thisMonth = true,
  }) => {
    'data': {
      'side': side,
      'period': ?(when ?? (thisMonth && tag == null ? november : null)),
      'categories': ?categories,
      'tag': ?tag,
      'account': ?account,
      'words': ?words,
      'above': ?above,
      'below': ?below,
      'focus': ?focus,
    },
    'places': ?places,
  };

  final golden = <String, Map<String, Object>?>{
    // Categories and periods.
    'кафе в октябре': data(categories: ['cafe'], when: october),
    'Кафе в октябре': data(categories: ['cafe'], when: october),
    'кафе': data(categories: ['cafe']),
    'траты на кафе в сентябре': data(categories: ['cafe'], when: september),
    'сколько я потратил на кафе в октябре': data(
      categories: ['cafe'],
      when: october,
    ),
    'продукты за прошлый месяц': data(
      categories: ['groceries'],
      when: october,
    ),
    'продуктов в этом месяце': data(categories: ['groceries']),
    'транспорт вчера': data(
      categories: ['transport'],
      when: period('day', '2026-11-11', '2026-11-11'),
    ),
    'кафе сегодня': data(
      categories: ['cafe'],
      when: period('day', '2026-11-12', '2026-11-12'),
    ),
    'подарки на прошлой неделе': data(
      categories: ['gifts'],
      when: period('week', '2026-11-02', '2026-11-08'),
    ),
    'дом на этой неделе': data(
      categories: ['home'],
      when: period('week', '2026-11-09', '2026-11-12'),
    ),
    'кафе за 3 месяца': data(
      categories: ['cafe'],
      when: period('months', '2026-08-01', '2026-10-31', 3),
    ),
    'кафе за последние 3 месяца': data(
      categories: ['cafe'],
      when: period('months', '2026-08-01', '2026-10-31', 3),
    ),
    'кафе за 30 дней': data(
      categories: ['cafe'],
      when: period('days', '2026-10-14', '2026-11-12', 30),
    ),
    'кафе за неделю': data(
      categories: ['cafe'],
      when: period('days', '2026-11-06', '2026-11-12', 7),
    ),
    'траты за месяц': data(),
    'траты за год': data(when: period('year', '2026-01-01', '2026-11-12')),
    'кафе в 2025 году': data(
      categories: ['cafe'],
      when: period('year', '2025-01-01', '2025-12-31'),
    ),
    'траты в прошлом году': data(
      when: period('year', '2025-01-01', '2025-12-31'),
    ),
    'кафе с 1 по 15 октября': data(
      categories: ['cafe'],
      when: period('range', '2026-10-01', '2026-10-15'),
    ),
    'кафе с 1 октября по 15 ноября': data(
      categories: ['cafe'],
      when: period('range', '2026-10-01', '2026-11-12'),
    ),
    'кафе с 5 ноября': data(
      categories: ['cafe'],
      when: period('range', '2026-11-05', '2026-11-12'),
    ),
    'траты до 10 ноября': data(
      when: period('range', '2026-11-01', '2026-11-10'),
    ),
    'кафе 8 ноября': data(
      categories: ['cafe'],
      when: period('day', '2026-11-08', '2026-11-08'),
    ),
    'кафе 08.11': data(
      categories: ['cafe'],
      when: period('day', '2026-11-08', '2026-11-08'),
    ),
    'кафе в декабре': data(
      categories: ['cafe'],
      when: period('month', '2025-12-01', '2025-12-31'),
    ),
    'кафе в мае': data(
      categories: ['cafe'],
      when: period('month', '2026-05-01', '2026-05-31'),
    ),
    'кафе в мае 2025': data(
      categories: ['cafe'],
      when: period('month', '2025-05-01', '2025-05-31'),
    ),
    'траты за всё время': data(thisMonth: false),
    'траты в позапрошлом месяце': data(when: september),
    'подписки в октябре': data(
      categories: ['subs'],
      when: october,
      places: ['schedules'],
    ),
    // Which money.
    'доходы в октябре': data(side: 'income', when: october),
    'сколько я заработал в октябре': data(side: 'income', when: october),
    'зарплата в октябре': data(
      side: 'income',
      categories: ['salary'],
      when: october,
      places: ['payday'],
    ),
    'зарплата': data(
      side: 'income',
      categories: ['salary'],
      places: ['payday'],
    ),
    'траты': data(),
    'расходы в сентябре': data(when: september),
    'доходы': data(side: 'income'),
    'мои покупки в октябре': data(when: october),
    // Amounts.
    'больше 5000 в ноябре': data(above: '5000.00 RUB'),
    'траты больше 5 000 ₽': data(above: '5000.00 RUB'),
    'дороже 10 тыс в октябре': data(above: '10000.00 RUB', when: october),
    'кафе дешевле 300': data(categories: ['cafe'], below: '300.00 RUB'),
    'траты от 1000 до 5000': data(
      above: '1000.00 RUB',
      below: '5000.00 RUB',
    ),
    'больше 100 лари': data(above: '100.00 GEL'),
    'больше 50 долларов в октябре': data(above: '50.00 USD', when: october),
    'больше 5к': data(above: '5000.00 RUB'),
    'больше 1,5 тыс': data(above: '1500.00 RUB'),
    'больше 100000000000000000': {'unknown': true},
    // What it wants most.
    'самая большая трата в октябре': data(focus: 'biggest', when: october),
    'самые крупные покупки': data(focus: 'biggest'),
    'сколько раз я был в кафе в октябре': data(
      categories: ['cafe'],
      focus: 'count',
      when: october,
    ),
    'как часто я хожу в кафе': data(categories: ['cafe'], focus: 'count'),
    'средний чек в кафе': data(categories: ['cafe'], focus: 'average'),
    'на что больше всего потратил в октябре': data(
      focus: 'categories',
      when: october,
    ),
    'куда ушли деньги в октябре': data(focus: 'categories', when: october),
    // Метки and trips.
    'траты в Тбилиси': data(tag: 'tbilisi'),
    'сколько ушло в поездке в Тбилиси': data(tag: 'tbilisi'),
    'Тбилиси': data(tag: 'tbilisi'),
    'кафе в Тбилиси': data(categories: ['cafe'], tag: 'tbilisi'),
    'ремонт кухни': data(tag: 'renovation'),
    'ремонт': data(tag: 'renovation'),
    'стамбул': data(tag: 'istanbul'),
    'траты в Стамбуле': data(tag: 'istanbul'),
    // Accounts.
    'траты по зарплатной карте в октябре': data(account: 'card', when: october),
    'наличными в октябре': data(account: 'cash', when: october),
    // Words of the note.
    'такси в ноябре': data(words: ['такси']),
    'хинкальная в октябре': data(words: ['хинкальная'], when: october),
    'хинкальная': {'unknown': true},
    // Facts.
    'сколько можно тратить': {'fact': 'allowance'},
    'сколько можно тратить сегодня': {'fact': 'allowance'},
    'сколько осталось до зарплаты': {'fact': 'allowance'},
    'когда следующий платёж': {'fact': 'payments'},
    'ближайшие платежи': {'fact': 'payments'},
    'когда спишут подписку': {'fact': 'payments'},
    'регулярные платежи': {'fact': 'payments'},
    'сколько у меня денег': {'fact': 'capital'},
    'мой баланс': {'fact': 'capital'},
    'капитал': {'fact': 'capital'},
    'курс доллара': {'fact': 'rate', 'currency': 'USD'},
    'курс лари': {'fact': 'rate', 'currency': 'GEL'},
    'курс евро': {'fact': 'rate', 'currency': 'EUR'},
    'какой курс': {'fact': 'rate', 'currency': 'USD'},
    // Help.
    'как перенести данные на новый телефон': {
      'help': [1],
      'places': ['backup'],
    },
    'где хранятся мои данные': {
      'help': [0],
      'places': ['backup'],
    },
    'откуда берется курс': {
      'help': [2],
    },
    'как скрыть суммы': {
      'help': [4],
    },
    'можно ли загрузить операции из банка': {
      'help': [3],
      'places': ['imports'],
    },
    // Screens.
    'настройки': {
      'places': ['settings'],
    },
    'уведомления': {
      'places': ['notifications'],
    },
    'импорт выписки': {
      'places': ['imports'],
    },
    'метки': {
      'places': ['tags'],
    },
    'отчёты': {
      'places': ['reports'],
    },
    'категории': {
      'places': ['categories'],
    },
    // Fixed replies.
    'стоит ли покупать доллары': {'refused': 'advice'},
    'куда вложить деньги': {'refused': 'advice'},
    'купить биткоин': {'refused': 'advice'},
    'что будет с курсом доллара': {'refused': 'advice'},
    'какая погода в Тбилиси': {'refused': 'offTopic'},
    'расскажи анекдот': {'refused': 'offTopic'},
    'кто ты': {'refused': 'offTopic'},
    // Nothing yet, and nothing at all.
    '': null,
    'ка': null,
    'абракадабра': {'unknown': true},
    'сколько я съел пиццы': {'unknown': true},
    // English.
    'spending in october': data(when: october),
    'income last month': data(side: 'income', when: october),
    'how much did i spend this week': data(
      when: period('week', '2026-11-09', '2026-11-12'),
    ),
    'over 100 usd': data(above: '100.00 USD'),
    'dollar rate': {'fact': 'rate', 'currency': 'USD'},
    'how much money do i have': {'fact': 'capital'},
  };

  for (final MapEntry(key: question, value: expected) in golden.entries) {
    test('«$question»', () => expect(read(question), expected));
  }
}
