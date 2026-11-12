@TestOn('vm')
library;

import 'dart:convert';

import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

final gel = Currency.custom('GEL', decimalDigits: 2);

Money lari(int minorUnits) => Money(minorUnits, gel);
Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

CivilDate nov(int day) => CivilDate(2026, 11, day);

Matcher throwsLedger() => throwsA(isA<LedgerException>());

/// The clock of the ledger: the last day of a trip to Tbilisi.
final now = DateTime.utc(2026, 11, 12, 12);

void main() {
  late BirkaDatabase database;
  late LedgerRepository ledger;
  late Account card;
  late Account lariCard;
  late Category cafe;
  late Category salary;
  final tbilisi = TagDays(nov(3), nov(12));

  setUp(() async {
    database = BirkaDatabase(NativeDatabase.memory());
    ledger = LedgerRepository(database, now: () => now);
    card = await ledger.addAccount(
      name: 'Card',
      type: AccountType.debit,
      openingBalance: rub(8640000),
    );
    lariCard = await ledger.addAccount(
      name: 'Lari',
      type: AccountType.debit,
      openingBalance: lari(500000),
    );
    cafe = await ledger.addCategory(kind: CategoryKind.expense, name: 'Cafe');
    salary = await ledger.addCategory(
      kind: CategoryKind.income,
      name: 'Salary',
    );
  });

  tearDown(() => database.close());

  TransactionDraft lunch(
    CivilDate day, {
    TransactionSource source = TransactionSource.manual,
  }) => TransactionDraft.expense(
    accountId: lariCard.id,
    allocations: [Allocation(categoryId: cafe.id, amount: lari(3800))],
    occurredOn: day,
    source: source,
  );

  Future<String> spend(
    CivilDate day, {
    Set<String>? tags,
    TransactionSource source = TransactionSource.manual,
  }) {
    final draft = lunch(day, source: source);
    return ledger.record(tags == null ? draft : draft.withTags(tags));
  }

  Future<Map<String, TagMark>> tagsOf(String id) async =>
      (await ledger.watchTransaction(id).first)!.tags;

  Future<Tag> trip({bool marksDays = true, TagDays? days}) async =>
      (await ledger.addTag(
        name: 'Тбилиси',
        days: days ?? tbilisi,
        marksDays: marksDays,
      )).tag;

  group('a trip that marks its days', () {
    test('goes onto a new expense of its days by itself', () async {
      final tag = await trip();

      final id = await spend(nov(12));

      expect(await tagsOf(id), {tag.id: TagMark.days});
      final transaction = await ledger.watchTransaction(id).first;
      expect(transaction!.tagIds, [tag.id]);
    });

    test(
      'leaves out incomes, transfers, regular payments and other days',
      () async {
        await trip();

        final income = await ledger.record(
          TransactionDraft.income(
            accountId: lariCard.id,
            allocations: [
              Allocation(categoryId: salary.id, amount: lari(9000)),
            ],
            occurredOn: nov(5),
          ),
        );
        final transfer = await ledger.record(
          TransactionDraft.transfer(
            fromAccountId: card.id,
            sent: rub(300500),
            toAccountId: lariCard.id,
            received: lari(10000),
            occurredOn: nov(5),
          ),
        );
        final rent = await spend(nov(5), source: TransactionSource.recurring);
        final after = await spend(nov(13));
        final before = await spend(nov(2));

        for (final id in [income, transfer, rent, after, before]) {
          expect(await tagsOf(id), isEmpty, reason: id);
        }
      },
    );

    test('marks nothing when it only names its days', () async {
      final tag = await trip(marksDays: false);

      final id = await spend(nov(12));

      expect(await tagsOf(id), isEmpty);
      expect(tag.isTrip, isTrue);
    });

    test('marks nothing once archived', () async {
      final tag = await trip();
      await ledger.updateTag(tag.copyWith(archived: true));

      expect(await tagsOf(await spend(nov(12))), isEmpty);
      expect(await ledger.watchTags().first, isEmpty);
      expect(await ledger.watchTags(includeArchived: true).first, hasLength(1));
    });

    test('stays on what it marked once archived', () async {
      final tag = await trip();
      final first = await spend(nov(4));
      final second = await spend(nov(11));

      final archived = await ledger.updateTag(tag.copyWith(archived: true));

      expect(archived.marked, 0);
      expect(await tagsOf(first), {tag.id: TagMark.days});
      expect(await tagsOf(second), {tag.id: TagMark.days});

      await ledger.updateTag(archived.tag.copyWith(archived: false));

      expect(await ledger.watchTransactions(tagId: tag.id).first, hasLength(2));
    });

    test('once archived, stays through a change and a pick', () async {
      final tag = await trip();
      final work = (await ledger.addTag(name: 'Работа')).tag;
      final moved = await spend(nov(4));
      final picked = await spend(nov(11));
      final archived = await ledger.updateTag(tag.copyWith(archived: true));

      await ledger.amend(moved, lunch(nov(20)));
      await ledger.setTags(picked, {work.id});

      expect(await tagsOf(moved), {tag.id: TagMark.days});
      expect(await tagsOf(picked), {
        tag.id: TagMark.days,
        work.id: TagMark.hand,
      });

      // Back in the lists, the trip follows its days again.
      await ledger.updateTag(archived.tag.copyWith(archived: false));

      expect(await tagsOf(moved), isEmpty);
      expect(await tagsOf(picked), {
        tag.id: TagMark.days,
        work.id: TagMark.hand,
      });
    });
  });

  group('a trip added after its days', () {
    test('marks the expenses of its days at once and says how many', () async {
      final first = await spend(nov(4));
      final second = await spend(nov(11));
      final rent = await spend(nov(5), source: TransactionSource.recurring);
      final home = await spend(nov(20));

      final marking = await ledger.addTag(
        name: 'Тбилиси',
        days: tbilisi,
        marksDays: true,
      );

      expect(marking.marked, 2);
      expect(await tagsOf(first), {marking.tag.id: TagMark.days});
      expect(await tagsOf(second), {marking.tag.id: TagMark.days});
      expect(await tagsOf(rent), isEmpty);
      expect(await tagsOf(home), isEmpty);
    });

    test('takes back what its days put on and keeps what the person put on '
        'by hand', () async {
      final onTheSpot = await spend(nov(4));
      final tickets = await spend(CivilDate(2026, 10, 14));
      final tag = await trip();
      await ledger.setTags(tickets, {tag.id});

      await ledger.unmarkDays(tag.id);

      expect(await tagsOf(onTheSpot), isEmpty);
      expect(await tagsOf(tickets), {tag.id: TagMark.hand});
      expect((await ledger.tag(tag.id))!.marksDays, isFalse);
      expect(await tagsOf(await spend(nov(12))), isEmpty);
    });
  });

  test('a trip whose days change moves its marks and keeps the hand', () async {
    final early = await spend(nov(2));
    final last = await spend(nov(12));
    final tickets = await spend(CivilDate(2026, 10, 14));
    final tag = await trip();
    await ledger.setTags(tickets, {tag.id});

    final marking = await ledger.updateTag(
      tag.copyWith(days: () => TagDays(nov(2), nov(11))),
    );

    expect(marking.marked, 1);
    expect(await tagsOf(early), {tag.id: TagMark.days});
    expect(await tagsOf(last), isEmpty);
    expect(await tagsOf(tickets), {tag.id: TagMark.hand});
  });

  group('what the person picks', () {
    test('a trip of the days that is not picked stays off for good', () async {
      final tag = await trip();

      final id = await spend(nov(12), tags: {});
      await ledger.updateTag(tag.copyWith(name: 'Тбилиси, осень'));

      expect(await tagsOf(id), {tag.id: TagMark.off});
      expect((await ledger.watchTransaction(id).first)!.tagIds, isEmpty);
      final wearing = await ledger.watchTransactions(tagId: tag.id).first;
      expect(wearing, isEmpty);
    });

    test('a picked trip of the days counts as put on by them, another метка '
        'as put on by hand', () async {
      final tag = await trip();
      final work = (await ledger.addTag(name: 'Работа')).tag;

      final id = await spend(nov(12), tags: {tag.id, work.id});

      expect(await tagsOf(id), {tag.id: TagMark.days, work.id: TagMark.hand});
    });

    test('changes the метки of a transaction on its own', () async {
      final tag = await trip();
      final work = (await ledger.addTag(name: 'Работа')).tag;
      final id = await spend(nov(12));

      await ledger.setTags(id, {work.id});

      expect(await tagsOf(id), {tag.id: TagMark.off, work.id: TagMark.hand});

      await ledger.setTags(id, {tag.id});

      expect(await tagsOf(id), {tag.id: TagMark.days});
    });

    test('a метка that does not exist breaks the write', () async {
      await expectLater(spend(nov(12), tags: {'nope'}), throwsLedger());
      await expectLater(
        ledger.setTags(await spend(nov(12)), {'nope'}),
        throwsLedger(),
      );
    });
  });

  test('a changed transaction keeps its метки and follows the days', () async {
    final tag = await trip();
    final work = (await ledger.addTag(name: 'Работа')).tag;
    final id = await spend(nov(12));
    await ledger.setTags(id, {tag.id, work.id});

    await ledger.amend(id, lunch(nov(20)));

    expect(await tagsOf(id), {work.id: TagMark.hand});

    await ledger.amend(id, lunch(nov(11)));

    expect(await tagsOf(id), {tag.id: TagMark.days, work.id: TagMark.hand});
  });

  test('a transaction that goes takes its метки along', () async {
    final tag = await trip();
    final id = await spend(nov(12));

    await ledger.delete(id);

    expect(await ledger.watchTransactions(tagId: tag.id).first, isEmpty);
    expect((await ledger.copy()).transactionTagRows, isEmpty);
  });

  test('the transactions of a метка are those that wear it', () async {
    final tag = await trip();
    final first = await spend(nov(4));
    final second = await spend(nov(12));
    await spend(nov(20));

    final wearing = await ledger.watchTransactions(tagId: tag.id).first;
    final work = (await ledger.addTag(name: 'Работа')).tag;
    final home = await spend(nov(20));
    await ledger.setTags(home, {work.id});
    final tagged = await ledger.watchTransactions(tagged: true).first;

    expect(wearing.map((it) => it.id), [second, first]);
    expect(tagged.map((it) => it.id), [home, second, first]);
  });

  test('a метка needs a name', () async {
    await expectLater(ledger.addTag(name: '  '), throwsLedger());
    await expectLater(
      ledger.addTag(name: ' Ремонт кухни '),
      completion(
        isA<TagMarking>().having((it) => it.tag.name, 'name', 'Ремонт кухни'),
      ),
    );
  });

  test('the метки list the trips by their days, then the others', () async {
    await ledger.addTag(name: 'Работа');
    await ledger.addTag(
      name: 'Ереван',
      days: TagDays(CivilDate(2026, 3, 12), CivilDate(2026, 3, 16)),
    );
    await trip();
    await ledger.addTag(name: 'Ремонт кухни');

    final tags = await ledger.watchTags().first;

    expect(tags.map((it) => it.name), [
      'Тбилиси',
      'Ереван',
      'Работа',
      'Ремонт кухни',
    ]);
  });

  group('a copy', () {
    test('keeps the метки and their marks through a restore', () async {
      final tag = await trip();
      final work = (await ledger.addTag(name: 'Работа')).tag;
      final id = await spend(nov(12));
      await ledger.setTags(id, {work.id});
      final copy = LedgerCopy.parse((await ledger.copy()).encode());
      final other = BirkaDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final restored = LedgerRepository(other, now: () => now);

      await restored.restore(copy);

      expect(await restored.watchTags().first, await ledger.watchTags().first);
      expect((await restored.watchTransaction(id).first)!.tags, {
        tag.id: TagMark.off,
        work.id: TagMark.hand,
      });
    });

    test('of version 7 reads with no метки', () async {
      await trip();
      await spend(nov(12));
      final json =
          (jsonDecode((await ledger.copy()).encode()) as Map<String, Object?>)
            ..['version'] = 7
            ..remove('tags');
      for (final transaction in json['transactions']! as List<Object?>) {
        (transaction! as Map<String, Object?>).remove('marks');
      }

      final copy = LedgerCopy.parse(jsonEncode(json));

      expect(copy.tagRows, isEmpty);
      expect(copy.transactionTagRows, isEmpty);
      expect(copy.counts.transactions, 1);
    });

    test('with a mark of no метка is damaged', () async {
      await trip();
      await spend(nov(12));
      final json =
          (jsonDecode((await ledger.copy()).encode()) as Map<String, Object?>)
            ..remove('tags');

      expect(
        () => LedgerCopy.parse(jsonEncode(json)),
        throwsA(
          isA<LedgerCopyException>().having(
            (it) => it.problem,
            'problem',
            LedgerCopyProblem.damaged,
          ),
        ),
      );
    });
  });
}
