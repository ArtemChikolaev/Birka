import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:debts_common/src/domain/debt.dart';
import 'package:debts_common/src/domain/debts_repository.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// Where the form of the terms of a debt stands.
enum DebtTermsStatus {
  /// The debt is on its way.
  loading,

  /// The person is filling in the form.
  editing,

  /// The terms are saved, and the form can close.
  saved,

  /// The debt is gone.
  gone,

  /// The debt could not be read, or the save failed.
  failed,
}

/// What the form that changes a debt holds: the name of the other person,
/// who they are and their number (ADR 0030), the day it should come back by
/// and the reminder of it (ADR 0029).
@immutable
final class DebtTermsState {
  /// Creates a state.
  const DebtTermsState({
    required this.status,
    required this.today,
    this.debt,
    this.name = '',
    this.about = '',
    this.phone,
    this.dueOn,
    this.reminds = false,
    this.nameMissing = false,
  });

  /// Where the form stands.
  final DebtTermsStatus status;

  /// Today on this device.
  final CivilDate today;

  /// The debt.
  final Debt? debt;

  /// The name of the other person.
  final String name;

  /// Who the other person is, such as «коллега».
  final String about;

  /// Their number, or `null`.
  final String? phone;

  /// The day the debt should come back by.
  final CivilDate? dueOn;

  /// Whether the phone reminds of the debt on [dueOn].
  final bool reminds;

  /// Whether a save was tried without a name.
  final bool nameMissing;

  /// A copy with the given fields changed. [dueOn] takes a function, so that
  /// it can become `null`.
  DebtTermsState copyWith({
    DebtTermsStatus? status,
    Debt? debt,
    String? name,
    String? about,
    String? Function()? phone,
    CivilDate? Function()? dueOn,
    bool? reminds,
    bool? nameMissing,
  }) => DebtTermsState(
    status: status ?? this.status,
    today: today,
    debt: debt ?? this.debt,
    name: name ?? this.name,
    about: about ?? this.about,
    phone: phone == null ? this.phone : phone(),
    dueOn: dueOn == null ? this.dueOn : dueOn(),
    reminds: reminds ?? this.reminds,
    nameMissing: nameMissing ?? this.nameMissing,
  );
}

/// Changes the other person of debt [_id], its day and the reminder of it.
final class DebtTermsCubit extends Cubit<DebtTermsState> {
  /// Creates the form on [_repository].
  DebtTermsCubit(this._repository, this._id, {bool reminders = true})
    : _reminders = reminders,
      super(
        DebtTermsState(
          status: DebtTermsStatus.loading,
          today: _repository.today(),
        ),
      ) {
    unawaited(_load());
  }

  final DebtsRepository _repository;
  final String _id;

  /// Whether this device reminds of debts: the site does not, so a day
  /// picked there turns no reminder on.
  final bool _reminders;

  Future<void> _load() async {
    try {
      final debts = await _repository.watchDebts().first;
      final people = await _repository.watchPeople().first;
      if (isClosed) return;
      final debt = debts.where((debt) => debt.id == _id).firstOrNull;
      if (debt == null) {
        return emit(state.copyWith(status: DebtTermsStatus.gone));
      }
      final person = people
          .where((person) => person.id == debt.personId)
          .firstOrNull;
      emit(
        state.copyWith(
          status: DebtTermsStatus.editing,
          debt: debt,
          name: debt.name,
          about: person?.about,
          phone: () => person?.phone,
          dueOn: () => debt.dueOn,
          reminds: debt.reminds,
        ),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: DebtTermsStatus.failed));
    }
  }

  /// The person typed [name].
  void nameChanged(String name) =>
      emit(state.copyWith(name: name, nameMissing: false));

  /// The person typed who the other one is.
  void aboutChanged(String about) => emit(state.copyWith(about: about));

  /// The person typed the number, or took it from a contact.
  void phoneChanged(String? phone) {
    final typed = phone?.trim() ?? '';
    emit(state.copyWith(phone: () => typed.isEmpty ? null : typed));
  }

  /// The person picked the day the debt should come back by, or none. A day
  /// turns the reminder on at first.
  void dueChanged(CivilDate? dueOn) => emit(
    state.copyWith(
      dueOn: () => dueOn,
      reminds:
          dueOn != null && (state.dueOn == null ? _reminders : state.reminds),
    ),
  );

  /// The person chose whether the phone reminds of the day.
  void remindsChanged({required bool reminds}) =>
      emit(state.copyWith(reminds: reminds && state.dueOn != null));

  /// Saves the terms.
  Future<void> save() async {
    final form = state;
    final debt = form.debt;
    if (debt == null || form.status != DebtTermsStatus.editing) return;
    if (form.name.trim().isEmpty) {
      return emit(form.copyWith(nameMissing: true));
    }
    try {
      await _repository.update(
        debt.id,
        name: form.name,
        about: form.about,
        phone: form.phone,
        terms: DebtTerms(
          side: debt.side,
          dueOn: form.dueOn,
          reminds: form.reminds && form.dueOn != null,
        ),
      );
      if (!isClosed) emit(state.copyWith(status: DebtTermsStatus.saved));
    } on Object {
      if (!isClosed) emit(state.copyWith(status: DebtTermsStatus.failed));
    }
  }
}
