import 'dart:math';

import 'package:design_tokens/design_tokens.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// Fills [ledger] with the demo, in place of all it holds: four accounts in
/// rubles, dollars and euros, the whole set of categories and half a year of
/// operations up to [now], in the language of the app (ADR 0019).
///
/// The same [now] gives the same demo, which screenshots and checks rely on.
///
/// The wipe and the demo are one write, so that two tabs that fill at once
/// leave one demo.
Future<void> fillDemo(LedgerRepository ledger, {required DateTime now}) =>
    ledger.atomically(() async {
      await ledger.wipe();
      await _Demo(ledger, now).fill();
    });

/// The rates of the exchanges of the demo, in kopecks for a dollar and a
/// euro.
const _rublesForDollar = 8100;
const _rublesForEuro = 9400;

final class _Demo {
  _Demo(this._ledger, this._now);

  final LedgerRepository _ledger;
  final DateTime _now;

  /// One seed for every demo.
  final _random = Random(2026);

  /// What each account holds, in its minor units, so that no account goes
  /// below zero.
  final _balances = <String, int>{};

  final _categories = <String, String>{};

  /// The id of the preset category [key]: every operation of the demo has
  /// one.
  String _categoryOf(String key) => _categories[key]!;

  late final String _card;
  late final String _cash;
  late final String _savings;
  late final String _euro;

  Future<void> fill() async {
    for (final preset in categoryPresets) {
      final category = await _ledger.addCategory(
        kind: preset.kind,
        name: t.categories.presets[preset.key] ?? preset.key,
        icon: preset.icon,
        color: paletteColors[preset.colorIndex],
      );
      _categories[preset.key] = category.id;
    }
    _card = await _account(
      t.demo.card,
      AccountType.debit,
      Money(4520000, Currency.rub),
      lastDigits: '4821',
      art: AccountArt.emerald,
    );
    _cash = await _account(
      t.demo.cash,
      AccountType.cash,
      Money(650000, Currency.rub),
      art: AccountArt.graphite,
    );
    _savings = await _account(
      t.demo.savings,
      AccountType.savings,
      Money(120000, Currency.usd),
      art: AccountArt.sapphire,
    );
    _euro = await _account(
      t.demo.euro,
      AccountType.debit,
      Money(35000, Currency.eur),
      lastDigits: '0937',
      art: AccountArt.violet,
    );
    final today = DateTime.utc(_now.year, _now.month, _now.day);
    for (
      var moment = DateTime.utc(_now.year, _now.month - 5);
      !moment.isAfter(today);
      moment = moment.add(const Duration(days: 1))
    ) {
      await _day(moment, today: moment == today);
    }
  }

  Future<String> _account(
    String name,
    AccountType type,
    Money balance, {
    required AccountArt art,
    String? lastDigits,
  }) async {
    final account = await _ledger.addAccount(
      name: name,
      type: type,
      openingBalance: balance,
      lastDigits: lastDigits,
      art: art,
    );
    _balances[account.id] = balance.minorUnits;
    return account.id;
  }

