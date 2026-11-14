import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:debts_common/src/domain/debt.dart';
import 'package:debts_common/src/domain/debts_repository.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// Where the form of a debt stands.
enum DebtFormStatus {
  /// The debts and the accounts are on their way.
  loading,

  /// The person is filling in the form.
  editing,

  /// A save is under way.
  saving,

  /// The debt is saved, and the form can close.
  saved,

  /// The debts or the accounts could not be read, or the save failed.
  failed,
}

/// What a save of the form wrote: for the toast that says so.
@immutable
final class DebtSaved {
  /// Creates what a save wrote.
  const DebtSaved({
    required this.debtId,
    required this.name,
    required this.amount,
  });

  /// The debt that took the money.
  final String debtId;

  /// The name of the other person.
  final String name;

  /// What moved.
  final Money amount;
}

/// What the form of a new debt holds, or of more money on a debt that is
/// there (ADR 0029).
@immutable
final class DebtFormState {
  /// Creates a state.
  const DebtFormState({
    required this.status,
    required this.today,
    required this.side,
    required this.day,
    this.name = '',
    this.fixed = false,
    this.debts = const [],
    this.accounts = const [],
    this.accountId,
    this.amountMinor = 0,
    this.dueOn,
    this.note = '',
    this.reminds = false,
    this.nameMissing = false,
    this.saved,
  });

  /// Where the form stands.
  final DebtFormStatus status;

  /// Today on this device.
  final CivilDate today;

  /// Whether the person lends or borrows.
  final DebtSide side;

  /// The name of the other person.
  final String name;

  /// Whether the other person came with the form, from the card of a debt,
  /// so that the form does not offer others.
  final bool fixed;

  /// Every debt there is, settled ones too.
  final List<Debt> debts;

  /// The accounts of the person, with what each holds.
  final List<AccountBalance> accounts;

  /// The account the money goes from or comes to.
  final String? accountId;

  /// The amount, in minor units of the currency of the account.
  final int amountMinor;

  /// The day of the transfer.
  final CivilDate day;

  /// The day the debt should come back by.
  final CivilDate? dueOn;

  /// The note of the transfer.
  final String note;

  /// Whether the phone reminds of the debt on [dueOn].
  final bool reminds;

  /// Whether a save was tried without a name.
  final bool nameMissing;

  /// What the save wrote, once it did.
  final DebtSaved? saved;

  /// The people of the debts to pick from: one chip for each name, the
  /// latest debt first.
  List<String> get people {
    final ordered = debts.toList()
      ..sort((a, b) {
        final day = b.steps.firstOrNull?.day;
        final other = a.steps.firstOrNull?.day;
        if (day == null || other == null) return 0;
        return day.compareTo(other);
      });
    final names = <String>[];
    for (final debt in ordered) {
      if (!names.any((name) => _sameName(name, debt.name))) {
        names.add(debt.name);
      }
    }
    return names;
  }

  /// The debt of [name] on [side] that the save adds to, or `null` for a new
  /// one.
  Debt? get match => debts
      .where((debt) => debt.side == side && _sameName(debt.name, name))
      .firstOrNull;

  /// The accounts the money can go from or come to: those in the currency
  /// of the debt that is there, or every one for a new debt.
  List<AccountBalance> get offered {
    final currency = match?.currency;
    return [
      for (final row in accounts)
        if (currency == null || row.account.currency == currency) row,
    ];
  }

  /// The account the money goes from or comes to, while it is offered.
  Account? get account => offered
      .map((row) => row.account)
      .where((account) => account.id == accountId)
      .firstOrNull;

  /// The currency of the amount.
  Currency? get currency => account?.currency ?? match?.currency;

  /// The amount, once there is an account.
  Money? get amount => switch (currency) {
    final currency? => Money(amountMinor, currency),
    null => null,
  };

  /// Whether the debt that is there is in a currency that no account has.
  bool get noAccount => match != null && offered.isEmpty;

  /// Whether the form can be saved.
  bool get canSave =>
      status == DebtFormStatus.editing &&
      name.trim().isNotEmpty &&
      amountMinor > 0 &&
      account != null;

  /// A copy with the given fields changed. [dueOn] takes a function, so that
  /// it can become `null`.
  DebtFormState copyWith({
    DebtFormStatus? status,
    DebtSide? side,
    String? name,
    List<Debt>? debts,
    List<AccountBalance>? accounts,
    String? accountId,
    int? amountMinor,
    CivilDate? day,
    CivilDate? Function()? dueOn,
    String? note,
    bool? reminds,
    bool? nameMissing,
    DebtSaved? saved,
  }) => DebtFormState(
    status: status ?? this.status,
    today: today,
    side: side ?? this.side,
    name: name ?? this.name,
    fixed: fixed,
    debts: debts ?? this.debts,
    accounts: accounts ?? this.accounts,
    accountId: accountId ?? this.accountId,
    amountMinor: amountMinor ?? this.amountMinor,
    day: day ?? this.day,
    dueOn: dueOn == null ? this.dueOn : dueOn(),
    note: note ?? this.note,
    reminds: reminds ?? this.reminds,
    nameMissing: nameMissing ?? this.nameMissing,
    saved: saved ?? this.saved,
  );
}

