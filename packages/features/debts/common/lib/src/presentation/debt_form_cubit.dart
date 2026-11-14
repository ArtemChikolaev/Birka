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
    this.personId,
    this.about = '',
    this.phone,
    this.fixed = false,
    this.debts = const [],
    this.people = const [],
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

  /// The person picked among the people of the debts, or `null` for a new
  /// one of [name] (ADR 0030).
  final String? personId;

  /// Who a new person is, such as «коллега», to tell namesakes apart.
  final String about;

  /// The number of a new person, typed or taken from a contact.
  final String? phone;

  /// Whether the other person came with the form, from the card of a debt,
  /// so that the form does not offer others.
  final bool fixed;

  /// Every debt there is, settled ones too.
  final List<Debt> debts;

  /// The people of the debts.
  final List<Person> people;

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

  /// The people to pick from, one chip for each: those of the latest debts
  /// first, then the others by name.
  List<Person> get chips {
    final ordered = debts.toList()
      ..sort((a, b) {
        final day = b.steps.firstOrNull?.day;
        final other = a.steps.firstOrNull?.day;
        if (day == null || other == null) return 0;
        return day.compareTo(other);
      });
    final ids = <String>[
      for (final debt in ordered) ?debt.personId,
      for (final person in people) person.id,
    ];
    final seen = <String>{};
    return [
      for (final id in ids)
        if (seen.add(id))
          ?people.where((person) => person.id == id).firstOrNull,
    ];
  }

  /// The person picked, or `null` for a new one.
  Person? get person =>
      people.where((person) => person.id == personId).firstOrNull;

  /// Someone already there with the name of a new person, whom the form asks
  /// to tell apart from them, until it says who the new one is.
  Person? get twin =>
      personId != null || name.trim().isEmpty || about.trim().isNotEmpty
      ? null
      : people.where((person) => _sameName(person.name, name)).firstOrNull;

  /// The debt of the person picked on [side] that the save adds to, or
  /// `null` for a new one.
  Debt? get match => personId == null
      ? null
      : debts
            .where((debt) => debt.side == side && debt.personId == personId)
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

  /// Whether the form can be saved. A namesake of someone there waits for
  /// the chip of that person or for who the new one is, so that two people
  /// of one name never look alike (ADR 0030).
  bool get canSave =>
      status == DebtFormStatus.editing &&
      name.trim().isNotEmpty &&
      twin == null &&
      amountMinor > 0 &&
      account != null;

  /// A copy with the given fields changed. [dueOn] takes a function, so that
  /// it can become `null`.
  DebtFormState copyWith({
    DebtFormStatus? status,
    DebtSide? side,
    String? name,
    String? Function()? personId,
    String? about,
    String? Function()? phone,
    List<Debt>? debts,
    List<Person>? people,
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
    personId: personId == null ? this.personId : personId(),
    about: about ?? this.about,
    phone: phone == null ? this.phone : phone(),
    fixed: fixed,
    debts: debts ?? this.debts,
    people: people ?? this.people,
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
      final people = await _repository.watchPeople().first;
      if (isClosed) return;
      final fixed = debts.where((debt) => debt.id == _debtId).firstOrNull;
      if (_debtId != null && fixed == null) {
        return emit(state.copyWith(status: DebtFormStatus.failed));
      }
      final next = state.copyWith(
        status: DebtFormStatus.editing,
        debts: debts,
        accounts: accounts,
        people: people,
        side: fixed?.side,
        name: fixed?.name,
        personId: () => fixed?.personId,
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

  /// The person picked [person] among the people of the debts.
  void personPicked(Person person) {
    if (state.fixed) return;
    emit(
      _withMatch(
        state.copyWith(
          personId: () => person.id,
          name: person.name,
          about: person.about,
          phone: () => person.phone,
          nameMissing: false,
        ),
      ),
    );
  }

  /// The person typed [name]: of someone new, even when it is the name of
  /// someone there, as names may repeat (ADR 0030).
  void nameChanged(String name) {
    if (state.fixed) return;
    final picked = state.person;
    emit(
      _withMatch(
        state.copyWith(
          name: name,
          personId: () => null,
          about: picked == null ? null : '',
          phone: picked == null ? null : () => null,
          nameMissing: false,
        ),
      ),
    );
  }

  /// The person typed who someone new is.
  void aboutChanged(String about) {
    if (state.personId != null) return;
    emit(state.copyWith(about: about));
  }

  /// The person typed the number of someone new, or took it from a contact.
  void phoneChanged(String? phone) {
    if (state.personId != null) return;
    final typed = phone?.trim() ?? '';
    emit(state.copyWith(phone: () => typed.isEmpty ? null : typed));
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
        personId: form.personId,
        about: form.about,
        phone: form.phone,
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
