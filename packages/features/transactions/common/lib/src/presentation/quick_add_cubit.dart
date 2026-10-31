import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:transactions_common/src/domain/amount_expression.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Where quick add stands.
enum QuickAddStatus {
  /// The accounts and categories are on their way.
  loading,

  /// The user is filling it in.
  editing,

  /// A save is under way.
  saving,

  /// The transaction is in the ledger, and the sheet can close.
  saved,

  /// The transaction could not be saved.
  failed,

  /// The accounts and categories could not be read.
  failedToRead,
}

/// What quick add opens on, when it does not open empty.
@immutable
final class QuickAddSource {
  /// Changes operation [operationId].
  const QuickAddSource.edit(this.operationId) : repeats = false;

  /// Records operation [operationId] once more, for today.
  const QuickAddSource.repeat(this.operationId) : repeats = true;

  /// The operation.
  final String operationId;

  /// Whether the operation stays as it is and a new one follows it.
  final bool repeats;
}

/// The fields of quick add.
@immutable
final class QuickAddState {
  /// Creates a state.
  const QuickAddState({
    required this.status,
    required this.kind,
    required this.today,
    required this.yesterday,
    required this.day,
    this.sent = const AmountExpression(),
    this.received = const AmountExpression(),
    this.editingReceived = false,
    this.accounts = const [],
    this.expenseCategories = const [],
    this.incomeCategories = const [],
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note = '',
    this.changesExisting = false,
  });

  /// How many categories stand on the sheet before the button for the rest.
  static const shownCategories = 7;

  /// Where quick add stands.
  final QuickAddStatus status;

  /// An expense, an income or a transfer.
  final TransactionKind kind;

  /// The day of today.
  final CivilDate today;

  /// The day before [today].
  final CivilDate yesterday;

  /// The day of the transaction.
  final CivilDate day;

  /// What was typed: the amount, or what leaves the account of a transfer.
  final AmountExpression sent;

  /// What arrives on the other account of a transfer between currencies.
  final AmountExpression received;

  /// Whether the keypad types [received] instead of [sent].
  final bool editingReceived;

  /// The accounts to choose from.
  final List<Account> accounts;

  /// The categories of expenses, the frequent ones first.
  final List<Category> expenseCategories;

  /// The categories of income, the frequent ones first.
  final List<Category> incomeCategories;

  /// The account, which money leaves in a transfer.
  final String? accountId;

  /// The account a transfer goes to.
  final String? toAccountId;

  /// The category.
  final String? categoryId;

  /// The note as typed.
  final String note;

  /// Whether a save changes an operation instead of adding one.
  final bool changesExisting;

  /// The picked account.
  Account? get account => _accountWith(accountId);

  /// The account a transfer goes to.
  Account? get toAccount => _accountWith(toAccountId);

  /// The accounts a transfer can go to.
  List<Account> get targets => [
    for (final account in accounts)
      if (account.id != accountId) account,
  ];

  /// The categories of [kind]. A transfer has none.
  List<Category> get categories => switch (kind) {
    TransactionKind.expense => expenseCategories,
    TransactionKind.income => incomeCategories,
    _ => const [],
  };

