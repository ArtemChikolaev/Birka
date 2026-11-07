import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/schedule_draft.dart';
import 'package:schedules_common/src/domain/schedules_repository.dart';

/// Where the form of a regular payment stands.
enum ScheduleFormStatus {
  /// What it needs has not been read yet.
  loading,

  /// The person fills it in.
  editing,

  /// It is being saved.
  saving,

  /// It was saved, and the form can close.
  saved,

  /// The payment was deleted, and the form can close.
  deleted,

  /// The payment it should change is gone.
  missing,
}

/// What the form of a regular payment holds.
@immutable
final class ScheduleFormState {
  /// Creates the state.
  ScheduleFormState({
    required this.today,
    this.status = ScheduleFormStatus.loading,
    this.id,
    this.kind = TransactionKind.expense,
    this.name = '',
    this.amountMinor = 0,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.every = ScheduleEvery.month,
    CivilDate? next,
    int? day,
    this.onDay = ScheduleOnDay.ask,
    this.reminder = ScheduleReminder.onDay,
    this.accounts = const [],
    this.expenses = const [],
    this.incomes = const [],
    this.failed = false,
  }) : next = next ?? today,
       day = day ?? (next ?? today).day;

  /// Today on this device.
  final CivilDate today;

  /// Where the form stands.
  final ScheduleFormStatus status;

  /// The payment that the form changes, or `null` for a new one.
  final String? id;

  /// An expense, an income or a transfer.
  final TransactionKind kind;

  /// What the person calls it.
  final String name;

  /// The amount in minor units of the currency of the account.
  final int amountMinor;

  /// The account the money leaves, or the account an income reaches.
  final String? accountId;

  /// The account a transfer reaches.
  final String? toAccountId;

  /// The category, or `null` to let its transactions wait in the inbox.
  final String? categoryId;

  /// How often it comes.
  final ScheduleEvery every;

  /// When it comes next.
  final CivilDate next;

  /// Its day of the month.
  final int day;

  /// What its day does.
  final ScheduleOnDay onDay;

  /// When to remind of it.
  final ScheduleReminder reminder;

  /// The accounts that are not archived, in their order.
  final List<Account> accounts;

  /// The open categories of expenses.
  final List<Category> expenses;

  /// The open categories of income.
  final List<Category> incomes;

  /// Whether the last save failed.
  final bool failed;

  /// Whether the form changes a payment rather than adding one.
  bool get editing => id != null;

  /// The account the money leaves or reaches.
  Account? get account => _account(accountId);

  /// The account a transfer reaches.
  Account? get toAccount => _account(toAccountId);

  /// The categories of the kind of the payment.
  List<Category> get categories =>
      kind == TransactionKind.income ? incomes : expenses;

  /// The category, if it is open.
  Category? get category =>
      categories.where((it) => it.id == categoryId).firstOrNull;

  /// The amount in the currency of the account.
  Money? get amount => switch (account) {
    final account? => Money(amountMinor, account.currency),
    null => null,
  };

  /// The accounts a transfer can reach: the others of the same currency.
  List<Account> get targets => [
    for (final other in accounts)
      if (other.id != accountId && other.currency == account?.currency) other,
  ];

  /// Whether the form holds a payment that the ledger takes.
  bool get valid =>
      name.trim().isNotEmpty &&
      amountMinor > 0 &&
      account != null &&
      (kind != TransactionKind.transfer || toAccount != null);

  Account? _account(String? id) =>
      accounts.where((it) => it.id == id).firstOrNull;

  /// The same state with the given fields changed.
  ScheduleFormState copyWith({
    ScheduleFormStatus? status,
    String? id,
    TransactionKind? kind,
    String? name,
    int? amountMinor,
    String? accountId,
    (String?,)? toAccountId,
    (String?,)? categoryId,
    ScheduleEvery? every,
    CivilDate? next,
    int? day,
    ScheduleOnDay? onDay,
    ScheduleReminder? reminder,
    List<Account>? accounts,
    List<Category>? expenses,
    List<Category>? incomes,
    bool? failed,
  }) => ScheduleFormState(
    today: today,
    status: status ?? this.status,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId == null ? this.toAccountId : toAccountId.$1,
    categoryId: categoryId == null ? this.categoryId : categoryId.$1,
    every: every ?? this.every,
    next: next ?? this.next,
    day: day ?? this.day,
    onDay: onDay ?? this.onDay,
    reminder: reminder ?? this.reminder,
    accounts: accounts ?? this.accounts,
    expenses: expenses ?? this.expenses,
    incomes: incomes ?? this.incomes,
    failed: failed ?? this.failed,
  );
}

/// Fills in a new regular payment, or changes one (ADR 0023). A new one can
/// start as the regular income «Зарплата», which sets the payday of the money
/// of the days.
class ScheduleFormCubit extends Cubit<ScheduleFormState> {
  /// Creates the form of payment [id], or of a new one, a salary with
  /// [salary], and reads what it needs.
  ScheduleFormCubit(this._repository, {String? id, bool salary = false})
    : _id = id,
      super(ScheduleFormState(today: _repository.today())) {
    unawaited(_load(salary: salary));
  }

  final SchedulesRepository _repository;
  final String? _id;

  /// Makes it an expense, an income or a transfer. A category of the other
  /// kind goes, and a transfer gets an account to reach.
  void kindChanged(TransactionKind kind) {
    final next = state.copyWith(kind: kind);
    final category = next.category;
    final target = kind == TransactionKind.transfer
        ? next.toAccount ?? next.targets.firstOrNull
        : null;
    emit(
      next.copyWith(
        categoryId: (kind == TransactionKind.transfer ? null : category?.id,),
        toAccountId: (target?.id,),
      ),
    );
  }

