import 'package:decimal/decimal.dart';
import 'package:import_common/src/domain/import_plan.dart';
import 'package:import_common/src/domain/statement.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The currency that the code [code] of a file names: one that Birka offers,
/// such as `USDT` with its six digits, another ISO 4217 one, or one outside it
/// with two digits.
Currency currencyNamed(String code) {
  for (final currency in offeredCurrencies) {
    if (currency.code == code) return currency;
  }
  return RegExp(r'^[A-Z]{3}$').hasMatch(code)
      ? Currency.iso(code)
      : Currency.custom(code, decimalDigits: 2);
}

/// Where [source] goes unless the person says otherwise: an open account of
/// its currency with the digits of its card or with its name, or else a new
/// account named [newName] with the balance before the statement.
AccountChoice defaultAccount(
  SourceAccount source,
  List<Account> accounts, {
  required String newName,
  Currency fallback = Currency.rub,
}) {
  final currency = source.currency == null
      ? fallback
      : currencyNamed(source.currency!);
  final open = [
    for (final account in accounts)
      if (!account.archived &&
          account.openingBalance.currency.code == currency.code)
        account,
  ];
  final byCard = [
    for (final account in open)
      if (account.lastDigits != null &&
          source.cards.contains(account.lastDigits))
        account,
  ];
  if (byCard.length == 1) return IntoAccount(byCard.single);
  final byName = [
    for (final account in open)
      if (sameName(account.name, source.key)) account,
  ];
  if (byName.length == 1) return IntoAccount(byName.single);
  final opening = source.opening ?? Decimal.zero;
  final minor = opening.shift(currency.decimalDigits).round();
  return NewAccount(
    name: newName,
    type: AccountType.debit,
    openingBalance: Money(minor.toBigInt().toInt(), currency),
    lastDigits: source.cards.length == 1 ? source.cards.single : null,
  );
}

/// Where [bank] goes unless the person says otherwise: a category of its kind
/// with its name, a subcategory for a name such as «Путешествия / Билеты»,
/// and else a new category when [create] says so, as for the categories of
/// another app. A category of a bank goes into the one of [presets], by the
/// keys of the presets, that it stands for in [bankCategoryPresets], or else
/// into the inbox.
CategoryChoice defaultCategory(
  BankCategory bank,
  List<Category> categories, {
  required bool create,
  Map<String, Category> presets = const {},
}) {
  final name = bank.name?.trim();
  if (name == null || name.isEmpty) return const Unsorted();
  final kind = [
    for (final category in categories)
      if (!category.archived && category.kind == bank.kind) category,
  ];
  final parts = name.split(' / ');
  if (parts.length == 2) {
    final [parentName, childName] = [for (final part in parts) part.trim()];
    final parent = kind
        .where((it) => it.parentId == null && sameName(it.name, parentName))
        .firstOrNull;
    if (parent != null) {
      final child = kind
          .where(
            (it) => it.parentId == parent.id && sameName(it.name, childName),
          )
          .firstOrNull;
      if (child != null) return IntoCategory(child.id);
      return create
          ? NewCategory(childName, parentId: parent.id)
          : IntoCategory(parent.id);
    }
    return create
        ? NewCategory(childName, parentName: parentName)
        : const Unsorted();
  }
  final same = kind.where((it) => sameName(it.name, name)).firstOrNull;
  if (same != null) return IntoCategory(same.id);
  if (create) return NewCategory(name);
  final preset = presets[bankCategoryPresets[bank.kind]?[_key(name)]];
  return preset == null ? const Unsorted() : IntoCategory(preset.id);
}

/// The presets of Birka that categories of banks stand for, by the kind and
/// the name of the category of the bank: «Супермаркеты» of T-Bank are
/// «Продукты», «Такси» is «Транспорт». Banks name their categories in their
/// own words, so only those that leave no doubt are here.
const Map<CategoryKind, Map<String, String>> bankCategoryPresets = {
  CategoryKind.expense: {
    'супермаркеты': 'groceries',
    'продукты': 'groceries',
    'рестораны': 'cafe',
    'фастфуд': 'cafe',
    'кафе': 'cafe',
    'рестораны и кафе': 'cafe',
    'кафе и рестораны': 'cafe',
    'транспорт': 'transport',
    'местный транспорт': 'transport',
    'такси': 'transport',
    'каршеринг': 'transport',
    'жкх': 'home',
    'коммунальные платежи': 'home',
    'дом и ремонт': 'home',
    'аптеки': 'health',
    'медицина': 'health',
    'медицинские услуги': 'health',
    'развлечения': 'leisure',
    'кино': 'leisure',
    'цифровые товары': 'subscriptions',
    'одежда и обувь': 'clothes',
    'одежда': 'clothes',
    'авиабилеты': 'travel',
    'ж/д билеты': 'travel',
    'жд билеты': 'travel',
    'отели': 'travel',
    'путешествия': 'travel',
    'образование': 'education',
    'цветы': 'gifts',
    'подарки': 'gifts',
  },
  CategoryKind.income: {
    'зарплата': 'salary',
    'проценты': 'interest',
    'проценты на остаток': 'interest',
    'подарки': 'giftsReceived',
  },
};

/// The categories of the bank that the operations of [statement] carry, the
/// most used first. A transfer carries one when the account of one of its
/// sides is in [leftOut], as it comes in as an expense or an income then.
List<BankCategory> bankCategoriesOf(
  Statement statement, {
  Set<String> leftOut = const {},
}) {
  final uses = <BankCategory, int>{};
  for (final row in statement.rows) {
    final out = leftOut.contains(row.out?.account) ? null : row.out;
    final into = leftOut.contains(row.into?.account) ? null : row.into;
    if ((out == null) == (into == null)) continue;
    final category = (
      kind: out != null ? CategoryKind.expense : CategoryKind.income,
      name: row.category,
    );
    uses[category] = (uses[category] ?? 0) + 1;
  }
  return [...uses.keys]..sort((a, b) => uses[b]!.compareTo(uses[a]!));
}

/// Whether two names are the same for a person: case, ё and the spaces around
/// them do not count.
bool sameName(String a, String b) => _key(a) == _key(b);

String _key(String name) => name
    .trim()
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp(r'\s+'), ' ');
