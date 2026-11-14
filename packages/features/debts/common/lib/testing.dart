/// The debts, accounts and rates of the boards «Кто кому должен» (ADR 0029)
/// and a repository that keeps them in memory, for the tests of both hosts.
library;

import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:decimal/decimal.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// Saturday, November 14, 2026: the day of the boards.
final boardToday = CivilDate(2026, 11, 14);

/// [units] whole units of [currency].
Money units(int units, Currency currency) => Money(units * 100, currency);

/// [units] whole rubles.
Money rub(int units) => Money(units * 100, Currency.rub);

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

/// An account of the person.
Account own(String id, String name, Currency currency) => Account(
  id: id,
  name: name,
  type: AccountType.debit,
  openingBalance: Money.zero(currency),
  includeInTotals: true,
  archived: false,
  sortOrder: 0,
);

/// A debt with [name] on [side], of person [personId] or `p-<id>`.
Account debtAccount(
  String id,
  String name,
  DebtSide side, {
  Currency currency = Currency.rub,
  CivilDate? dueOn,
  bool reminds = false,
  AccountArt art = AccountArt.emerald,
  String? personId,
}) => Account(
  id: id,
  name: name,
  type: AccountType.debt,
  openingBalance: Money.zero(currency),
  includeInTotals: false,
  archived: false,
  sortOrder: 0,
  art: art,
  debt: DebtTerms(side: side, dueOn: dueOn, reminds: reminds),
  personId: personId ?? 'p-$id',
);

/// The people of [debts]: one for each person they point at, by the name
/// of the first debt.
List<Person> peopleOf(List<Account> debts) {
  final people = <String, Person>{};
  for (final debt in debts) {
    final id = debt.personId;
    if (id != null) {
      people.putIfAbsent(id, () => Person(id: id, name: debt.name));
    }
  }
  return [...people.values];
}

/// A transfer of [amount] from [from] to [to] on [day].
Transaction transfer(
  String id,
  String from,
  String to,
  Money amount,
  CivilDate day, {
  String note = '',
}) => Transaction(
  id: id,
  kind: TransactionKind.transfer,
  occurredOn: day,
  note: note,
  status: TransactionStatus.cleared,
  source: TransactionSource.manual,
  entries: [
    Entry(accountId: from, amount: -amount),
    Entry(accountId: to, amount: amount),
  ],
  allocations: const [],
);

/// The accounts of the person on the boards.
List<Account> boardAccounts() => [
  own('card', 'Зарплатная карта', Currency.rub),
  own('cash', 'Наличные', Currency.rub),
  own('savings', 'Накопления', Currency.usd),
];

/// The debts of the boards: Дима owes 120 $ due today, Маша 3 000 ₽ of
/// 5 000 ₽ by 1 December, the person owes Саша 4 000 ₽ by 20 November, and
/// Ира and Папа gave everything back.
List<Account> boardDebts() => [
  debtAccount(
    'dima',
    'Дима',
    DebtSide.lent,
    currency: Currency.usd,
    dueOn: boardToday,
    reminds: true,
    art: AccountArt.sapphire,
  ),
  debtAccount(
    'masha',
    'Маша',
    DebtSide.lent,
    dueOn: CivilDate(2026, 12, 1),
    reminds: true,
  ),
  debtAccount(
    'sasha',
    'Саша',
    DebtSide.borrowed,
    dueOn: CivilDate(2026, 11, 20),
    art: AccountArt.amber,
  ),
  debtAccount('ira', 'Ира', DebtSide.lent, art: AccountArt.rose),
  debtAccount('dad', 'Папа', DebtSide.lent, art: AccountArt.violet),
];