  /// The operations of one day: the fixed ones of the month first, then
  /// what a day of shops and roads brings.
  Future<void> _day(DateTime moment, {required bool today}) async {
    final day = CivilDate(moment.year, moment.month, moment.day);
    final monthsAgo =
        (_now.year * 12 + _now.month) - (moment.year * 12 + moment.month);
    final weekend = moment.weekday >= DateTime.saturday;
    switch (moment.day) {
      case 5:
        await _earn(day, _card, 'salary', 5000000, t.demo.advance);
      case 7:
        await _move(
          day,
          _card,
          Money(800000, Currency.rub),
          _cash,
          t.demo.toCash,
        );
      case 10:
        await _spend(day, 'home', _rub(6400, 900), t.demo.utilities);
      case 12:
        await _spend(day, 'subscriptions', 95000, t.demo.phone);
      case 15:
        await _spend(day, 'subscriptions', 29900, t.demo.music);
      case 18:
        await _spend(day, 'subscriptions', 39900, t.demo.movies);
      case 20:
        await _earn(day, _card, 'salary', 7500000, t.demo.salary);
      case 21:
        await _move(
          day,
          _card,
          Money(3000000, Currency.rub),
          _savings,
          t.demo.toSavings,
          received: Money(3000000 * 100 ~/ _rublesForDollar, Currency.usd),
        );
      case 28:
        await _earn(day, _savings, 'interest', 120, t.demo.interest);
    }
    if (monthsAgo == 1 && moment.day == 16) {
      await _earn(day, _card, 'freelance', 2500000, t.demo.project);
    }
    if (monthsAgo == 3 && moment.day == 24) {
      await _spend(day, 'gifts', 450000, t.demo.gift);
    }
    if (monthsAgo == 2) {
      if (moment.day == 10) {
        await _move(
          day,
          _card,
          Money(3000000, Currency.rub),
          _euro,
          t.demo.toEuro,
          received: Money(3000000 * 100 ~/ _rublesForEuro, Currency.eur),
        );
      }
      if (moment.day >= 12 && moment.day <= 15) {
        await _trip(day, first: moment.day == 12);
        return;
      }
    }
    if (today || _chance(45)) {
      final (note, account) = _pick([
        (t.demo.supermarket, _card),
        (t.demo.supermarket, _card),
        (t.demo.market, _cash),
        (t.demo.bakery, _cash),
        ('', _card),
      ]);
      await _spend(
        day,
        'groceries',
        _rub(600, 3600, kopecks: true),
        note,
        account: account,
      );
    }
    if (today || _chance(weekend ? 45 : 25)) {
      final note = _pick([t.demo.coffee, t.demo.coffee, t.demo.lunch, '']);
      await _spend(day, 'cafe', _rub(250, 1150), note);
    }
    if (!weekend && _chance(70)) {
      await (_chance(25)
          ? _spend(day, 'transport', _rub(350, 550), t.demo.taxi)
          : _spend(day, 'transport', 7000, t.demo.metro));
    }
    if (weekend && _chance(30)) {
      await _spend(
        day,
        'leisure',
        _rub(500, 2500),
        _pick([t.demo.cinema, t.demo.concert]),
      );
    }
    if (_chance(5)) {
      await _spend(day, 'health', _rub(400, 2100), t.demo.pharmacy);
    }
    if (_chance(3)) {
      await _spend(day, 'clothes', _rub(2000, 7000), t.demo.clothes);
    }
  }

  /// A day abroad, paid from the card in euros.
  Future<void> _trip(CivilDate day, {required bool first}) async {
    if (first) await _spend(day, 'travel', 32000, t.demo.hotel, account: _euro);
    await _spend(
      day,
      'cafe',
      1200 + _random.nextInt(2400),
      t.demo.coffee,
      account: _euro,
    );
    await _spend(
      day,
      'transport',
      800 + _random.nextInt(1200),
      t.demo.trip,
      account: _euro,
    );
  }

  Future<void> _spend(
    CivilDate day,
    String category,
    int minor,
    String note, {
    String? account,
  }) async {
    var from = account ?? _card;
    // An account without enough money leaves the purchase to the card.
    if (_balances[from]! < minor && from != _euro) from = _card;
    if (_balances[from]! < minor) return;
    final currency = from == _euro ? Currency.eur : Currency.rub;
    await _ledger.record(
      TransactionDraft.expense(
        accountId: from,
        allocations: [
          Allocation(
            categoryId: _categoryOf(category),
            amount: Money(minor, currency),
          ),
        ],
        occurredOn: day,
        note: note,
      ),
    );
    _balances[from] = _balances[from]! - minor;
  }

  Future<void> _earn(
    CivilDate day,
    String account,
    String category,
    int minor,
    String note,
  ) async {
    final currency = account == _savings ? Currency.usd : Currency.rub;
    await _ledger.record(
      TransactionDraft.income(
        accountId: account,
        allocations: [
          Allocation(
            categoryId: _categoryOf(category),
            amount: Money(minor, currency),
          ),
        ],
        occurredOn: day,
        note: note,
      ),
    );
    _balances[account] = _balances[account]! + minor;
  }

  Future<void> _move(
    CivilDate day,
    String from,
    Money sent,
    String to,
    String note, {
    Money? received,
  }) async {
    if (_balances[from]! < sent.minorUnits) return;
    final arrived = received ?? sent;
    await _ledger.record(
      TransactionDraft.transfer(
        fromAccountId: from,
        sent: sent,
        toAccountId: to,
        received: arrived,
        occurredOn: day,
        note: note,
      ),
    );
    _balances[from] = _balances[from]! - sent.minorUnits;
    _balances[to] = _balances[to]! + arrived.minorUnits;
  }

  /// Whether something with a chance of [percent] in a hundred happens.
  bool _chance(int percent) => _random.nextInt(100) < percent;

  /// One of [choices].
  T _pick<T>(List<T> choices) => choices[_random.nextInt(choices.length)];

  /// Some rubles from [least] up to [least] and [spread] more, in kopecks.
  int _rub(int least, int spread, {bool kopecks = false}) =>
      (least + _random.nextInt(spread)) * 100 +
      (kopecks ? _random.nextInt(100) : 0);
}
