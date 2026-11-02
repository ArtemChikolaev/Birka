import 'dart:convert';

import 'package:ledger/ledger.dart';
import 'package:test/test.dart';

/// A copy with a card in rubles, a wallet in euros, a category with a
/// subcategory, a salary and four transactions of every kind.
Map<String, Object?> sample() {
  Map<String, Object?> stamps(String id) => {
    'id': id,
    'createdAt': '2026-10-01T09:00:00.000Z',
    'updatedAt': '2026-10-02T09:00:00.000Z',
  };
  Map<String, Object?> account(String id, String currency, {int digits = 2}) =>
      {
        ...stamps(id),
        'name': 'Account $id',
        'type': 'debit',
        'currency': currency,
        'decimalDigits': digits,
        'openingBalanceMinor': 100000,
        'lastDigits': '4568',
        'art': 'emerald',
        'includeInTotals': true,
        'archived': false,
        'sortOrder': 0,
      };
  Map<String, Object?> category(String id, String kind, {String? parentId}) => {
    ...stamps(id),
    'parentId': parentId,
    'kind': kind,
    'name': 'Category $id',
    'icon': 'cup',
    'color': '#4ade80',
    'archived': false,
    'sortOrder': 0,
  };
  Map<String, Object?> transaction(
    String id,
    String kind, {
    required List<Map<String, Object?>> entries,
    List<Map<String, Object?>> allocations = const [],
  }) => {
    ...stamps(id),
    'kind': kind,
    'occurredOn': '2026-10-28',
    'occurredAt': '2026-10-28T18:40:00.000Z',
    'note': '',
    'status': 'cleared',
    'source': 'manual',
    'entries': entries,
    'allocations': allocations,
  };
  Map<String, Object?> entry(String id, String accountId, int amount) => {
    ...stamps(id),
    'accountId': accountId,
    'amountMinor': amount,
  };
  Map<String, Object?> allocation(String id, String categoryId, int amount) => {
    ...stamps(id),
    'categoryId': categoryId,
    'amountMinor': amount,
  };

  return {
    'format': 'birka-copy',
    'version': 1,
    'madeAt': '2026-10-28T18:40:00.000Z',
    'accounts': [account('card', 'RUB'), account('wallet', 'EUR')],
    'categories': [
      // The child comes first: the order of a file does not matter.
      category('cafe', 'expense', parentId: 'food'),
      category('food', 'expense'),
      category('salary', 'income'),
    ],
    'transactions': [
      transaction(
        'lunch',
        'expense',
        entries: [entry('e1', 'card', -45000)],
        allocations: [
          allocation('a1', 'cafe', 30000),
          allocation('a2', 'food', 15000),
        ],
      ),
      transaction(
        'pay',
        'income',
        entries: [entry('e2', 'card', 9000000)],
        allocations: [allocation('a3', 'salary', 9000000)],
      ),
      transaction(
        'exchange',
        'transfer',
        entries: [entry('e3', 'card', -1000000), entry('e4', 'wallet', 10000)],
      ),
      transaction(
        'fix',
        'adjustment',
        entries: [entry('e5', 'wallet', -150)],
      ),
    ],
  };
}

/// The rows under [key] in [json], to break one of them.
List<Map<String, Object?>> rowsOf(Map<String, Object?> json, String key) =>
    (json[key]! as List).cast();

/// The transactions of [json].
List<Map<String, Object?>> transactionsOf(Map<String, Object?> json) =>
    rowsOf(json, 'transactions');

/// The legs of the transaction [id] in [json].
List<Map<String, Object?>> legsOf(
  Map<String, Object?> json,
  String id,
  String legs,
) => (transactionsOf(json).singleWhere((it) => it['id'] == id)[legs]! as List)
    .cast();

Matcher throwsProblem(LedgerCopyProblem problem) => throwsA(
  isA<LedgerCopyException>().having((it) => it.problem, 'problem', problem),
);

