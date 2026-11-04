import 'package:import_common/src/domain/import_defaults.dart';
import 'package:import_common/src/domain/statement.dart';
import 'package:import_common/src/domain/statement_format.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The name of [format] for people, such as «Т-Банк» or «Дзен-мани».
String formatLabel(StatementFormat format) =>
    t.imports.formats[format.id] ?? format.id;

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
    final bank = format == null ? t.imports.account : formatLabel(format);
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
