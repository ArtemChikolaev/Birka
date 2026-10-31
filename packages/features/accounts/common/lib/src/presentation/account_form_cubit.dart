import 'dart:async';

import 'package:accounts_common/src/domain/account_draft.dart';
import 'package:accounts_common/src/domain/accounts_repository.dart';
import 'package:accounts_common/src/domain/offered_currencies.dart';
import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// The types the form offers. The rest come later, with their own rules.
const _offeredTypes = <AccountType>[
  AccountType.debit,
  AccountType.cash,
  AccountType.credit,
  AccountType.savings,
  AccountType.deposit,
];

final _spaces = RegExp(r'\s');

/// Why the form cannot be saved.
enum AccountFormError {
  /// The name is empty.
  nameMissing,

  /// The amount is not a number in the currency of the account.
  amountInvalid,

  /// The last digits are not four digits.
  lastDigitsInvalid,
}

/// Where the form stands.
enum AccountFormStatus {
  /// The account to edit is on its way.
  loading,

  /// The user is filling in the form.
  editing,

  /// A save is under way.
  saving,

  /// The account is saved, and the form can close.
  saved,

  /// The account could not be read or saved.
  failed,
}

/// The fields of the form.
@immutable
final class AccountFormState {
  /// Creates a state.
  const AccountFormState({
    required this.status,
    required this.name,
    required this.type,
    required this.currency,
    required this.amount,
    required this.lastDigits,
    required this.art,
    required this.includeInTotals,
    required this.isNew,
    this.archived = false,
    this.errors = const {},
  });

  /// Where the form stands.
  final AccountFormStatus status;

  /// The name as typed.
  final String name;

  /// The kind of the account.
  final AccountType type;

  /// The currency of the account.
  final Currency currency;

  /// What the account holds, as typed. For a credit card it is the debt.
  final String amount;

  /// The last digits as typed.
  final String lastDigits;

  /// The art of the account.
  final AccountArt art;

  /// Whether the account counts towards the totals.
  final bool includeInTotals;

  /// Whether the form creates an account instead of changing one.
  final bool isNew;

  /// Whether the account is archived.
  final bool archived;

  /// What stops the form from being saved.
  final Set<AccountFormError> errors;

  /// Whether the amount of this form is a debt, typed without a sign.
  bool get isDebt => type == AccountType.credit;

  /// Whether this form asks for the last digits of a card.
  bool get hasCard => type == AccountType.debit || type == AccountType.credit;

  /// The types to pick from. A type the form does not offer stays on the form
  /// of its account.
  List<AccountType> get types => [
    ..._offeredTypes,
    if (!_offeredTypes.contains(type)) type,
  ];

  /// The currencies to pick from. An existing account keeps its own.
  List<Currency> get currencies => isNew ? offeredCurrencies : [currency];

  /// The amount as money, or `null` if it is not a number. People paste
  /// amounts with spaces between the groups of digits.
  Money? get balance {
    final text = amount.replaceAll(_spaces, '');
    try {
      final parsed = text.isEmpty
          ? Money.zero(currency)
          : Money.parse(text, currency);
      return isDebt ? -parsed : parsed;
    } on FormatException {
      return null;
    }
  }

  /// What a preview shows while the amount is being typed.
  Money get previewBalance => balance ?? Money.zero(currency);

  /// A copy with the given fields changed.
  AccountFormState copyWith({
    AccountFormStatus? status,
    String? name,
    AccountType? type,
    Currency? currency,
    String? amount,
    String? lastDigits,
    AccountArt? art,
    bool? includeInTotals,
    bool? archived,
    Set<AccountFormError>? errors,
  }) {
    return AccountFormState(
      status: status ?? this.status,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      lastDigits: lastDigits ?? this.lastDigits,
      art: art ?? this.art,
      includeInTotals: includeInTotals ?? this.includeInTotals,
      isNew: isNew,
      archived: archived ?? this.archived,
      errors: errors ?? this.errors,
    );
  }
}

/// Fills in and saves the form of an account.
class AccountFormCubit extends Cubit<AccountFormState> {
  /// Creates the form for a new account, or loads account [accountId].
  AccountFormCubit(this._repository, {String? accountId})
    : _accountId = accountId,
      super(
        AccountFormState(
          status: accountId == null
              ? AccountFormStatus.editing
              : AccountFormStatus.loading,
          name: '',
          type: AccountType.debit,
          currency: offeredCurrencies.first,
          amount: '',
          lastDigits: '',
          art: AccountArt.emerald,
          includeInTotals: true,
          isNew: accountId == null,
        ),
      ) {
    if (accountId != null) unawaited(_load(accountId));
  }

