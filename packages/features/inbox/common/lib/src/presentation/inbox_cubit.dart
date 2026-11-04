import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:device_settings/device_settings.dart';
import 'package:inbox_common/src/domain/inbox_repository.dart';
import 'package:inbox_common/src/domain/transfer_pairs.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:rates/rates.dart';

/// What the inbox shows.
enum InboxFilter {
  /// Everything that waits.
  all,

  /// The operations without a category.
  uncategorized,

  /// The transfers between one's own accounts to link.
  transfers,
}

/// An operation without a category, with the category that past choices
/// suggest for it.
@immutable
final class InboxItem {
  /// Creates the item of [transaction].
  const InboxItem(this.transaction, {this.hint});

  /// The operation.
  final Transaction transaction;

  /// What the past suggests, if anything.
  final CategoryHint? hint;

  /// The id of the operation.
  String get id => transaction.id;
}

/// What waits for the person in the inbox (ADR 0022).
@immutable
final class InboxState {
  /// Creates a state.
  const InboxState({
    this.loading = true,
    this.filter = InboxFilter.all,
    this.items = const [],
    this.pairs = const [],
    this.accounts = const [],
    this.categories = const [],
    this.rates = const RateBook.empty(),
    this.selected = const {},
    this.busy = const {},
    this.latestImport,
    this.failed = false,
    this.transfers = 0,
  });

  /// Whether the ledger is still being read.
  final bool loading;

  /// What is shown.
  final InboxFilter filter;

  /// The operations without a category, the earliest first, but those of a
  /// transfer to link.
  final List<InboxItem> items;

  /// The transfers to link.
  final List<TransferPair> pairs;

  /// The accounts, archived ones included.
  final List<Account> accounts;

  /// The categories of both kinds, archived ones included.
  final List<Category> categories;

  /// The rates of the Bank of Russia.
  final RateBook rates;

  /// The operations picked to get one category together.
  final Set<String> selected;

  /// The operations and pairs being written.
  final Set<String> busy;

  /// The latest import, which the inbox follows.
  final LedgerImport? latestImport;

  /// Whether the last writing failed.
  final bool failed;

  /// How many transfers the person linked here, so that each gets its word.
  final int transfers;

  /// How many things wait.
  int get count => items.length + pairs.length;

  /// The operations on screen.
  List<InboxItem> get shownItems =>
      filter == InboxFilter.transfers ? const [] : items;

  /// The transfers on screen.
  List<TransferPair> get shownPairs =>
      filter == InboxFilter.uncategorized ? const [] : pairs;

  /// The picked operations, in their order.
  List<InboxItem> get picked => [
    for (final item in items)
      if (selected.contains(item.id)) item,
  ];

  InboxState _with({
    bool? loading,
    InboxFilter? filter,
    List<InboxItem>? items,
    List<TransferPair>? pairs,
    List<Account>? accounts,
    List<Category>? categories,
    RateBook? rates,
    Set<String>? selected,
    Set<String>? busy,
    Object? latestImport = _same,
    bool? failed,
    int? transfers,
  }) => InboxState(
    loading: loading ?? this.loading,
    filter: filter ?? this.filter,
    items: items ?? this.items,
    pairs: pairs ?? this.pairs,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    rates: rates ?? this.rates,
    selected: selected ?? this.selected,
    busy: busy ?? this.busy,
    latestImport: identical(latestImport, _same)
        ? this.latestImport
        : latestImport as LedgerImport?,
    failed: failed ?? this.failed,
    transfers: transfers ?? this.transfers,
  );

  static const _same = Object();
}

/// The inbox (ADR 0022): the operations without a category, each with the
/// category that past choices suggest, and the transfers between one's own
/// accounts that imports split into an expense and an income. The pairs
/// that the person says are no transfers stay apart on this device, in
/// [_store].
final class InboxCubit extends Cubit<InboxState> {
  /// Creates the inbox on [_repository], keeping its pairs apart in
  /// [_store].
  InboxCubit(this._repository, this._store) : super(const InboxState()) {
    _dismissed = {
      for (final key in (_store.read(dismissedKey) ?? '').split(','))
        if (key.isNotEmpty) key,
    };
    _subscriptions = [
      _repository.watchTransactions().listen((it) {
        _transactions = it;
        _update();
      }, onError: _failed),
      _repository.watchAccounts().listen((it) {
        _accounts = it;
        _update();
      }, onError: _failed),
      for (final kind in CategoryKind.values)
        _repository.watchCategories(kind).listen((it) {
          _categories[kind] = it;
          _update();
        }, onError: _failed),
      _repository.watchRates().listen((it) {
        _rates = it;
        _update();
      }, onError: _failed),
      _repository.watchImports().listen((it) {
        if (!isClosed) emit(state._with(latestImport: it.firstOrNull));
      }, onError: _failed),
    ];
  }

  /// Where the pairs that are no transfers stay, as their keys.
  static const dismissedKey = 'inboxNotTransfers';

  final InboxRepository _repository;
  final SettingsStore _store;
  late final List<StreamSubscription<Object>> _subscriptions;
  late Set<String> _dismissed;

  List<Transaction>? _transactions;
  List<Account> _accounts = const [];
  final _categories = <CategoryKind, List<Category>>{};
  RateBook _rates = const RateBook.empty();