/// The transfers of the debts of the boards.
List<Transaction> boardTransfers() => [
  transfer(
    'dima-lent',
    'savings',
    'dima',
    units(120, Currency.usd),
    CivilDate(2026, 10, 20),
    note: 'за квартиру',
  ),
  transfer(
    'masha-lent',
    'cash',
    'masha',
    rub(5000),
    CivilDate(2026, 11, 3),
    note: 'на билеты',
  ),
  transfer('masha-back', 'masha', 'card', rub(2000), CivilDate(2026, 11, 10)),
  transfer(
    'sasha-borrowed',
    'sasha',
    'card',
    rub(4000),
    CivilDate(2026, 11, 8),
    note: 'до зарплаты',
  ),
  transfer('ira-lent', 'card', 'ira', rub(1500), CivilDate(2026, 10, 25)),
  transfer('ira-back', 'ira', 'card', rub(1500), CivilDate(2026, 11, 2)),
  transfer('dad-lent', 'card', 'dad', rub(10000), CivilDate(2026, 10, 1)),
  transfer('dad-back', 'dad', 'card', rub(10000), CivilDate(2026, 10, 30)),
];

/// The rates of the boards: a dollar costs 81,40 ₽.
RateBook boardRates() => RateBook([
  DayRates(boardToday, {'USD': Decimal.parse('81.40')}),
]);

/// Keeps the debts in memory, as the ledger would.
final class FakeDebtsRepository implements DebtsRepository {
  /// Creates a repository with the story of the boards, or with [accounts],
  /// [debts] and [transfers] of a test.
  FakeDebtsRepository({
    List<Account>? accounts,
    List<Account>? debts,
    List<Person>? people,
    List<Transaction>? transfers,
    RateBook? rates,
    this.base,
    CivilDate? today,
    this.failing = false,
  }) : _accounts = accounts ?? boardAccounts(),
       _debts = debts ?? boardDebts(),
       _people = people ?? peopleOf(debts ?? boardDebts()),
       _transfers = transfers ?? boardTransfers(),
       _rates = rates ?? boardRates(),
       _today = today ?? boardToday;

  final List<Account> _accounts;
  final List<Account> _debts;
  final List<Person> _people;
  final List<Transaction> _transfers;
  final RateBook _rates;
  final CivilDate _today;

  /// The currency of the totals, or `null` to follow the first account.
  final Currency? base;

  /// Whether every read fails.
  final bool failing;

  final _changes = StreamController<void>.broadcast();
  var _next = 0;

  /// The debts as the ledger holds them now, settled ones too.
  List<Account> get debts => List.unmodifiable(_debts);

  /// The people of the debts as the ledger holds them now.
  List<Person> get people => List.unmodifiable(_people);

  /// The transfers as the ledger holds them now.
  List<Transaction> get transfers => List.unmodifiable(_transfers);

  @override
  CivilDate today() => _today;

  /// What [read] gives now, and again after every change. A cancel gives
  /// back no future: one of a broadcast stream completes in the root zone,
  /// which the fake time of a widget test never runs, so `first` would wait
  /// for it forever.
  Stream<T> _follow<T>(T Function() read) {
    if (failing) return Stream.error(StateError('No ledger'));
    return Stream.multi((controller) {
      controller.add(read());
      final subscription = _changes.stream.listen(
        (_) => controller.add(read()),
      );
      controller.onCancel = () => unawaited(subscription.cancel());
    });
  }

  List<Debt> _read() => debtsOf(
    _debts,
    _transfers,
    accounts: {
      for (final account in [..._accounts, ..._debts]) account.id: account,
    },
  );

  @override
  Stream<List<Person>> watchPeople() => _follow(() => [..._people]);

  @override
  Stream<List<Debt>> watchDebts() => _follow(_read);

  @override
  Stream<List<AccountBalance>> watchAccounts() => _follow(
    () => [
      for (final account in _accounts)
        AccountBalance(account, _balanceOf(account)),
    ],
  );

  Money _balanceOf(Account account) {
    var balance = account.openingBalance;
    for (final transfer in _transfers) {
      for (final entry in transfer.entries) {
        if (entry.accountId == account.id) balance += entry.amount;
      }
    }
    return balance;
  }

  @override
  Stream<RateBook> watchRates() => Stream.value(_rates);