  final AccountsRepository _repository;
  final String? _accountId;

  /// What the account held when the form opened.
  Money? _loaded;

  /// Sets the name.
  void nameChanged(String value) =>
      _edit(state.copyWith(name: value), AccountFormError.nameMissing);

  /// Sets the kind of the account. What a saved account holds stays as it is,
  /// so its amount changes sign when the field starts or stops meaning a debt.
  void typeChanged(AccountType value) {
    final next = state.copyWith(type: value);
    final balance = state.balance;
    if (state.isNew || balance == null || next.isDebt == state.isDebt) {
      emit(next);
    } else {
      emit(next.copyWith(amount: _amountOf(balance, debt: next.isDebt)));
    }
  }

  /// Sets the currency, which only a new account can change.
  void currencyChanged(Currency value) {
    if (state.isNew) {
      _edit(state.copyWith(currency: value), AccountFormError.amountInvalid);
    }
  }

  /// Sets the amount.
  void amountChanged(String value) =>
      _edit(state.copyWith(amount: value), AccountFormError.amountInvalid);

  /// Sets the last digits.
  void lastDigitsChanged(String value) => _edit(
    state.copyWith(lastDigits: value),
    AccountFormError.lastDigitsInvalid,
  );

  /// Sets the art.
  void artChanged(AccountArt value) => emit(state.copyWith(art: value));

  /// Sets whether the account counts towards the totals.
  void includeInTotalsChanged({required bool value}) =>
      emit(state.copyWith(includeInTotals: value));

  /// Checks the fields and saves the account.
  Future<void> save() async {
    final errors = <AccountFormError>{};
    final name = state.name.trim();
    if (name.isEmpty) errors.add(AccountFormError.nameMissing);
    final lastDigits = state.hasCard ? state.lastDigits.trim() : '';
    if (lastDigits.isNotEmpty && !_lastDigits.hasMatch(lastDigits)) {
      errors.add(AccountFormError.lastDigitsInvalid);
    }
    final balance = state.balance;
    if (balance == null) errors.add(AccountFormError.amountInvalid);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return;
    }

    emit(state.copyWith(status: AccountFormStatus.saving, errors: const {}));
    final draft = AccountDraft(
      name: name,
      type: state.type,
      currency: state.currency,
      // An amount left alone must not undo what happened since the form opened.
      balance: balance == _loaded ? null : balance,
      art: state.art,
      includeInTotals: state.includeInTotals,
      lastDigits: lastDigits.isEmpty ? null : lastDigits,
    );
    final id = _accountId;
    await _finish(
      id == null ? _repository.add(draft) : _repository.update(id, draft),
    );
  }

  /// Puts the account away, or brings it back, and closes the form.
  Future<void> toggleArchived() async {
    final id = _accountId;
    if (id == null) return;
    emit(state.copyWith(status: AccountFormStatus.saving));
    await _finish(_repository.setArchived(id, archived: !state.archived));
  }

  static final _lastDigits = RegExp(r'^\d{4}$');

  /// [balance] as the field shows it, which is without a sign for a debt.
  static String _amountOf(Money balance, {required bool debt}) =>
      balance.isZero ? '' : (debt ? -balance : balance).toDecimalString();

  void _edit(AccountFormState next, AccountFormError cleared) =>
      emit(next.copyWith(errors: {...next.errors}..remove(cleared)));

  Future<void> _finish(Future<void> write) async {
    try {
      await write;
      emit(state.copyWith(status: AccountFormStatus.saved));
    } on Exception {
      emit(state.copyWith(status: AccountFormStatus.failed));
    }
  }

  Future<void> _load(String id) async {
    try {
      final row = await _repository.account(id);
      if (isClosed) return;
      if (row == null) {
        emit(state.copyWith(status: AccountFormStatus.failed));
        return;
      }
      final AccountBalance(:account, :balance) = row;
      _loaded = balance;
      emit(
        state.copyWith(
          status: AccountFormStatus.editing,
          name: account.name,
          type: account.type,
          currency: account.currency,
          amount: _amountOf(
            balance,
            debt: account.type == AccountType.credit,
          ),
          lastDigits: account.lastDigits ?? '',
          art: account.art,
          includeInTotals: account.includeInTotals,
          archived: account.archived,
        ),
      );
    } on Exception {
      emit(state.copyWith(status: AccountFormStatus.failed));
    }
  }
}
