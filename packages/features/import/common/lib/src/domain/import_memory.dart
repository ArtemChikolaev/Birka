import 'dart:convert';

import 'package:device_settings/device_settings.dart';
import 'package:import_common/src/domain/cell_values.dart';
import 'package:import_common/src/domain/import_plan.dart';
import 'package:import_common/src/domain/statement.dart';
import 'package:import_common/src/domain/statement_format.dart';
import 'package:import_common/src/domain/statement_layout.dart';
import 'package:import_common/src/domain/statement_table.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// The start of the id of a format that a person set themselves.
const ownFormatPrefix = 'own-';

/// Whether [format] is one that a person set themselves, which Birka keeps.
bool isOwnFormat(StatementFormat? format) =>
    format?.id.startsWith(ownFormatPrefix) ?? false;

/// The format of [layout] of [table] as the person set it: each header with
/// its role, and how the values are written, under an id of the headers, so
/// that the next file with the same headers reads the same way; `null` for a
/// table without headers, which nothing could tell again.
StatementFormat? ownFormatOf(StatementTable table, StatementLayout layout) {
  if (layout.header < 0) return null;
  final headers = [
    for (final column in layout.columns) normalizeHeader(column.header),
  ];
  final columns = <String, ColumnRole>{
    for (final (index, header) in headers.indexed)
      if (header.isNotEmpty) header: layout.roles[index],
  };
  if (columns.isEmpty) return null;
  return StatementFormat(
    id: '$ownFormatPrefix${_hash(headers.join('\u0001'))}',
    file: table.file,
    columns: columns,
    sign: layout.options.sign,
    decimalMark: layout.options.decimalMark,
    dateOrder: layout.options.dateOrder,
  );
}

/// [layout] read as its format of one's own says: the guesses of the values
/// give way to what the person chose before.
StatementLayout asOwnFormat(StatementLayout layout) {
  final format = layout.format;
  if (!isOwnFormat(format)) return layout;
  return layout.withOptions(
    ReadingOptions(
      sign: format!.sign,
      decimalMark: format.decimalMark ?? layout.options.decimalMark,
      dateOrder: format.dateOrder ?? layout.options.dateOrder,
    ),
  );
}

/// The key under which the account of the ledger for [source] is kept: its
/// key in the file with the digits of its cards, so that another card of
/// the same bank and currency goes its own way.
String sourceKeyOf(SourceAccount source) =>
    [source.key, ...source.cards.toList()..sort()].join('·');

/// What a person chose for a format: the account of the ledger for each
/// account of the file by [sourceKeyOf], or `null` for one left out, the
/// category for each category of the bank, and the category of fees.
@immutable
final class RememberedChoices {
  /// Creates the choices.
  const RememberedChoices({
    this.accounts = const {},
    this.categories = const {},
    this.fees,
  });

  /// The id of the account for each account of the file by [sourceKeyOf],
  /// or `null` when its operations stay out.
  final Map<String, String?> accounts;

  /// The id of the category for each category of the bank.
  final Map<BankCategory, String> categories;

  /// The id of the category of fees.
  final String? fees;
}

/// What Birka keeps of past imports on this device (ADR 0021, point 19): the
/// formats that a person set themselves, so that the next file with the same
/// headers reads at once, and the choices of each format, so that its next
/// file goes where the last one went.
final class ImportMemory {
  /// Creates the memory in [_store].
  ImportMemory(this._store);

  final SettingsStore _store;

  /// Where the memory stays in the settings.
  static const key = 'importMemory';

  /// How many formats of one's own the memory keeps, the latest first.
  static const most = 20;

  /// The formats that the person set themselves, the latest first.
  List<StatementFormat> get formats => [
    for (final format in _read().formats) ?_formatOf(format),
  ];

  /// What the person chose for the format [formatId] the last time.
  RememberedChoices? choicesOf(String formatId) {
    final choices = _read().choices[formatId];
    return choices is Map<String, Object?> ? _choicesOf(choices) : null;
  }