bool _sameName(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

/// Fills in and saves a debt: money lent or borrowed, to a new person or to
/// one whose debt is there.
final class DebtFormCubit extends Cubit<DebtFormState> {
  /// Creates the form on [_repository]. [debtId] fixes the other person to
  /// the one of that debt, as «Ещё в долг» on its card does.
  DebtFormCubit(
    this._repository, {
    String? debtId,
    DebtSide side = DebtSide.lent,
    bool reminders = true,
  }) : _debtId = debtId,
       _reminders = reminders,
       super(
         DebtFormState(
           status: DebtFormStatus.loading,
           today: _repository.today(),
           day: _repository.today(),
           side: side,
           fixed: debtId != null,
         ),
       ) {
    unawaited(_load());
  }

  final DebtsRepository _repository;
  final String? _debtId;

  /// Whether this device reminds of debts: the site does not, so a day
  /// picked there turns no reminder on.
  final bool _reminders;

  Future<void> _load() async {
    try {
      final debts = await _repository.watchDebts().first;
      final accounts = await _repository.watchAccounts().first;
      if (isClosed) return;
      final fixed = debts.where((debt) => debt.id == _debtId).firstOrNull;
      if (_debtId != null && fixed == null) {
        return emit(state.copyWith(status: DebtFormStatus.failed));
      }
      final next = state.copyWith(
        status: DebtFormStatus.editing,
        debts: debts,
        accounts: accounts,
        side: fixed?.side,
        name: fixed?.name,
      );
      emit(_withMatch(next));
    } on Object {
      if (!isClosed) emit(state.copyWith(status: DebtFormStatus.failed));
    }
  }

  /// The person lends, or borrows.
  void sideChanged(DebtSide side) {
    if (state.fixed || side == state.side) return;
    emit(_withMatch(state.copyWith(side: side)));
  }

  /// The person picked [name] among the people of the debts, or typed it.
  void nameChanged(String name) {
    if (state.fixed) return;
    emit(_withMatch(state.copyWith(name: name, nameMissing: false)));
  }

  /// The person picked account [id].
  void accountChanged(String id) => emit(state.copyWith(accountId: id));

  /// Sets the amount, in minor units of the currency of the account.
  void amountChanged(int minorUnits) =>
      emit(state.copyWith(amountMinor: minorUnits < 0 ? 0 : minorUnits));

  /// The person picked the day of the transfer.
  void dayChanged(CivilDate day) => emit(state.copyWith(day: day));

  /// The person picked the day the debt should come back by, or none. A day
  /// turns the reminder on at first.
  void dueChanged(CivilDate? dueOn) => emit(
    state.copyWith(
      dueOn: () => dueOn,
      reminds:
          dueOn != null && (state.dueOn == null ? _reminders : state.reminds),
    ),
  );

  /// The person typed [note].
  void noteChanged(String note) => emit(state.copyWith(note: note));

  /// The person chose whether the phone reminds of the day.
  void remindsChanged({required bool reminds}) =>
      emit(state.copyWith(reminds: reminds && state.dueOn != null));

  /// Saves the debt.
  Future<void> save() async {
    if (state.name.trim().isEmpty) {
      return emit(state.copyWith(nameMissing: true));
    }
    final form = state;
    final account = form.account;
    final amount = form.amount;
    if (!form.canSave || account == null || amount == null) return;
    emit(form.copyWith(status: DebtFormStatus.saving));
    try {
      final id = await _repository.open(
        name: form.name,
        side: form.side,
        accountId: account.id,
        amount: amount,
        day: form.day,
        debtId: form.match?.id,
        note: form.note,
        terms: DebtTerms(
          side: form.side,
          dueOn: form.dueOn,
          reminds: form.reminds && form.dueOn != null,
        ),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DebtFormStatus.saved,
          saved: DebtSaved(
            debtId: id,
            name: form.match?.name ?? form.name.trim(),
            amount: amount,
          ),
        ),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: DebtFormStatus.failed));
    }
  }

  /// Takes the terms of the debt that the name now points at, and an account
  /// in its currency.
  DebtFormState _withMatch(DebtFormState next) {
    final match = next.match;
    final previous = state.match;
    var form = next;
    if (match != null && match.id != previous?.id) {
      form = form.copyWith(
        dueOn: () => match.closed ? null : match.dueOn,
        reminds: !match.closed && match.reminds,
      );
    }
    final offered = form.offered;
    final kept = offered.any((row) => row.account.id == form.accountId);
    if (!kept && offered.isNotEmpty) {
      form = form.copyWith(accountId: _usual(match, offered));
    }
    return form;
  }

  /// The account that money of [debt] moved on last, when it is offered, or
  /// the first one.
  static String _usual(Debt? debt, List<AccountBalance> offered) {
    final last = debt?.steps.firstOrNull?.account?.id;
    return offered.any((row) => row.account.id == last)
        ? last!
        : offered.first.account.id;
  }
}
