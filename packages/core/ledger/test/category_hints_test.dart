import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

Transaction _operation(
  String id,
  String note,
  CivilDate day, {
  String? category,
  TransactionKind kind = TransactionKind.expense,
  String account = 'card',
  int amount = 145000,
  String? importId,
}) => Transaction(
  id: id,
  kind: kind,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: TransactionSource.import,
  entries: [
    Entry(
      accountId: account,
      amount: Money(
        kind == TransactionKind.expense ? -amount : amount,
        Currency.rub,
      ),
    ),
  ],
  allocations: [
    Allocation(categoryId: category, amount: Money(amount, Currency.rub)),
  ],
  importId: importId,
);

void main() {
  group('an operation of a name the person chose before', () {
    test('goes where they put it, how often and since when', () {
      final memory = CategoryMemory([
        _operation(
          'a',
          'ИП Соколов А. В.',
          CivilDate(2026, 9, 3),
          category: 'cafe',
        ),
        _operation(
          'b',
          'ИП Соколов А. В.',
          CivilDate(2026, 9, 12),
          category: 'cafe',
        ),
        _operation(
          'c',
          'ИП Соколов А. В.',
          CivilDate(2026, 9, 25),
          category: 'cafe',
        ),
      ]);

      final hint = memory.hintFor(
        _operation('new', 'ИП Соколов А. В.', CivilDate(2026, 10, 4)),
      )!;

      expect(hint.categoryId, 'cafe');
      expect(hint.reason, HintReason.sameName);
      expect(hint.count, 3);
      expect(hint.first, CivilDate(2026, 9, 3));
      expect(hint.last, CivilDate(2026, 9, 25));
    });

    test('meets it in capitals and with another number', () {
      final memory = CategoryMemory([
        _operation(
          'a',
          'Пятёрочка 5678',
          CivilDate(2026, 9, 3),
          category: 'food',
        ),
      ]);

      final hint = memory.hintFor(
        _operation('new', 'ПЯТЕРОЧКА 1234', CivilDate(2026, 10, 4)),
      );

      expect(hint?.categoryId, 'food');
      expect(hint?.reason, HintReason.sameName);
    });

    test('takes the category given most, or the latest of a tie', () {
      final memory = CategoryMemory([
        _operation('a', 'Озон', CivilDate(2026, 8, 3), category: 'home'),
        _operation('b', 'Озон', CivilDate(2026, 8, 9), category: 'shop'),
        _operation('c', 'Озон', CivilDate(2026, 9, 1), category: 'shop'),
        _operation('d', 'Лента', CivilDate(2026, 8, 3), category: 'food'),
        _operation('e', 'Лента', CivilDate(2026, 9, 3), category: 'home'),
      ]);

      expect(
        memory
            .hintFor(_operation('x', 'Озон', CivilDate(2026, 10, 1)))
            ?.categoryId,
        'shop',
      );
      expect(
        memory
            .hintFor(_operation('y', 'Лента', CivilDate(2026, 10, 1)))
            ?.categoryId,
        'home',
      );
    });

    test('of another kind says nothing', () {
      final memory = CategoryMemory([
        _operation(
          'a',
          'Возврат',
          CivilDate(2026, 9, 3),
          category: 'salary',
          kind: TransactionKind.income,
        ),
      ]);

      expect(
        memory.hintFor(_operation('x', 'Возврат', CivilDate(2026, 10, 1))),
        isNull,
      );
    });
  });

  group('the same amount month after month', () {
    final memory = CategoryMemory([
      _operation(
        'a',
        'APPLE.COM/BILL',
        CivilDate(2026, 7, 16),
        amount: 39900,
        category: 'subscriptions',
      ),
      _operation(
        'b',
        'APPLE.COM/BILL',
        CivilDate(2026, 8, 16),
        amount: 39900,
        category: 'subscriptions',
      ),
      _operation(
        'c',
        'Музыка',
        CivilDate(2026, 9, 16),
        amount: 39900,
        category: 'subscriptions',
      ),
      _operation(
        'd',
        'Музыка',
        CivilDate(2026, 9, 20),
        amount: 39900,
        account: 'cash',
        category: 'gifts',
      ),
    ]);

    test('goes into the category it had, since its first month', () {
      final hint = memory.hintFor(
        _operation(
          'new',
          'Подписка на музыку',
          CivilDate(2026, 10, 16),
          amount: 39900,
        ),
      )!;

      expect(hint.categoryId, 'subscriptions');
      expect(hint.reason, HintReason.everyMonth);
      expect(hint.first, CivilDate(2026, 7, 16));
    });

    test('of one month only, or of another account, says nothing', () {
      expect(
        memory.hintFor(
          _operation(
            'x',
            'Спортзал',
            CivilDate(2026, 8, 20),
            amount: 39900,
            account: 'cash',
          ),
        ),
        isNull,
      );
    });
  });

  group('a similar name', () {
    test('in other letters is that of the latest one', () {
      final memory = CategoryMemory([
        _operation(
          'a',
          'Барбершоп',
          CivilDate(2026, 8, 14),
          category: 'beauty',
        ),
      ]);

      final hint = memory.hintFor(
        _operation('new', 'BARBERSHOP 77', CivilDate(2026, 10, 14)),
      )!;

      expect(hint.categoryId, 'beauty');
      expect(hint.reason, HintReason.similarName);
      expect(hint.like, 'Барбершоп');
      expect(hint.last, CivilDate(2026, 8, 14));
    });

    test('of the same import wins over an older one', () {
      final memory = CategoryMemory([
        _operation(
          'a',
          'Маркетплейс',
          CivilDate(2026, 8, 2),
          category: 'gifts',
        ),
        _operation(
          'b',
          'Маркетплейс Озон',
          CivilDate(2026, 10, 12),
          category: 'shop',
          importId: 'october',
        ),
      ]);

      final hint = memory.hintFor(
        _operation(
          'new',
          'MARKET ONLINE',
          CivilDate(2026, 10, 21),
          importId: 'october',
        ),
      )!;

      expect(hint.categoryId, 'shop');
      expect(hint.reason, HintReason.sameImport);
      expect(hint.like, 'Маркетплейс Озон');
    });

    test('is never only a word that banks put everywhere', () {
      final memory = CategoryMemory([
        _operation(
          'a',
          'Перевод СБП Петрову',
          CivilDate(2026, 9, 2),
          category: 'gifts',
        ),
        _operation(
          'b',
          'Оплата картой',
          CivilDate(2026, 9, 3),
          category: 'shop',
        ),
      ]);

      expect(
        memory.hintFor(
          _operation('x', 'Перевод Ивану К.', CivilDate(2026, 10, 9)),
        ),
        isNull,
      );
      expect(
        memory.hintFor(_operation('y', 'Оплата услуг', CivilDate(2026, 10, 9))),
        isNull,
      );
    });
  });

  test('remembers only operations of one category', () {
    final memory = CategoryMemory([
      _operation('a', 'Кофейня', CivilDate(2026, 9, 3)),
      Transaction(
        id: 'b',
        kind: TransactionKind.expense,
        occurredOn: CivilDate(2026, 9, 4),
        note: 'Кофейня',
        status: TransactionStatus.cleared,
        source: TransactionSource.manual,
        entries: [Entry(accountId: 'card', amount: Money(-1000, Currency.rub))],
        allocations: [
          Allocation(categoryId: 'cafe', amount: Money(500, Currency.rub)),
          Allocation(categoryId: 'food', amount: Money(500, Currency.rub)),
        ],
      ),
    ]);

    expect(
      memory.hintFor(_operation('x', 'Кофейня', CivilDate(2026, 10, 1))),
      isNull,
    );
  });

  test('a name is its words without digits, alike in Latin letters', () {
    expect(nameKey('Пятёрочка 1234'), 'пятерочка');
    expect(nameKey('ZHKU MOSKVA'), 'zhku moskva');
    expect(nameWords('Перевод Ивану К. по СБП'), {'ivanu'});
  });

  test('the tree of categories puts each parent before its own', () {
    Category category(
      String id, {
      String? parentId,
      CategoryKind kind = CategoryKind.expense,
      bool archived = false,
    }) => Category(
      id: id,
      kind: kind,
      name: id,
      archived: archived,
      sortOrder: 0,
      parentId: parentId,
    );

    final tree = categoryTree([
      category('food'),
      category('home'),
      category('rent', parentId: 'home'),
      category('market', parentId: 'food'),
      category('old', archived: true),
      category('salary', kind: CategoryKind.income),
    ], CategoryKind.expense);

    expect(
      [for (final it in tree) '${it.nested ? '  ' : ''}${it.category.id}'],
      [
        'food',
        '  market',
        'home',
        '  rent',
      ],
    );
  });
}
