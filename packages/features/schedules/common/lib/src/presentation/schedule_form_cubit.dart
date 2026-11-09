import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:schedules_common/src/domain/reminders.dart';
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
    this.advanceDay,
    this.onDay = ScheduleOnDay.ask,
    this.reminder = ScheduleReminder.onDay,
    this.reminders,
    this.accounts = const [],
    this.expenses = const [],
    this.incomes = const [],
    this.failed = false,
    this.madeFrom,
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

  /// The amount in minor units of the currency of the account: what comes
  /// in a month for a salary in halves.
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

  /// Its day of the month: the day of the rest for a salary in halves.
  final int day;

  /// The day of the month of its advance, for a salary in halves.
  final int? advanceDay;

  /// What its day does.
  final ScheduleOnDay onDay;

  /// When to remind of it.
  final ScheduleReminder reminder;

  /// How this device reminds of the payments, `null` until it is read
  /// (ADR 0025).
  final ReminderSettings? reminders;

  /// The accounts that are not archived, in their order.
  final List<Account> accounts;

  /// The open categories of expenses.
  final List<Category> expenses;

  /// The open categories of income.
  final List<Category> incomes;

  /// Whether the last save failed.
  final bool failed;

  /// The operation that a new payment is made from (ADR 0023, point 22),
  /// which becomes its time on that day.
  final Transaction? madeFrom;

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

  /// Whether it is an income that comes in halves: an advance and the rest.
  bool get halves => kind == TransactionKind.income && advanceDay != null;

  /// What each time brings: half of [amount] for a salary in halves, or
  /// `null` when the sum of a month does not split into equal halves, since
  /// both times carry the one amount of the rule.
  Money? get part {
    final amount = this.amount;
    if (amount == null || !halves) return amount;
    final [advance, rest] = amount.split(2);
    return advance == rest ? advance : null;
  }

  /// Whether the sum of a month of a salary in halves does not split into
  /// two equal halves.
  bool get uneven => halves && amount != null && part == null;

  /// The payment as the form holds it, for what its rule gives before it is
  /// saved, such as its first reminder. Its amount and its accounts play no
  /// part in that, so a form without an account still gives one.
  Schedule get schedule => Schedule(
    id: id ?? '',
    kind: kind,
    name: name.trim(),
    accountId: accountId ?? '',
    amount: amount ?? const Money.zero(Currency.rub),
    every: every,
    day: day,
    advanceDay: halves ? advanceDay : null,
    next: next,
    onDay: onDay,
    reminder: reminder,
  );

  /// Whether its next time is the advance of a salary in halves.
  bool get nextIsAdvance => switch (advanceDay) {
    final advance? when halves =>
      CivilDate.onDay(next.year, next.month, advance) == next &&
          CivilDate.onDay(next.year, next.month, day) != next,
    _ => false,
  };

  /// The accounts a transfer can reach: the others of the same currency.
  List<Account> get targets => [
    for (final other in accounts)
      if (other.id != accountId && other.currency == account?.currency) other,
  ];

  /// Whether the form holds a payment that the ledger takes.
  bool get valid =>
      name.trim().isNotEmpty &&
      (part?.isPositive ?? false) &&
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
    (int?,)? advanceDay,
    ScheduleOnDay? onDay,
    ScheduleReminder? reminder,
    ReminderSettings? reminders,
    List<Account>? accounts,
    List<Category>? expenses,
    List<Category>? incomes,
    bool? failed,
    Transaction? madeFrom,
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
    advanceDay: advanceDay == null ? this.advanceDay : advanceDay.$1,
    onDay: onDay ?? this.onDay,
    reminder: reminder ?? this.reminder,
    reminders: reminders ?? this.reminders,
    accounts: accounts ?? this.accounts,
    expenses: expenses ?? this.expenses,
    incomes: incomes ?? this.incomes,
    failed: failed ?? this.failed,
    madeFrom: madeFrom ?? this.madeFrom,
  );
}

/// Fills in a new regular payment, or changes one (ADR 0023). A new one can
/// start as the regular income «Зарплата», which sets the payday of the money
/// of the days.
class ScheduleFormCubit extends Cubit<ScheduleFormState> {
  /// Creates the form of payment [id], or of a new one: a salary with
  /// [salary], or one made [from] an operation, which it starts as. It reads
  /// what it needs.
  ScheduleFormCubit(
    this._repository, {
    String? id,
    bool salary = false,
    String? from,
  }) : _id = id,
       super(ScheduleFormState(today: _repository.today())) {
    _reminders = _repository.watchReminders().listen(
      (reminders) => emit(state.copyWith(reminders: reminders)),
    );
    unawaited(_load(salary: salary, from: from));
  }

  final SchedulesRepository _repository;
  final String? _id;
  late final StreamSubscription<ReminderSettings> _reminders;