  /// Keeps [format] when it is the person's own, and [choices] for it, in
  /// place of what was kept for it before.
  Future<void> remember(
    StatementFormat format,
    RememberedChoices choices,
  ) async {
    final kept = _read();
    final formats = [
      if (isOwnFormat(format)) _jsonOf(format),
      for (final other in kept.formats)
        if (other['id'] != format.id) other,
    ].take(most).toList();
    final owned = {
      for (final other in formats) other['id'],
    };
    final all = {
      for (final MapEntry(:key, :value) in kept.choices.entries)
        if (!key.startsWith(ownFormatPrefix) || owned.contains(key)) key: value,
      format.id: _jsonOfChoices(choices),
    };
    await _store.write(key, jsonEncode({'formats': formats, 'choices': all}));
  }

  ({List<Map<String, Object?>> formats, Map<String, Object?> choices}) _read() {
    try {
      final json = jsonDecode(_store.read(key) ?? '{}');
      if (json is! Map<String, Object?>) return (formats: [], choices: {});
      final formats = json['formats'];
      final choices = json['choices'];
      return (
        formats: [
          if (formats is List)
            for (final format in formats)
              if (format is Map<String, Object?>) format,
        ],
        choices: choices is Map<String, Object?> ? choices : {},
      );
    } on FormatException {
      return (formats: [], choices: {});
    }
  }

  static Map<String, Object?> _jsonOf(StatementFormat format) => {
    'id': format.id,
    'file': format.file.name,
    'columns': {
      for (final MapEntry(:key, :value) in format.columns.entries)
        key: value.name,
    },
    'sign': format.sign.name,
    'decimalMark': format.decimalMark?.name,
    'dateOrder': format.dateOrder?.name,
  };

  static StatementFormat? _formatOf(Map<String, Object?> json) {
    final id = json['id'];
    final file = TableFile.values.asNameMap()[json['file']];
    final columns = json['columns'];
    if (id is! String || !id.startsWith(ownFormatPrefix)) return null;
    if (file == null || columns is! Map<String, Object?>) return null;
    final roles = ColumnRole.values.asNameMap();
    return StatementFormat(
      id: id,
      file: file,
      columns: {
        for (final MapEntry(:key, :value) in columns.entries)
          key: ?roles[value],
      },
      sign:
          AmountSign.values.asNameMap()[json['sign']] ??
          AmountSign.expenseNegative,
      decimalMark: DecimalMark.values.asNameMap()[json['decimalMark']],
      dateOrder: DateOrder.values.asNameMap()[json['dateOrder']],
    );
  }

  static Map<String, Object?> _jsonOfChoices(RememberedChoices choices) => {
    'accounts': choices.accounts,
    'categories': [
      for (final MapEntry(:key, :value) in choices.categories.entries)
        {'kind': key.kind.name, 'name': key.name, 'category': value},
    ],
    'fees': choices.fees,
  };

  static RememberedChoices _choicesOf(Map<String, Object?> json) {
    final accounts = json['accounts'];
    final categories = json['categories'];
    final fees = json['fees'];
    final kinds = CategoryKind.values.asNameMap();
    return RememberedChoices(
      accounts: {
        if (accounts is Map<String, Object?>)
          for (final MapEntry(:key, :value) in accounts.entries)
            if (value == null || value is String) key: value as String?,
      },
      categories: {
        if (categories is List)
          for (final category in categories)
            if (category is Map<String, Object?>)
              if ((
                    kinds[category['kind']],
                    category['name'],
                    category['category'],
                  )
                  case (final kind?, final String? name, final String id))
                (kind: kind, name: name): id,
      },
      fees: fees is String ? fees : null,
    );
  }
}

/// A short id of [text] that stays the same from run to run and on every
/// compiler: 32 bits of FNV-1a over its code units, in hex. The product by
/// the prime goes in two parts, so that no number passes what the web holds
/// exactly.
String _hash(String text) {
  var hash = 0x811C9DC5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x193 + ((hash & 0xFF) << 24)) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
