import 'dart:convert';
import 'dart:typed_data';

import 'package:backup_common/backup_common.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime(2026, 11, 2, 21, 40);
  late FakeBackupRepository repository;
  late FakeBackupFiles files;
  late FakeSettingsStore store;
  late BackupCubit cubit;

  BackupCubit create() => BackupCubit(repository, files, store, now: () => now);

  setUp(() {
    repository = FakeBackupRepository()..copyText = sampleCopy(operations: 3);
    files = FakeBackupFiles();
    store = FakeSettingsStore();
    cubit = create();
  });

  tearDown(() => cubit.close());

  test('follows how much the ledger holds', () async {
    const counts = LedgerCounts(
      accounts: 6,
      categories: 24,
      transactions: 1248,
    );

    repository.counts.add(counts);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.counts, counts);
  });

  test('knows when the device saved its last copy', () async {
    store.values[BackupCubit.lastCopyKey] = '2026-11-01T18:40:00.000Z';
    await cubit.close();

    cubit = create();

    expect(cubit.state.lastCopyAt, DateTime.utc(2026, 11, 1, 18, 40));
  });

  group('saving a copy', () {
    test('saves the file and remembers when', () async {
      await cubit.save();

      final file = files.saved.single;
      expect(file.name, 'birka-2026-10-28.birka');
      expect(file.type, copyFileType);
      expect(LedgerCopy.parse(utf8.decode(file.bytes)).counts.transactions, 3);
      expect(cubit.state.lastCopyAt, DateTime.utc(2026, 10, 28, 12));
      expect(store.values[BackupCubit.lastCopyKey], '2026-10-28T12:00:00.000Z');
      expect(cubit.state.notice, isA<CopySaved>());
      expect(cubit.state.task, isNull);
    });

    test('that the person cancels changes nothing', () async {
      files.saves = false;

      await cubit.save();

      expect(cubit.state.lastCopyAt, isNull);
      expect(cubit.state.notice, isNull);
      expect(store.values, isEmpty);
    });

    test('that fails says so', () async {
      files.failure = Exception('No room');

      await cubit.save();

      expect(cubit.state.notice, isA<BackupFailed>());
      expect(cubit.state.lastCopyAt, isNull);
      expect(cubit.state.task, isNull);
    });

    test('waits for the task that runs', () async {
      final first = cubit.save();
      final second = cubit.save();
      await (first, second).wait;

      expect(files.saved, hasLength(1));
    });

    test('says it twice when it happens twice', () async {
      final notices = <BackupNotice?>[];
      final listening = cubit.stream.listen(
        (state) => notices.add(state.notice),
      );

      await cubit.save();
      await cubit.save();
      await Future<void>.delayed(Duration.zero);
      await listening.cancel();

      expect(notices.whereType<CopySaved>(), hasLength(2));
    });
  });

  group('opening a copy', () {
    test('offers it with what it holds', () async {
      files.chosen = FakeFile('birka-2026-10-28.birka', sampleCopy());

      await cubit.open();

      final offer = cubit.state.offer!;
      expect(offer.fileName, 'birka-2026-10-28.birka');
      expect(offer.copy.counts.transactions, 1);
      expect(repository.restored, isEmpty);
      expect(cubit.state.task, isNull);
    });

    test('without a choice changes nothing', () async {
      await cubit.open();

      expect(cubit.state.offer, isNull);
      expect(cubit.state.notice, isNull);
    });

    test('that is not a copy says so', () async {
      files.chosen = FakeFile('table.csv', 'Date,Amount\r\n2026-10-28,100');

      await cubit.open();

      expect(cubit.state.offer, isNull);
      expect(
        cubit.state.notice,
        isA<CopyRefused>().having(
          (it) => it.problem,
          'problem',
          LedgerCopyProblem.notACopy,
        ),
      );
    });

    test('that holds no text says that it is not a copy', () async {
      files.chosen = FakeFile.bytes(
        'photo.jpg',
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
      );

      await cubit.open();

      expect(
        cubit.state.notice,
        isA<CopyRefused>().having(
          (it) => it.problem,
          'problem',
          LedgerCopyProblem.notACopy,
        ),
      );
    });

    test('that is too large is not read at all', () async {
      final file = _Huge();
      files.chosen = file;

      await cubit.open();

      expect(file.wasRead, isFalse);
      expect(cubit.state.notice, isA<CopyRefused>());
    });

    test('from a newer version asks for an update', () async {
      final json = jsonDecode(sampleCopy()) as Map<String, Object?>;
      json['version'] = LedgerCopy.version + 1;
      files.chosen = FakeFile('new.birka', jsonEncode(json));

      await cubit.open();

      expect(
        cubit.state.notice,
        isA<CopyRefused>().having(
          (it) => it.problem,
          'problem',
          LedgerCopyProblem.newer,
        ),
      );
    });
  });

  group('restoring', () {
    setUp(() async {
      files.chosen = FakeFile(
        'birka-2026-10-28.birka',
        sampleCopy(madeAt: DateTime.utc(2026, 10, 28, 18, 40)),
      );
      await cubit.open();
    });

    test('puts the copy in place of the ledger', () async {
      await cubit.restore();

      expect(repository.restored.single.counts.transactions, 1);
      expect(cubit.state.offer, isNull);
      expect(
        cubit.state.notice,
        isA<CopyRestored>().having(
          (it) => it.madeAt,
          'madeAt',
          DateTime.utc(2026, 10, 28, 18, 40),
        ),
      );
    });

    test('that fails says so and lets the copy go', () async {
      repository.failure = Exception('Disk full');

      await cubit.restore();

      expect(repository.restored, isEmpty);
      expect(cubit.state.offer, isNull);
      expect(cubit.state.notice, isA<BackupFailed>());
    });

    test('does not happen after a no', () async {
      cubit.dismiss();
      await cubit.restore();

      expect(cubit.state.offer, isNull);
      expect(repository.restored, isEmpty);
    });
  });

  test('exports the operations as a table', () async {
    await cubit.export();

    final file = files.saved.single;
    expect(file.name, 'birka-operations-2026-11-02.csv');
    expect(file.type, operationsFileType);
    // Excel reads Cyrillic only after the mark of UTF-8.
    expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(file.bytes), startsWith('Date,Type,Amount'));
    expect(cubit.state.notice, isA<OperationsExported>());
  });

  test('wipes the ledger', () async {
    await cubit.wipe();

    expect(repository.wipes, 1);
    expect(cubit.state.notice, isA<LedgerWiped>());
  });

  test('a wipe that fails says so', () async {
    repository.failure = Exception('Locked');

    await cubit.wipe();

    expect(cubit.state.notice, isA<BackupFailed>());
  });
}

/// A file far larger than a copy.
final class _Huge implements ChosenFile {
  bool wasRead = false;

  @override
  String get name => 'film.mov';

  @override
  Future<int?> length() async => largestCopy + 1;

  @override
  Future<Uint8List> read() async {
    wasRead = true;
    return Uint8List(0);
  }
}
