import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:debts_common/src/domain/debt.dart';
import 'package:debts_common/src/domain/debts_repository.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// Where the form of a return stands.
enum DebtReturnStatus {
  /// The debt and the accounts are on their way.
  loading,

  /// The person is filling in the form.
  editing,

  /// A save is under way.
  saving,

  /// The return is saved, and the form can close.
  saved,

  /// The debt is gone, or nothing is owed on it any more.
  gone,

  /// The debt or the accounts could not be read, or the save failed.
  failed,
}

/// What a return wrote: for the toast that says so.
@immutable
final class DebtReturned {
  /// Creates what a return wrote.
  const DebtReturned({
    required this.name,
    required this.side,
    required this.amount,
    required this.left,
  });

  /// The name of the other person.
  final String name;

  /// Who owed whom.
  final DebtSide side;

  /// What came back or went back.
  final Money amount;

  /// What is left of the debt after it.
  final Money left;

  /// Whether the return settled the debt.
  bool get closed => !left.isPositive;
}

/// What the form of a return holds: all that is left, or a part of it, on
/// an account in the currency of the debt (ADR 0029).
@immutable
final class DebtReturnState {
  /// Creates a state.
  const DebtReturnState({
    required this.status,
    required this.today,
    required this.day,
    this.debt,
    this.accounts = const [],
    this.accountId,
    this.all = true,
    this.partMinor = 0,
    this.saved,
  });

  /// Where the form stands.
  final DebtReturnStatus status;

  /// Today on this device.
  final CivilDate today;

  /// The debt.
  final Debt? debt;

  /// The accounts of the person, with what each holds.
  final List<AccountBalance> accounts;

  /// The account the money comes to or goes from.
  final String? accountId;

  /// Whether all that is left comes back.
  final bool all;

  /// The part that comes back, in minor units of the currency of the debt.
  final int partMinor;

  /// The day of the return.
  final CivilDate day;

  /// What the save wrote, once it did.
  final DebtReturned? saved;

  /// The accounts in the currency of the debt.
  List<AccountBalance> get offered => [
    for (final row in accounts)
      if (row.account.currency == debt?.currency) row,
  ];

  /// The account the money comes to or goes from, while it is offered.
  Account? get account => offered
      .map((row) => row.account)
      .where((account) => account.id == accountId)
      .firstOrNull;

  /// What comes back.
  Money? get amount => switch (debt) {
    final debt? => all ? debt.left : Money(partMinor, debt.currency),
    null => null,
  };

  /// Whether the part is more than what is left.
  bool get tooMuch => !all && debt != null && partMinor > debt!.left.minorUnits;

  /// What is left once the return is saved.
  Money? get leftAfter => switch ((debt, amount)) {
    (final debt?, final amount?) when !tooMuch => debt.left - amount,
    _ => null,
  };

  /// Whether no account is in the currency of the debt.
  bool get noAccount => debt != null && offered.isEmpty;

  /// Whether the form can be saved.
  bool get canSave =>
      status == DebtReturnStatus.editing &&
      account != null &&
      (amount?.isPositive ?? false) &&
      !tooMuch;

  /// A copy with the given fields changed.
  DebtReturnState copyWith({
    DebtReturnStatus? status,
    Debt? debt,
    List<AccountBalance>? accounts,
    String? accountId,
    bool? all,
    int? partMinor,
    CivilDate? day,
    DebtReturned? saved,
  }) => DebtReturnState(
    status: status ?? this.status,
    today: today,
    day: day ?? this.day,
    debt: debt ?? this.debt,
    accounts: accounts ?? this.accounts,
    accountId: accountId ?? this.accountId,
    all: all ?? this.all,
    partMinor: partMinor ?? this.partMinor,
    saved: saved ?? this.saved,
  );
}

/// Fills in and saves a return of debt [_id]: money that the other one gives
/// back, or that the person gives back.
final class DebtReturnCubit extends Cubit<DebtReturnState> {
  /// Creates the form on [_repository].
  DebtReturnCubit(this._repository, this._id)
    : super(
        DebtReturnState(
          status: DebtReturnStatus.loading,
          today: _repository.today(),
          day: _repository.today(),
        ),
      ) {
    unawaited(_load());
  }

  final DebtsRepository _repository;
  final String _id;

  Future<void> _load() async {
    try {
      final debts = await _repository.watchDebts().first;
      final accounts = await _repository.watchAccounts().first;
      if (isClosed) return;
      final debt = debts.where((debt) => debt.id == _id).firstOrNull;
      if (debt == null || debt.closed) {
        return emit(state.copyWith(status: DebtReturnStatus.gone));
      }
      final offered = [
        for (final row in accounts)
          if (row.account.currency == debt.currency) row.account.id,
      ];
      final last = debt.steps.firstOrNull?.account?.id;
      emit(
        state.copyWith(
          status: DebtReturnStatus.editing,
          debt: debt,
          accounts: accounts,
          accountId: offered.contains(last) ? last : offered.firstOrNull,
        ),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: DebtReturnStatus.failed));
    }
  }

  /// All that is left comes back, or a part of it.
  void allChanged({required bool all}) => emit(state.copyWith(all: all));

  /// Sets the part, in minor units of the currency of the debt.
  void partChanged(int minorUnits) =>
      emit(state.copyWith(partMinor: minorUnits < 0 ? 0 : minorUnits));

  /// The person picked account [id].
  void accountChanged(String id) => emit(state.copyWith(accountId: id));

  /// The person picked the day of the return.
  void dayChanged(CivilDate day) => emit(state.copyWith(day: day));

  /// Saves the return.
  Future<void> save() async {
    final form = state;
    final debt = form.debt;
    final account = form.account;
    final amount = form.amount;
    final left = form.leftAfter;
    if (!form.canSave ||
        debt == null ||
        account == null ||
        amount == null ||
        left == null) {
      return;
    }
    emit(form.copyWith(status: DebtReturnStatus.saving));
    try {
      await _repository.settle(
        debt.id,
        accountId: account.id,
        amount: amount,
        day: form.day,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DebtReturnStatus.saved,
          saved: DebtReturned(
            name: debt.name,
            side: debt.side,
            amount: amount,
            left: left,
          ),
        ),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: DebtReturnStatus.failed));
    }
  }
}
