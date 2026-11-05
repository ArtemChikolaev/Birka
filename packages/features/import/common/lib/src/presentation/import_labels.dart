import 'package:decimal/decimal.dart';
import 'package:import_common/src/domain/import_defaults.dart';
import 'package:import_common/src/domain/import_memory.dart';
import 'package:import_common/src/domain/import_plan.dart';
import 'package:import_common/src/domain/statement.dart';
import 'package:import_common/src/domain/statement_format.dart';
import 'package:import_common/src/domain/statement_formats.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The name of [format] for people, such as «Т-Банк» or «Дзен-мани», or
/// «Свой формат» for one that the person set themselves.
String formatLabel(StatementFormat format) => isOwnFormat(format)
    ? t.imports.own
    : t.imports.formats[format.id] ?? format.id;

/// The names of new accounts for [accounts] of a file of [format], by their
/// keys: the name of an account in the file, or else the bank with the digits
/// of the card, and the currency when two names would be the same.
Map<String, String> newAccountNames(
  List<SourceAccount> accounts,
  StatementFormat? format,
) {
  String nameOf(SourceAccount source) {
    final key = source.key;
    if (key.isNotEmpty && key != source.currency) return key;
    final bank = format == null || isOwnFormat(format)
        ? t.imports.account
        : formatLabel(format);
    return source.cards.length == 1 ? '$bank ••${source.cards.single}' : bank;
  }

  final names = {for (final source in accounts) source.key: nameOf(source)};
  final uses = <String, int>{};
  for (final name in names.values) {
    uses[name] = (uses[name] ?? 0) + 1;
  }
  return {
    for (final source in accounts)
      source.key: switch (names[source.key]!) {
        final name when uses[name]! > 1 && source.currency != null =>
          '$name ${source.currency}',
        final name => name,
      },
  };
}

/// The categories of [categories] that stand for the presets of Birka, by the
/// keys of the presets: an open one of the kind of a preset with its name, or
/// else the one of that kind with its icon.
Map<String, Category> presetCategories(List<Category> categories) {
  final open = [
    for (final category in categories)
      if (!category.archived) category,
  ];
  return {
    for (final preset in categoryPresets) preset.key: ?_standsFor(preset, open),
  };
}

Category? _standsFor(CategoryPreset preset, List<Category> categories) {
  final kind = [
    for (final category in categories)
      if (category.kind == preset.kind) category,
  ];
  final name = t.categories.presets[preset.key];
  final named = name == null
      ? null
      : kind.where((it) => sameName(it.name, name)).firstOrNull;
  if (named != null) return named;
  final drawn = [
    for (final category in kind)
      if (category.icon == preset.icon) category,
  ];
  return drawn.length == 1 ? drawn.single : null;
}

/// The days from [from] to [to] for people: «3 октября 2026», «сентябрь
/// 2026», «1–15 октября 2026», «3 сентября – 4 ноября 2026», or both days
/// with their years.
String periodLabel(CivilDate from, CivilDate to) {
  String day(CivilDate date, {bool year = true}) => dateLabel(
    year: date.year,
    month: date.month,
    day: date.day,
    thisYear: year ? 0 : date.year,
  );
  if (from == to) return day(from);
  if (from.year != to.year) {
    return t.imports.periodFar(from: day(from), to: day(to));
  }
  if (from.month != to.month) {
    return t.imports.periodInYear(
      from: day(from, year: false),
      to: day(to, year: false),
      year: to.year,
    );
  }
  final last = DateTime.utc(to.year, to.month + 1, 0).day;
  if (from.day == 1 && to.day == last) {
    return t.imports.periodMonth(
      month: t.imports.monthsWhole[to.month - 1],
      year: to.year,
    );
  }
  return t.imports.periodInMonth(
    from: from.day,
    to: to.day,
    month: t.transactions.months[to.month - 1],
    year: to.year,
  );
}

/// [count] operations for people: «1 операция», «4 310 операций».
String operationsLabel(int count) =>
    t.imports.operations(n: count, count: formatCount(count));

/// A past import for people: its bank or its file, and its days, such as
/// «Альфа-Банк · сентябрь 2026».
String importLabel(LedgerImport import) {
  final format = statementFormats
      .where((it) => it.id == import.format)
      .firstOrNull;
  return t.imports.pastName(
    format: format == null ? import.fileName : formatLabel(format),
    period: periodLabel(import.firstDay, import.lastDay),
  );
}

/// The line under a past import: how many operations went where and when,
/// such as «198 операций → Зарплатная карта · 2 октября», with the year when
/// it is not that of [now].
String importLine(
  LedgerImport import,
  List<Account> accounts, {
  required DateTime now,
}) {
  final names = [
    for (final account in accounts)
      if (import.accountIds.contains(account.id)) account.name,
  ];
  final count = import.accountIds.length;
  final day = import.importedAt.toLocal();
  return t.imports.pastLine(
    operations: operationsLabel(import.transactions),
    where: names.length == 1 && count == 1
        ? names.single
        : t.imports.accounts(n: count, count: formatCount(count)),
    day: dateLabel(
      year: day.year,
      month: day.month,
      day: day.day,
      thisYear: now.toLocal().year,
    ),
  );
}

/// What [source] is for people, in the heading of its step: its card, its
/// name in the file, or nothing of its own.
String sourceTitle(SourceAccount source) {
  if (source.cards.length == 1) {
    return t.imports.accountTitleCard(card: source.cards.single);
  }
  if (source.key.isNotEmpty && source.key != source.currency) {
    return t.imports.accountTitleNamed(name: source.key);
  }
  return t.imports.accountTitle;
}

/// [amount] in [currency] of a file as money, or `null` when it has more
/// digits than the currency or lies past what money holds. A file that
/// names no currency is in [fallback].
Money? moneyOf(
  Decimal amount,
  String? currency, {
  Currency fallback = Currency.rub,
}) => moneyIn(amount, currency == null ? fallback : currencyNamed(currency));

/// What [match] says beside an account, such as «совпал номер карты».
String matchLabel(AccountMatch match) => switch (match) {
  AccountMatch.card => t.imports.cardMatched,
  AccountMatch.name => t.imports.nameMatched,
};

/// What the bank says [source] holds at the end of its statement, in the
/// currency of [after] when the file names none: `null` when the file gives
/// no balance, or one past what money holds.
Money? bankBalance(SourceAccount source, Money after) {
  final closing = source.closing;
  return closing == null
      ? null
      : moneyOf(closing, source.currency, fallback: after.currency);
}
