import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:backup_common/backup_common.dart';

/// The settings in memory.
final class FakeSettingsStore implements SettingsStore {
  /// Creates a store that holds [values].
  FakeSettingsStore([Map<String, String>? values]) : values = values ?? {};

  /// What the store holds.
  final Map<String, String> values;

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// A file in memory.
final class FakeFile implements ChosenFile {
  /// Creates a file [name] that holds [text].
  FakeFile(this.name, String text) : _bytes = utf8.encode(text);

  /// Creates a file [name] that holds the bytes given.
  FakeFile.bytes(this.name, this._bytes);

  @override
  final String name;

  final Uint8List _bytes;

  /// Whether it has been read.
  bool wasRead = false;

  @override
  Future<int?> length() async => _bytes.length;

  @override
  Future<Uint8List> read() async {
    wasRead = true;
    return _bytes;
  }
}

/// What one save carried.
typedef SavedFile = ({String name, String type, Uint8List bytes});

/// The windows of the system, answered by the test.
final class FakeBackupFiles implements BackupFiles {
  /// Whether the person saves what they are offered.
  bool saves = true;

  /// What the person chooses.
  ChosenFile? chosen;

  /// What the next call fails with.
  Exception? failure;

  /// Every file saved, in order.
  final saved = <SavedFile>[];

  @override
  Future<bool> save({
    required String name,
    required String type,
    required Uint8List bytes,
  }) async {
    if (failure case final failure?) throw failure;
    if (!saves) return false;
    saved.add((name: name, type: type, bytes: bytes));
    return true;
  }

  @override
  Future<ChosenFile?> open() async {
    if (failure case final failure?) throw failure;
    return chosen;
  }
}

/// The ledger in memory.
final class FakeBackupRepository implements BackupRepository {
  /// How much the ledger holds, for the test to change.
  final counts = StreamController<LedgerCounts>.broadcast();

  /// The text of the copy that the ledger makes.
  String copyText = '';

  /// What [operations] gives.
  OperationsExport export = const OperationsExport(
    transactions: [],
    accounts: [],
    categories: [],
  );

  /// What the next write fails with.
  Exception? failure;

  /// Every copy restored, in order.
  final restored = <LedgerCopy>[];

  /// How many times the ledger was wiped.
  int wipes = 0;

  @override
  Stream<LedgerCounts> watchCounts() => counts.stream;

  @override
  Future<LedgerCopy> copy() async {
    if (failure case final failure?) throw failure;
    return LedgerCopy.parse(copyText);
  }

  @override
  Future<void> restore(LedgerCopy copy) async {
    if (failure case final failure?) throw failure;
    restored.add(copy);
  }

  @override
  Future<void> wipe() async {
    if (failure case final failure?) throw failure;
    wipes++;
  }

  @override
  Future<OperationsExport> operations() async {
    if (failure case final failure?) throw failure;
    return export;
  }
}

/// The text of a copy made at [madeAt] with a card, a cafe and [operations]
/// coffees.
String sampleCopy({DateTime? madeAt, int operations = 1}) {
  Map<String, Object?> stamps(String id) => {
    'id': id,
    'createdAt': '2026-10-01T09:00:00.000Z',
    'updatedAt': '2026-10-01T09:00:00.000Z',
  };
  return jsonEncode({
    'format': 'birka-copy',
    'version': 1,
    'madeAt': (madeAt ?? DateTime.utc(2026, 10, 28, 12)).toIso8601String(),
    'accounts': [
      {
        ...stamps('card'),
        'name': 'Card',
        'type': 'debit',
        'currency': 'RUB',
        'decimalDigits': 2,
        'openingBalanceMinor': 0,
        'lastDigits': null,
        'art': 'emerald',
        'includeInTotals': true,
        'archived': false,
        'sortOrder': 0,
      },
    ],
    'categories': [
      {
        ...stamps('cafe'),
        'parentId': null,
        'kind': 'expense',
        'name': 'Cafe',
        'icon': null,
        'color': null,
        'archived': false,
        'sortOrder': 0,
      },
    ],
    'transactions': [
      for (var i = 0; i < operations; i++)
        {
          ...stamps('coffee $i'),
          'kind': 'expense',
          'occurredOn': '2026-10-28',
          'occurredAt': null,
          'note': '',
          'status': 'cleared',
          'source': 'manual',
          'entries': [
            {...stamps('entry $i'), 'accountId': 'card', 'amountMinor': -25000},
          ],
          'allocations': [
            {
              ...stamps('allocation $i'),
              'categoryId': 'cafe',
              'amountMinor': 25000,
            },
          ],
        },
    ],
  });
}
