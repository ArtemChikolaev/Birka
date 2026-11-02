import 'dart:async';

import 'package:database/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

/// The site runs one drift server in a shared worker, and every tab is a
/// client of it that can close at any moment (ADR 0015).
void main() {
  late DriftServer server;

  setUp(
    () => server = DriftServer(DatabaseConnection(NativeDatabase.memory())),
  );
  tearDown(() => server.shutdown());

  StreamChannel<Object?> connect() {
    final controller = StreamChannelController<Object?>();
    unawaited(server.serve(controller.foreign));
    return controller.local;
  }

  Future<BirkaDatabase> open(StreamChannel<Object?> channel) async =>
      BirkaDatabase(await connectToRemoteAndInitialize(channel));

  Future<void> addCategory(BirkaDatabase database, String id) {
    final at = DateTime.utc(2026, 11, 2);
    return database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            createdAt: at,
            updatedAt: at,
            kind: 'expense',
            name: id,
          ),
        );
  }

  test(
    'a client that leaves in a transaction does not hold the others',
    () async {
      final leaving = connect();
      final first = await open(leaving);
      final inside = Completer<void>();
      unawaited(
        first
            .transaction(() async {
              await addCategory(first, 'left behind');
              inside.complete();
              // The tab closes here, before its transaction ends.
              await Completer<void>().future;
            })
            .then<void>((_) {}, onError: (Object _) {}),
      );
      await inside.future;
      await leaving.sink.close();

      final second = await open(connect());
      addTearDown(second.close);
      final categories = await second
          .select(second.categories)
          .get()
          .timeout(const Duration(seconds: 5));

      expect(categories, isEmpty, reason: 'its transaction is rolled back');
      await addCategory(second, 'written after');
      expect(await second.select(second.categories).get(), hasLength(1));
    },
  );

  test(
    'a client that leaves after its transaction keeps what it wrote',
    () async {
      final leaving = connect();
      final first = await open(leaving);
      await first.transaction(() => addCategory(first, 'kept'));
      await leaving.sink.close();

      final second = await open(connect());
      addTearDown(second.close);

      expect(await second.select(second.categories).get(), hasLength(1));
    },
  );
}
