@TestOn('vm')
library;

import 'package:ask_common/ask_common.dart';
import 'package:database/database.dart';
import 'package:device_settings/device_settings.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late BirkaDatabase database;
  late _Store store;
  late LedgerAskRepository repository;

  setUp(() {
    database = BirkaDatabase(NativeDatabase.memory());
    store = _Store();
    repository = LedgerAskRepository(
      LedgerRepository(database),
      RatesRepository(database),
      BaseCurrency(null),
      MonthStart(1),
      store,
      now: () => DateTime(2026, 11, 12, 9),
    );
  });

  tearDown(() => database.close());

  test(
    'keeps the questions asked last with the settings of the device',
    () async {
      expect(repository.recent(), isEmpty);

      await repository.keepRecent(const ['кафе в октябре', 'курс лари']);

      expect(store.values[LedgerAskRepository.recentKey], isNotNull);
      expect(repository.recent(), ['кафе в октябре', 'курс лари']);
    },
  );

  test('reads nothing from a broken setting', () {
    store.values[LedgerAskRepository.recentKey] = '{not json';
    expect(repository.recent(), isEmpty);

    store.values[LedgerAskRepository.recentKey] = '{"a": 1}';
    expect(repository.recent(), isEmpty);
  });

  test('tells the day of the device', () {
    expect(repository.today(), CivilDate(2026, 11, 12));
  });
}
