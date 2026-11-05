import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:device_settings/device_settings.dart';
import 'package:import_common/import_common.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The settings in memory.
final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// A table of a bank that no format knows: a date, a text, the amount that
/// the guess leaves out and a balance.
StatementTable _table({String name = 'statement_oct_2026.csv'}) => tableOf(
  [
    ['День', 'Назначение платежа', 'Сумма в валюте счёта', 'Остаток'],
    ['01.10.2026', 'Зарплата', '96500,00', '142679,81'],
    ['03.10.2026', 'Кофейня Зерно', '-420,00', '142259,81'],
  ],
  fileName: name,
);

/// The layout of [table] as a person sets it: the amount in its column.
StatementLayout _set(StatementTable table) =>
    guessLayout(table).withRole(2, ColumnRole.amount);

void main() {
  late _Store store;
  late ImportMemory memory;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    store = _Store();
    memory = ImportMemory(store);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group("a format of one's own", () {
    test('holds each header with its role and how values are written', () {
      final format = ownFormatOf(_table(), _set(_table()))!;

      expect(isOwnFormat(format), isTrue);
      expect(format.columns, {
        'день': ColumnRole.date,
        'назначение платежа': ColumnRole.description,
        'сумма в валюте счета': ColumnRole.amount,
        'остаток': ColumnRole.balance,
      });
      expect(format.decimalMark, DecimalMark.comma);
      expect(formatLabel(format), 'Свой формат');
    });

    test('takes the same id from the same headers on every compiler', () {
      expect(ownFormatOf(_table(), _set(_table()))!.id, 'own-9af66e5a');
      expect(
        ownFormatOf(_table(name: 'other.csv'), _set(_table()))!.id,
        'own-9af66e5a',
      );
    });

    test('reads the next file with the same headers at once', () {
      final format = ownFormatOf(_table(), _set(_table()))!;

      final layout = asOwnFormat(
        detectLayout(_table(), formats: [...statementFormats, format]),
      );

      expect(layout.format?.id, format.id);
      expect(layout.missing, isEmpty);
      expect(layout.roles[2], ColumnRole.amount);
    });

    test('keeps the way of the values that the person chose', () {
      final set = _set(_table()).withOptions(
        const ReadingOptions(decimalMark: DecimalMark.dot),
      );
      final format = ownFormatOf(_table(), set)!;

      final layout = asOwnFormat(
        detectLayout(_table(), formats: [format]),
      );

      expect(layout.options.decimalMark, DecimalMark.dot);
    });

    test('is none for a table without headers', () {
      final table = tableOf([
        ['01.10.2026', '-420,00'],
      ]);

      expect(ownFormatOf(table, guessLayout(table)), isNull);
    });
  });

  test('keeps an account of a file by its key and the digits of its cards', () {
    SourceAccount source(String key, Set<String> cards) => SourceAccount(
      key: key,
      operations: 1,
      spent: Decimal.zero,
      received: Decimal.zero,
      cards: cards,
    );

    expect(sourceKeyOf(source('RUB', {'7777', '4821'})), 'RUB·4821·7777');
    expect(sourceKeyOf(source('', {})), '');
  });

  group('the memory', () {
    test("keeps a format of one's own and its choices", () async {
      final format = ownFormatOf(_table(), _set(_table()))!;
      const choices = RememberedChoices(
        accounts: {'': 'card', 'savings': null},
        categories: {
          (kind: CategoryKind.expense, name: 'Супермаркеты'): 'food',
          (kind: CategoryKind.expense, name: null): 'other',
        },
        fees: 'bank',
      );

      await memory.remember(format, choices);
      final again = ImportMemory(store);

      expect(again.formats.single.id, format.id);
      expect(again.formats.single.columns, format.columns);
      final kept = again.choicesOf(format.id)!;
      expect(kept.accounts, choices.accounts);
      expect(kept.categories, choices.categories);
      expect(kept.fees, 'bank');
    });

    test('keeps only the choices of a format that Birka knows', () async {
      await memory.remember(
        alfa,
        const RememberedChoices(accounts: {'RUB': 'card'}),
      );

      expect(memory.formats, isEmpty);
      expect(memory.choicesOf('alfa')!.accounts, {'RUB': 'card'});
    });

    test('puts the latest format first and the oldest out', () async {
      for (var i = 0; i < ImportMemory.most + 2; i++) {
        final format = StatementFormat(
          id: '${ownFormatPrefix}f$i',
          file: TableFile.csv,
          columns: const {'дата': ColumnRole.date},
        );
        await memory.remember(format, const RememberedChoices());
      }

      final ids = memory.formats.map((it) => it.id).toList();
      expect(ids, hasLength(ImportMemory.most));
      expect(ids.first, '${ownFormatPrefix}f${ImportMemory.most + 1}');
      expect(ids, isNot(contains('${ownFormatPrefix}f0')));
      expect(memory.choicesOf('${ownFormatPrefix}f0'), isNull);
    });

    test('that holds no sense is empty', () {
      store.values[ImportMemory.key] = 'not json';
      expect(memory.formats, isEmpty);
      expect(memory.choicesOf('alfa'), isNull);

      store.values[ImportMemory.key] = jsonEncode({
        'formats': [
          {'id': 'alfa', 'file': 'csv', 'columns': <String, String>{}},
        ],
      });
      expect(memory.formats, isEmpty);
    });
  });
}