  /// The picked category.
  Category? get category {
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  /// Whether the categories do not fit on the sheet.
  bool get hasMoreCategories => categories.length > shownCategories + 1;

  /// The categories on the sheet. One picked from the rest takes the last
  /// place, so that the sheet shows what was picked.
  List<Category> get shown {
    if (!hasMoreCategories) return categories;
    final first = categories.take(shownCategories).toList();
    final picked = category;
    if (picked == null || first.contains(picked)) return first;
    return [...first.take(shownCategories - 1), picked];
  }

  /// Whether a transfer goes between currencies and needs two amounts.
  bool get needsTwoAmounts {
    final to = toAccount;
    return kind == TransactionKind.transfer &&
        to != null &&
        to.currency != account?.currency;
  }

  /// What the keypad is typing.
  AmountExpression get editing =>
      needsTwoAmounts &&
          editingReceived //
      ? received
      : sent;

  /// The currency of what the keypad is typing.
  Currency? get editingCurrency => needsTwoAmounts && editingReceived
      ? toAccount?.currency
      : account?.currency;

  /// The amount, or what leaves the account of a transfer.
  Money? get amount => _value(sent, account);

  /// What arrives on the other account of a transfer.
  Money? get receivedAmount =>
      needsTwoAmounts ? _value(received, toAccount) : amount;

  /// Whether a save can start: every field it needs is in place, and it has
  /// not started already.
  bool get canSave {
    if (status == QuickAddStatus.saving || status == QuickAddStatus.saved) {
      return false;
    }
    if (account == null || !(amount?.isPositive ?? false)) return false;
    return kind == TransactionKind.transfer
        ? toAccount != null && (receivedAmount?.isPositive ?? false)
        : category != null;
  }

  Account? _accountWith(String? id) {
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Money? _value(AmountExpression expression, Account? account) =>
      account == null ? null : expression.valueIn(account.currency);

  /// A copy with the given fields changed. [toAccountId] and [categoryId]
  /// take functions, so they can also become `null`.
  QuickAddState copyWith({
    QuickAddStatus? status,
    TransactionKind? kind,
    CivilDate? day,
    AmountExpression? sent,
    AmountExpression? received,
    bool? editingReceived,
    List<Account>? accounts,
    List<Category>? expenseCategories,
    List<Category>? incomeCategories,
    String? accountId,
    String? Function()? toAccountId,
    String? Function()? categoryId,
    String? note,
    bool? changesExisting,
  }) {
    return QuickAddState(
      status: status ?? this.status,
      kind: kind ?? this.kind,
      today: today,
      yesterday: yesterday,
      day: day ?? this.day,
      sent: sent ?? this.sent,
      received: received ?? this.received,
      editingReceived: editingReceived ?? this.editingReceived,
      accounts: accounts ?? this.accounts,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId == null ? this.toAccountId : toAccountId(),
      categoryId: categoryId == null ? this.categoryId : categoryId(),
      note: note ?? this.note,
      changesExisting: changesExisting ?? this.changesExisting,
    );
  }
}

/// Fills in and saves a transaction: a new one, or the one [QuickAddSource]
/// names.
class QuickAddCubit extends Cubit<QuickAddState> {
  /// Creates quick add and loads its choices. [now] tells the time in tests.
  QuickAddCubit(
    this._repository, {
    DateTime Function()? now,
    QuickAddSource? source,
  }) : _now = now ?? DateTime.now,
       _source = source,
       super(_initial((now ?? DateTime.now)())) {
    unawaited(refresh());
  }

  final TransactionsRepository _repository;
  final DateTime Function() _now;
  final QuickAddSource? _source;

  /// Whether the sheet has taken what it needs from its source.
  bool _filled = false;

  /// The operation that a save changes.
  Operation? _changing;

  static QuickAddState _initial(DateTime now) {
    final today = CivilDate.of(now);
    return QuickAddState(
      status: QuickAddStatus.loading,
      kind: TransactionKind.expense,
      today: today,
      yesterday: CivilDate.of(DateTime(now.year, now.month, now.day - 1)),
      day: today,
    );
  }

  /// Fills the sheet once from the operation it opens on.
  Future<void> _fill() async {
    final source = _source;
    if (source == null || _filled) return;
    final operation = await _repository
        .watchOperation(source.operationId)
        .first;
    if (isClosed) return;
    _filled = true;
    if (operation == null) return;
    final repeats = source.repeats;
    if (!repeats) _changing = operation;
    final received = operation.received;
    emit(
      state.copyWith(
        kind: operation.kind,
        day: repeats ? null : operation.day,
        sent: AmountExpression.of(operation.amount),
        received: received == null ? null : AmountExpression.of(received),
        accountId: operation.account?.id,
        toAccountId: () => operation.toAccount?.id,
        categoryId: () => operation.category?.id,
        note: operation.note,
        changesExisting: !repeats,
      ),
    );
  }

  /// Reads the choices again, such as after a new account appeared. What an
  /// operation being changed names stays among them, even when it is archived.
  Future<void> refresh() async {
    try {
      await _fill();
      final changing = _changing;
      final accounts = _withKept(await _repository.accounts(), [
        changing?.account,
        changing?.toAccount,
      ], (account) => account.id);
      final expenses = await _repository.categories(CategoryKind.expense);
      final income = await _repository.categories(CategoryKind.income);
      final last = await _repository.lastAccountId();
      if (isClosed) return;
      final current = state.accountId ?? last;
      final kept = [changing?.category];
      emit(
        state.copyWith(
          status: QuickAddStatus.editing,
          accounts: accounts,
          expenseCategories: changing?.kind == TransactionKind.expense
              ? _withKept(expenses, kept, (category) => category.id)
              : expenses,
          incomeCategories: changing?.kind == TransactionKind.income
              ? _withKept(income, kept, (category) => category.id)
              : income,
          accountId: accounts.any((account) => account.id == current)
              ? current
              : accounts.firstOrNull?.id,
        ),
      );
    } on Exception {
      if (!isClosed) emit(state.copyWith(status: QuickAddStatus.failedToRead));
    }
  }

  static List<T> _withKept<T extends Object>(
    List<T> items,
    List<T?> kept,
    String Function(T) idOf,
  ) {
    final ids = items.map(idOf).toSet();
    return [
      ...items,
      for (final item in kept.nonNulls)
        if (ids.add(idOf(item))) item,
    ];
  }

  /// Sets the kind. The category belongs to the old kind and goes with it.
  void kindChanged(TransactionKind value) {
    if (value == state.kind) return;
    emit(state.copyWith(kind: value, categoryId: () => null));
  }

  /// Types a digit.
  void digitTyped(int digit) => _type(
    (expression, decimalDigits) =>
        expression.digit(digit, decimalDigits: decimalDigits),
  );

  /// Types the decimal point.
  void pointTyped() => _type(
    (expression, decimalDigits) =>
        expression.decimalPoint(decimalDigits: decimalDigits),
  );

  /// Types an operator.
  void operatorTyped(AmountOperator operator) =>
      _type((expression, _) => expression.operator_(operator));

  /// Removes what was typed last.
  void backspaceTyped() => _type((expression, _) => expression.backspace());

  /// Sets which of the two amounts of a transfer the keypad types.
  void editingChanged({required bool received}) =>
      emit(state.copyWith(editingReceived: received));

  /// Sets the account. A transfer cannot go to the account it leaves.
  void accountChanged(String id) {
    emit(
      state.copyWith(
        accountId: id,
        toAccountId: id == state.toAccountId ? () => null : null,
      ),
    );
  }

  /// Sets the account a transfer goes to.
  void toAccountChanged(String id) =>
      emit(state.copyWith(toAccountId: () => id));

  /// Sets the category.
  void categoryChanged(String id) => emit(state.copyWith(categoryId: () => id));

  /// Sets the day.
  void dayChanged(CivilDate value) => emit(state.copyWith(day: value));

  /// Sets the note.
  void noteChanged(String value) => emit(state.copyWith(note: value));

  /// Saves the transaction, if every field is in place.
  Future<void> save() async {
    if (!state.canSave) return;
    final draft = _draft();
    emit(state.copyWith(status: QuickAddStatus.saving));
    try {
      final changing = _changing;
      if (changing == null) {
        await _repository.record(draft);
      } else {
        await _repository.amend(changing.id, draft);
      }
      if (!isClosed) emit(state.copyWith(status: QuickAddStatus.saved));
    } on Exception {
      if (!isClosed) emit(state.copyWith(status: QuickAddStatus.failed));
    }
  }

  TransactionDraft _draft() {
    final note = state.note.trim();
    final day = state.day;
    final kept = _changing?.transaction;
    final status = kept?.status ?? TransactionStatus.cleared;
    final source = kept?.source ?? TransactionSource.manual;
    // The moment is known only for what happens now, and stays with its day.
    final at = kept?.occurredOn == day
        ? kept?.occurredAt
        : (day == state.today ? _now() : null);
    if (state.kind == TransactionKind.transfer) {
      return TransactionDraft.transfer(
        fromAccountId: state.accountId!,
        sent: state.amount!,
        toAccountId: state.toAccountId!,
        received: state.receivedAmount!,
        occurredOn: day,
        occurredAt: at,
        note: note,
        status: status,
        source: source,
      );
    }
    final allocations = [
      Allocation(categoryId: state.categoryId!, amount: state.amount!),
    ];
    return state.kind == TransactionKind.income
        ? TransactionDraft.income(
            accountId: state.accountId!,
            allocations: allocations,
            occurredOn: day,
            occurredAt: at,
            note: note,
            status: status,
            source: source,
          )
        : TransactionDraft.expense(
            accountId: state.accountId!,
            allocations: allocations,
            occurredOn: day,
            occurredAt: at,
            note: note,
            status: status,
            source: source,
          );
  }

  void _type(
    AmountExpression Function(AmountExpression, int decimalDigits) edit,
  ) {
    final decimalDigits = state.editingCurrency?.decimalDigits ?? 2;
    if (state.needsTwoAmounts && state.editingReceived) {
      emit(state.copyWith(received: edit(state.received, decimalDigits)));
    } else {
      emit(state.copyWith(sent: edit(state.sent, decimalDigits)));
    }
  }
}