  @override
  Stream<Currency?> watchBaseCurrency() => Stream.value(base);

  @override
  Stream<Currency?> watchMainCurrency() => Stream.value(Currency.rub);

  @override
  Future<String> open({
    required String name,
    required DebtSide side,
    required String accountId,
    required Money amount,
    required CivilDate day,
    String? debtId,
    String? personId,
    String about = '',
    String? phone,
    String note = '',
    DebtTerms? terms,
  }) async {
    var index = _debts.indexWhere(
      (debt) => debtId != null
          ? debt.id == debtId
          : personId != null &&
                debt.personId == personId &&
                debt.debt?.side == side &&
                debt.currency == amount.currency,
    );
    if (index < 0) {
      final person =
          _people.where((it) => it.id == personId).firstOrNull ??
          Person(
            id: 'person-${_next++}',
            name: name.trim(),
            about: about.trim(),
            phone: phone,
          );
      if (!_people.contains(person)) _people.add(person);
      _debts.add(
        debtAccount(
          'debt-${_next++}',
          person.name,
          side,
          currency: amount.currency,
          dueOn: terms?.dueOn,
          reminds: terms?.reminds ?? false,
          personId: person.id,
        ),
      );
      index = _debts.length - 1;
    } else if (terms != null) {
      _debts[index] = _withTerms(_debts[index], terms);
    }
    final id = _debts[index].id;
    final lends = side == DebtSide.lent;
    _transfers.add(
      transfer(
        'transfer-${_next++}',
        lends ? accountId : id,
        lends ? id : accountId,
        amount,
        day,
        note: note.trim(),
      ),
    );
    _changes.add(null);
    return id;
  }

  @override
  Future<void> settle(
    String debtId, {
    required String accountId,
    required Money amount,
    required CivilDate day,
  }) async {
    final debt = _debts.firstWhere((debt) => debt.id == debtId);
    final back = debt.debt?.side == DebtSide.lent;
    _transfers.add(
      transfer(
        'transfer-${_next++}',
        back ? debtId : accountId,
        back ? accountId : debtId,
        amount,
        day,
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> update(
    String debtId, {
    required String name,
    required DebtTerms terms,
    String about = '',
    String? phone,
  }) async {
    final index = _debts.indexWhere((debt) => debt.id == debtId);
    final personId = _debts[index].personId;
    final at = _people.indexWhere((it) => it.id == personId);
    if (at >= 0) {
      _people[at] = _people[at].copyWith(
        name: name.trim(),
        about: about.trim(),
        phone: () => phone,
      );
    }
    _debts[index] = _withTerms(_debts[index], terms);
    for (var i = 0; i < _debts.length; i++) {
      if (_debts[i].personId == personId) {
        _debts[i] = _withTerms(_debts[i], _debts[i].debt!, name: name.trim());
      }
    }
    _changes.add(null);
  }

  static Account _withTerms(Account debt, DebtTerms terms, {String? name}) =>
      Account(
        id: debt.id,
        name: name ?? debt.name,
        type: debt.type,
        openingBalance: debt.openingBalance,
        includeInTotals: false,
        archived: false,
        sortOrder: debt.sortOrder,
        art: debt.art,
        debt: terms,
        personId: debt.personId,
      );
}

/// A phone whose window of the contacts gives [contact], and that keeps the
/// messages it was asked to open.
final class FakePeoplePhone implements PeoplePhone {
  /// Creates a phone that gives [contact], or nothing as if closed.
  FakePeoplePhone({this.contact});

  /// What the window of the contacts gives.
  PickedContact? contact;

  /// How many times the window of the contacts opened.
  int picks = 0;

  /// The SMS opened, as the number and the text.
  final sms = <(String, String)>[];

  /// The texts shared.
  final shared = <String>[];

  @override
  Future<PickedContact?> pickContact() async {
    picks++;
    return contact;
  }

  @override
  Future<void> sendSms(String number, String text) async =>
      sms.add((number, text));

  @override
  Future<void> share(String text) async => shared.add(text);
}