  void _failed(Object _) {
    if (!isClosed) emit(state._with(loading: false, failed: true));
  }

  /// Counts again what waits, once the ledger is read.
  void _update() {
    final transactions = _transactions;
    if (isClosed || transactions == null) return;
    final categories = [
      for (final kind in CategoryKind.values) ...?_categories[kind],
    ];
    final open = {
      for (final category in categories)
        if (!category.archived) category.id: category.kind,
    };
    final memory = CategoryMemory(transactions);
    final pairs = transferPairs(
      transactions,
      rates: _rates,
      dismissed: _dismissed,
    );
    final paired = {
      for (final pair in pairs) ...[pair.out.id, pair.into.id],
    };
    final waiting = [
      for (final transaction in transactions)
        if (_waits(transaction) && !paired.contains(transaction.id))
          transaction,
    ]..sort(_byDay);
    final items = [
      for (final transaction in waiting)
        InboxItem(
          transaction,
          hint: switch (memory.hintFor(transaction)) {
            final hint? when open[hint.categoryId] == _kindOf(transaction) =>
              hint,
            _ => null,
          },
        ),
    ];
    final ids = {for (final item in items) item.id};
    emit(
      state._with(
        loading: false,
        items: items,
        pairs: pairs,
        accounts: _accounts,
        categories: categories,
        rates: _rates,
        selected: state.selected.where(ids.contains).toSet(),
      ),
    );
  }

  static bool _waits(Transaction transaction) =>
      _kindOf(transaction) != null &&
      transaction.allocations.any((it) => it.categoryId == null);

  static CategoryKind? _kindOf(Transaction transaction) =>
      switch (transaction.kind) {
        TransactionKind.expense => CategoryKind.expense,
        TransactionKind.income => CategoryKind.income,
        _ => null,
      };

  static int _byDay(Transaction a, Transaction b) {
    final byDay = a.occurredOn.compareTo(b.occurredOn);
    return byDay != 0 ? byDay : a.id.compareTo(b.id);
  }

  /// Shows [filter].
  void show(InboxFilter filter) => emit(state._with(filter: filter));

  /// Picks the operation [id], or puts it back.
  void toggle(String id) {
    final selected = {...state.selected};
    if (!selected.remove(id)) selected.add(id);
    emit(state._with(selected: selected));
  }

  /// Picks every operation of [shown], those on screen, or puts them back
  /// when all of them are picked. An operation past the screen is never
  /// picked unseen.
  void toggleAll(Iterable<String> shown) {
    final ids = {...shown};
    final all = ids.isNotEmpty && ids.every(state.selected.contains);
    emit(
      state._with(
        selected: all
            ? state.selected.difference(ids)
            : {...state.selected, ...ids},
      ),
    );
  }

  /// Puts every picked operation back.
  void pickNone() => emit(state._with(selected: const {}));

  /// Gives the operation [id] the category that its hint names.
  Future<void> accept(String id) async {
    final item = state.items.where((it) => it.id == id).firstOrNull;
    final hint = item?.hint;
    if (item == null || hint == null) return;
    await _categorize([(item.transaction, hint.categoryId)]);
  }

  /// Gives the operation [id] the category [categoryId].
  Future<void> choose(String id, String categoryId) async {
    final item = state.items.where((it) => it.id == id).firstOrNull;
    if (item == null) return;
    await _categorize([(item.transaction, categoryId)]);
  }

  /// Gives the picked operations of its kind the category [categoryId], at
  /// once; those of the other kind stay picked.
  Future<void> choosePicked(String categoryId) async {
    final category = state.categories
        .where((it) => it.id == categoryId)
        .firstOrNull;
    if (category == null) return;
    await _categorize([
      for (final item in state.picked)
        if (_kindOf(item.transaction) == category.kind)
          (item.transaction, categoryId),
    ]);
  }

  Future<void> _categorize(List<(Transaction, String)> choices) async {
    if (choices.isEmpty) return;
    final ids = {for (final (transaction, _) in choices) transaction.id};
    if (ids.any(state.busy.contains)) return;
    emit(
      state._with(
        busy: {...state.busy, ...ids},
        selected: state.selected.difference(ids),
        failed: false,
      ),
    );
    try {
      await _repository.categorize(choices);
    } on Object {
      if (!isClosed) emit(state._with(failed: true));
    } finally {
      if (!isClosed) emit(state._with(busy: state.busy.difference(ids)));
    }
  }

  /// Links [pair] into one transfer between its accounts.
  Future<void> makeTransfer(TransferPair pair) async {
    if (state.busy.contains(pair.key)) return;
    emit(state._with(busy: {...state.busy, pair.key}, failed: false));
    try {
      await _repository.makeTransfer(pair);
      if (!isClosed) emit(state._with(transfers: state.transfers + 1));
    } on Object {
      if (!isClosed) emit(state._with(failed: true));
    } finally {
      if (!isClosed) emit(state._with(busy: state.busy.difference({pair.key})));
    }
  }

  /// Keeps [pair] apart: its income then waits for a category of its own.
  Future<void> notTransfer(TransferPair pair) async {
    _dismissed = {..._dismissed, pair.key};
    await _store.write(dismissedKey, _dismissed.join(','));
    _update();
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