void main() {
  test('reads a copy and says how much it holds and when it was made', () {
    final copy = LedgerCopy.parse(jsonEncode(sample()));

    expect(
      copy.counts,
      const LedgerCounts(accounts: 2, categories: 3, transactions: 4),
    );
    expect(copy.madeAt, DateTime.utc(2026, 10, 28, 18, 40));
    expect(copy.madeAt.isUtc, isTrue);
  });

  test('writes what it reads, and reads what it writes', () {
    final copy = LedgerCopy.parse(jsonEncode(sample()));
    final again = LedgerCopy.parse(copy.encode());

    expect(again.encode(), copy.encode());
    expect(again.counts, copy.counts);
    expect(again.entryRows.map((row) => row.amountMinor), [
      -45000,
      9000000,
      -1000000,
      10000,
      -150,
    ]);
    expect(again.entryRows.first.transactionId, 'lunch');
  });

  test('keeps parents before their subcategories for the restore', () {
    final copy = LedgerCopy.parse(jsonEncode(sample()));

    expect(copy.categoryRows.map((row) => row.id), ['food', 'salary', 'cafe']);
  });

  test('keeps every field of the rows', () {
    final copy = LedgerCopy.parse(jsonEncode(sample()));
    final card = copy.accountRows.first;
    final cafe = copy.categoryRows.last;
    final lunch = copy.transactionRows.first;

    expect(card.lastDigits, '4568');
    expect(card.openingBalanceMinor, 100000);
    expect(card.createdAt, DateTime.utc(2026, 10, 1, 9));
    expect(card.updatedAt, DateTime.utc(2026, 10, 2, 9));
    expect(card.deletedAt, isNull);
    expect(cafe.parentId, 'food');
    expect(cafe.color, '#4ade80');
    expect(lunch.occurredOn, '2026-10-28');
    expect(lunch.occurredAt, DateTime.utc(2026, 10, 28, 18, 40));
  });

  test('takes an empty ledger', () {
    final json = sample()
      ..['accounts'] = <Object?>[]
      ..['categories'] = <Object?>[]
      ..['transactions'] = <Object?>[];

    expect(LedgerCopy.parse(jsonEncode(json)).counts.isEmpty, isTrue);
  });

  group('says that a file is not a copy', () {
    test('when it is not JSON', () {
      expect(
        () => LedgerCopy.parse('date;amount\n2026-10-28;100'),
        throwsProblem(LedgerCopyProblem.notACopy),
      );
    });

    test('when it is JSON without the mark of the format', () {
      expect(
        () => LedgerCopy.parse('{"accounts": []}'),
        throwsProblem(LedgerCopyProblem.notACopy),
      );
      expect(
        () => LedgerCopy.parse('[1, 2]'),
        throwsProblem(LedgerCopyProblem.notACopy),
      );
    });
  });

  test('says when a newer version made the copy', () {
    final json = sample()..['version'] = LedgerCopy.version + 1;

    expect(
      () => LedgerCopy.parse(jsonEncode(json)),
      throwsProblem(LedgerCopyProblem.newer),
    );
  });

  group('refuses a damaged copy', () {
    void expectDamaged(void Function(Map<String, Object?> json) damage) {
      final json = sample();
      damage(json);
      expect(
        () => LedgerCopy.parse(jsonEncode(json)),
        throwsProblem(LedgerCopyProblem.damaged),
      );
    }

    test('without a version', () {
      expectDamaged((json) => json.remove('version'));
    });

    test('with a field missing or of another type', () {
      expectDamaged((json) => rowsOf(json, 'accounts').first.remove('name'));
      expectDamaged(
        (json) => rowsOf(json, 'accounts').first['sortOrder'] = '0',
      );
      expectDamaged((json) => json['transactions'] = {});
      expectDamaged(
        (json) => json['categories'] = [...rowsOf(json, 'categories'), 'food'],
      );
    });

    test('with a moment or a day that does not exist', () {
      expectDamaged((json) => json['madeAt'] = 'yesterday');
      expectDamaged(
        (json) => transactionsOf(json).first['occurredOn'] = '28.10',
      );
      expectDamaged(
        (json) => transactionsOf(json).first['occurredOn'] = '2026-02-30',
      );
    });

    test('with a name that the ledger does not know', () {
      expectDamaged(
        (json) => rowsOf(json, 'accounts').first['type'] = 'piggy bank',
      );
      expectDamaged((json) => transactionsOf(json).first['status'] = 'lost');
    });

    test('with an amount that does not fit the money of the account', () {
      expectDamaged(
        (json) => rowsOf(json, 'accounts').first['currency'] = 'rub',
      );
      expectDamaged(
        (json) => rowsOf(json, 'accounts').first['decimalDigits'] = 40,
      );
      expectDamaged(
        (json) => legsOf(json, 'fix', 'entries').first['amountMinor'] =
            9007199254740991 + 1,
      );
    });

    test('with an id twice', () {
      expectDamaged((json) {
        final accounts = rowsOf(json, 'accounts');
        accounts.add({...accounts.first});
      });
      expectDamaged(
        (json) => legsOf(json, 'pay', 'entries').first['id'] = 'e1',
      );
    });

    test('with a color that a screen could not draw', () {
      expectDamaged(
        (json) => rowsOf(json, 'categories').first['color'] = 'green',
      );
    });

    test('with categories that break their two levels', () {
      expectDamaged(
        (json) => rowsOf(json, 'categories').first['parentId'] = 'gone',
      );
      expectDamaged(
        (json) => rowsOf(json, 'categories')[1]['parentId'] = 'cafe',
      );
      expectDamaged(
        (json) => rowsOf(json, 'categories').first['parentId'] = 'salary',
      );
    });

    test('with money on an account that it does not have', () {
      expectDamaged(
        (json) => legsOf(json, 'lunch', 'entries').first['accountId'] = 'gone',
      );
    });

    test('with a category of another kind or none', () {
      expectDamaged(
        (json) =>
            legsOf(json, 'lunch', 'allocations').first['categoryId'] = 'salary',
      );
      expectDamaged(
        (json) =>
            legsOf(json, 'lunch', 'allocations').first['categoryId'] = 'gone',
      );
    });

    test('with an expense that its categories do not add up to', () {
      expectDamaged(
        (json) => legsOf(json, 'lunch', 'allocations').first['amountMinor'] = 1,
      );
      expectDamaged((json) => legsOf(json, 'lunch', 'allocations').clear());
    });

    test('with legs that its kind does not have', () {
      expectDamaged(
        (json) =>
            legsOf(json, 'exchange', 'entries').first['accountId'] = 'wallet',
      );
      expectDamaged(
        (json) =>
            legsOf(json, 'exchange', 'entries').first['amountMinor'] = 1000000,
      );
      expectDamaged((json) => legsOf(json, 'fix', 'entries').clear());
      expectDamaged(
        (json) => legsOf(json, 'fix', 'entries').first['amountMinor'] = 0,
      );
    });
  });
}