  /// Names the payment.
  void nameChanged(String name) => emit(state.copyWith(name: name));

  /// Sets the amount, in minor units of the currency of the account.
  void amountChanged(int minorUnits) =>
      emit(state.copyWith(amountMinor: minorUnits));

  /// Moves the payment to account [id]. A transfer keeps an account to reach
  /// in the same currency.
  void accountChanged(String id) {
    final next = state.copyWith(accountId: id);
    if (next.kind != TransactionKind.transfer) return emit(next);
    final target = next.targets.where((it) => it.id == next.toAccountId);
    emit(
      next.copyWith(
        toAccountId: (target.firstOrNull?.id ?? next.targets.firstOrNull?.id,),
      ),
    );
  }

  /// Makes a transfer reach account [id].
  void toAccountChanged(String id) => emit(state.copyWith(toAccountId: (id,)));

  /// Gives the payment category [id], or none with `null`.
  void categoryChanged(String? id) => emit(state.copyWith(categoryId: (id,)));

  /// Repeats the payment [every] month, week or year.
  void everyChanged(ScheduleEvery every) => emit(state.copyWith(every: every));

  /// Moves its next time to [day], whose day of the month it keeps.
  void nextChanged(CivilDate day) =>
      emit(state.copyWith(next: day, day: day.day));

  /// Says what its day does.
  void onDayChanged(ScheduleOnDay onDay) => emit(state.copyWith(onDay: onDay));

  /// Says when to remind of it.
  void reminderChanged(ScheduleReminder reminder) =>
      emit(state.copyWith(reminder: reminder));

  /// Saves the payment, once it is [ScheduleFormState.valid].
  Future<void> save() async {
    final form = state;
    final account = form.account;
    if (!form.valid || account == null) return;
    if (form.status != ScheduleFormStatus.editing) return;
    emit(form.copyWith(status: ScheduleFormStatus.saving, failed: false));
    final amount = Money(form.amountMinor, account.currency);
    final transfer = form.kind == TransactionKind.transfer;
    try {
      if (form.id case final id?) {
        await _repository.update(
          Schedule(
            id: id,
            kind: form.kind,
            name: form.name.trim(),
            accountId: account.id,
            toAccountId: transfer ? form.toAccountId : null,
            categoryId: transfer ? null : form.categoryId,
            amount: amount,
            every: form.every,
            day: form.day,
            next: form.next,
            onDay: form.onDay,
            reminder: form.reminder,
          ),
        );
      } else {
        await _repository.add(
          ScheduleDraft(
            kind: form.kind,
            name: form.name,
            accountId: account.id,
            toAccountId: transfer ? form.toAccountId : null,
            categoryId: transfer ? null : form.categoryId,
            amount: amount,
            every: form.every,
            next: form.next,
            onDay: form.onDay,
            reminder: form.reminder,
          ),
        );
      }
      emit(state.copyWith(status: ScheduleFormStatus.saved));
    } on LedgerException {
      emit(state.copyWith(status: ScheduleFormStatus.editing, failed: true));
    }
  }

  /// Deletes the payment that the form changes.
  Future<void> delete() async {
    final id = state.id;
    if (id == null || state.status != ScheduleFormStatus.editing) return;
    emit(state.copyWith(status: ScheduleFormStatus.saving));
    await _repository.delete(id);
    emit(state.copyWith(status: ScheduleFormStatus.deleted));
  }

  Future<void> _load({required bool salary}) async {
    final rows = await _repository.watchAccounts().first;
    final expenses = await _repository
        .watchCategories(CategoryKind.expense)
        .first;
    final incomes = await _repository
        .watchCategories(CategoryKind.income)
        .first;
    final base = await _repository.watchBaseCurrency().first;
    if (isClosed) return;
    final accounts = [
      for (final row in rows)
        if (!row.account.archived) row.account,
    ];
    final loaded = state.copyWith(
      accounts: accounts,
      expenses: [
        for (final category in expenses)
          if (!category.archived) category,
      ],
      incomes: [
        for (final category in incomes)
          if (!category.archived) category,
      ],
    );
    final id = _id;
    if (id == null) {
      final first =
          accounts.where((it) => it.currency == base).firstOrNull ??
          accounts.firstOrNull;
      return emit(
        loaded.copyWith(
          status: ScheduleFormStatus.editing,
          kind: salary ? TransactionKind.income : null,
          name: salary ? t.schedules.salaryName : null,
          accountId: first?.id,
        ),
      );
    }
    final schedules = await _repository.watchSchedules().first;
    if (isClosed) return;
    final schedule = schedules.where((it) => it.id == id).firstOrNull;
    if (schedule == null) {
      return emit(loaded.copyWith(status: ScheduleFormStatus.missing));
    }
    emit(
      ScheduleFormState(
        today: loaded.today,
        status: ScheduleFormStatus.editing,
        id: schedule.id,
        kind: schedule.kind,
        name: schedule.name,
        amountMinor: schedule.amount.minorUnits,
        accountId: schedule.accountId,
        toAccountId: schedule.toAccountId,
        categoryId: schedule.categoryId,
        every: schedule.every,
        next: schedule.next,
        day: schedule.day,
        onDay: schedule.onDay,
        reminder: schedule.reminder,
        accounts: loaded.accounts,
        expenses: loaded.expenses,
        incomes: loaded.incomes,
      ),
    );
  }
}