  /// Makes it an expense, an income or a transfer. A category of the other
  /// kind goes, a transfer gets an account to reach, and only an income keeps
  /// its advance.
  void kindChanged(TransactionKind kind) {
    final next = state.copyWith(
      kind: kind,
      advanceDay: kind == TransactionKind.income ? null : (null,),
    );
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

  /// Moves its next time to [day], whose day of the month it keeps. For a
  /// salary in halves, [day] gives the day of the rest, and the next time is
  /// the nearest of the two days.
  void nextChanged(CivilDate day) {
    final advance = state.advanceDay;
    if (!state.halves || advance == null) {
      return emit(state.copyWith(next: day, day: day.day));
    }
    if (day.day == advance) return;
    emit(
      state.copyWith(
        day: day.day,
        next: _firstOn(state.today, advance, day.day),
      ),
    );
  }

  /// Makes an income come in [halves], an advance and the rest, every month,
  /// or in one sum.
  void halvesChanged({required bool halves}) {
    if (!halves) return emit(state.copyWith(advanceDay: (null,)));
    final day = state.day;
    final advance = state.advanceDay ?? (day <= 15 ? day + 15 : day - 15);
    emit(
      state.copyWith(
        every: ScheduleEvery.month,
        advanceDay: (advance,),
        next: _firstOn(state.today, advance, day),
      ),
    );
  }

  /// Moves the advance of a salary in halves to [day] of the month.
  void advanceDayChanged(int day) {
    if (!state.halves || day == state.day) return;
    emit(
      state.copyWith(
        advanceDay: (day,),
        next: _firstOn(state.today, day, state.day),
      ),
    );
  }

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
    final amount = form.part!;
    final transfer = form.kind == TransactionKind.transfer;
    final advance = form.halves ? form.advanceDay : null;
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
            advanceDay: advance,
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
            day: advance == null ? null : form.day,
            advanceDay: advance,
            onDay: form.onDay,
            reminder: form.reminder,
            madeFrom: form.madeFrom?.id,
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

  @override
  Future<void> close() async {
    await _reminders.cancel();
    return super.close();
  }

  Future<void> _load({required bool salary, String? from}) async {
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
    if (id == null && from != null) {
      final made = await _repository.watchTransaction(from).first;
      if (isClosed) return;
      if (made != null && made.kind != TransactionKind.adjustment) {
        return emit(_madeFrom(loaded, made));
      }
    }
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
        // A salary in halves shows what it brings in a month.
        amountMinor:
            schedule.amount.minorUnits * (schedule.advanceDay == null ? 1 : 2),
        accountId: schedule.accountId,
        toAccountId: schedule.toAccountId,
        categoryId: schedule.categoryId,
        every: schedule.every,
        next: schedule.next,
        day: schedule.day,
        advanceDay: schedule.advanceDay,
        onDay: schedule.onDay,
        reminder: schedule.reminder,
        reminders: state.reminders,
        accounts: loaded.accounts,
        expenses: loaded.expenses,
        incomes: loaded.incomes,
      ),
    );
  }
}

/// The form of a new payment [loaded] as operation [made] gives it: its kind,
/// what it is called, its amount, accounts and category, every month on its
/// day from the next time after it. One that a statement brought is charged
/// by the bank, so it posts itself; one the person wrote asks first
/// (ADR 0023, point 22).
ScheduleFormState _madeFrom(ScheduleFormState loaded, Transaction made) {
  final transfer = made.kind == TransactionKind.transfer;
  final from = made.entries.first;
  final open = {for (final account in loaded.accounts) account.id};
  final categories = {for (final it in made.allocations) it.categoryId};
  final categoryId = transfer || categories.length != 1
      ? null
      : categories.single;
  final category = [
    ...loaded.expenses,
    ...loaded.incomes,
  ].where((it) => it.id == categoryId).firstOrNull;
  final note = made.note.trim();
  final day = made.occurredOn;
  final to = transfer ? made.entries.last.accountId : null;
  return loaded.copyWith(
    status: ScheduleFormStatus.editing,
    kind: made.kind,
    name: note.isNotEmpty ? note : category?.name ?? '',
    amountMinor: from.amount.minorUnits.abs(),
    accountId: open.contains(from.accountId)
        ? from.accountId
        : loaded.accounts.firstOrNull?.id,
    toAccountId: (open.contains(to) ? to : null,),
    categoryId: (category?.id,),
    every: ScheduleEvery.month,
    next: nextAfterOperation(day, today: loaded.today),
    day: day.day,
    onDay: made.source == TransactionSource.import
        ? ScheduleOnDay.post
        : ScheduleOnDay.ask,
    madeFrom: made,
  );
}

/// The first time of a monthly payment made from an operation of [made]: on
/// its day of the month, from [today] on, and after the operation, which is
/// a time of its own.
CivilDate nextAfterOperation(CivilDate made, {required CivilDate today}) {
  final day = made.day;
  var next = CivilDate.onDay(today.year, today.month, day);
  if (next.compareTo(today) < 0) {
    next = CivilDate.onDay(today.year, today.month + 1, day);
  }
  if (next.compareTo(made) <= 0) {
    next = CivilDate.onDay(made.year, made.month + 1, day);
  }
  return next;
}

/// The nearest time from [today] on of a salary with its advance on day
/// [advance] and the rest on day [day] of a month.
CivilDate _firstOn(CivilDate today, int advance, int day) {
  CivilDate from(int day) {
    final same = CivilDate.onDay(today.year, today.month, day);
    return same.compareTo(today) >= 0
        ? same
        : CivilDate.onDay(today.year, today.month + 1, day);
  }

  final a = from(advance);
  final b = from(day);
  return a.compareTo(b) <= 0 ? a : b;
}
