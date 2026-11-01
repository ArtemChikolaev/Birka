import 'package:bloc/bloc.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:device_settings/device_settings.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:onboarding_common/src/domain/first_account.dart';
import 'package:onboarding_common/src/domain/onboarding_repository.dart';
import 'package:onboarding_common/src/domain/ready_category.dart';
import 'package:rates/rates.dart';

/// The types the first account can take. A debt has its own sign and its own
/// words, so it waits for the form of accounts.
const offeredFirstTypes = <AccountType>[
  AccountType.debit,
  AccountType.cash,
  AccountType.savings,
];

final _spaces = RegExp(r'\s');

/// The steps, in their order.
enum OnboardingStep {
  /// What Birka is, the language and the base currency.
  welcome,

  /// The first account.
  account,

  /// The ready set of categories.
  categories,
}

/// Where the onboarding stands.
enum OnboardingStatus {
  /// The user is going through the steps.
  editing,

  /// A save is under way.
  saving,

  /// Everything is kept, and the app can open.
  finished,

  /// What the steps asked for could not be saved.
  failed,
}

/// Why the first account cannot be taken.
enum OnboardingError {
  /// The name is empty.
  nameMissing,

  /// The amount is not a number in the currency of the account.
  amountInvalid,
}

/// The ready sets of categories to choose from.
enum CategorySet {
  /// What most people need at first.
  short,

  /// Every ready category.
  full
  ;

  /// The categories of the set, in the language of the user.
  List<ReadyCategory> get categories => [
    for (final preset in categoryPresets)
      if (this == CategorySet.full || preset.basic)
        ReadyCategory(
          kind: preset.kind,
          name: t.categories.presets[preset.key] ?? preset.key,
          icon: preset.icon,
          color: paletteColors[preset.colorIndex],
        ),
  ];
}

/// What the steps hold.
@immutable
final class OnboardingState {
  /// Creates a state.
  const OnboardingState({
    required this.step,
    required this.status,
    required this.baseCurrency,
    required this.name,
    required this.type,
    required this.currency,
    required this.amount,
    required this.categorySet,
    this.errors = const {},
  });

  /// The step on the screen.
  final OnboardingStep step;

  /// Where the onboarding stands.
  final OnboardingStatus status;

  /// The currency of totals, or `null` to follow the first account.
  final Currency? baseCurrency;

  /// The name of the account as typed.
  final String name;

  /// The kind of the account.
  final AccountType type;

  /// The currency of the account.
  final Currency currency;

  /// What the account holds, as typed.
  final String amount;

  /// The ready set that the last step adds.
  final CategorySet categorySet;

  /// What stops the account from being taken.
  final Set<OnboardingError> errors;

  /// The amount as money, or `null` if it is not a number. People paste
  /// amounts with spaces between the groups of digits.
  Money? get balance {
    final text = amount.replaceAll(_spaces, '');
    try {
      return text.isEmpty ? Money.zero(currency) : Money.parse(text, currency);
    } on FormatException {
      return null;
    }
  }

  /// What a preview shows while the amount is being typed.
  Money get previewBalance => balance ?? Money.zero(currency);

  /// A copy with the given fields changed. [baseCurrency] is in a record,
  /// because `null` is a choice for it.
  OnboardingState copyWith({
    OnboardingStep? step,
    OnboardingStatus? status,
    (Currency?,)? baseCurrency,
    String? name,
    AccountType? type,
    Currency? currency,
    String? amount,
    CategorySet? categorySet,
    Set<OnboardingError>? errors,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      status: status ?? this.status,
      baseCurrency: baseCurrency == null ? this.baseCurrency : baseCurrency.$1,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      categorySet: categorySet ?? this.categorySet,
      errors: errors ?? this.errors,
    );
  }
}

/// Leads a new device through the three steps. The language and the base
/// currency apply at once, and the account and the categories wait for the end,
/// so that going back changes them and leaving adds nothing.
class OnboardingCubit extends Cubit<OnboardingState> {
  /// Creates the steps on [_repository] and [_store]. [deviceLanguage] is the
  /// language that the device reports, and [baseCurrency] is what the screens
  /// follow.
  OnboardingCubit(
    this._repository,
    this._store, {
    required String deviceLanguage,
    required BaseCurrency baseCurrency,
  }) : _deviceLanguage = deviceLanguage,
       _baseCurrency = baseCurrency,
       super(
         OnboardingState(
           step: OnboardingStep.welcome,
           status: OnboardingStatus.editing,
           baseCurrency: baseCurrency.value,
           name: '',
           type: offeredFirstTypes.first,
           currency: baseCurrency.value ?? offeredCurrencies.first,
           amount: '',
           categorySet: CategorySet.short,
         ),
       );

  final OnboardingRepository _repository;
  final SettingsStore _store;
  final String _deviceLanguage;
  final BaseCurrency _baseCurrency;

  /// Turns the app to [language]. The host redraws in it.
  Future<void> languageChanged(AppLocale language) async {
    if (language == LocaleSettings.currentLocale) return;
    final next = Settings.readFrom(_store).copyWith(language: (language,));
    await next.writeTo(_store);
    next.applyLanguage(device: _deviceLanguage);
  }

  /// Shows totals in [currency], or in that of the first account with `null`.
  /// The first account starts in the same currency.
  Future<void> baseCurrencyChanged(Currency? currency) async {
    if (currency == state.baseCurrency) return;
    emit(
      state.copyWith(
        baseCurrency: (currency,),
        currency: currency,
        errors: {...state.errors}..remove(OnboardingError.amountInvalid),
      ),
    );
    _baseCurrency.choose(currency);
    await Settings.readFrom(
      _store,
    ).copyWith(baseCurrency: (currency,)).writeTo(_store);
  }

  /// Sets the name of the account.
  void nameChanged(String value) =>
      _edit(state.copyWith(name: value), OnboardingError.nameMissing);

  /// Sets the kind of the account.
  void typeChanged(AccountType value) => emit(state.copyWith(type: value));

  /// Sets the currency of the account.
  void currencyChanged(Currency value) =>
      _edit(state.copyWith(currency: value), OnboardingError.amountInvalid);

  /// Sets what the account holds.
  void amountChanged(String value) =>
      _edit(state.copyWith(amount: value), OnboardingError.amountInvalid);

  /// Picks the ready set of categories.
  void categorySetChanged(CategorySet value) =>
      emit(state.copyWith(categorySet: value));

  /// Goes to the next step, or finishes after the last one.
  Future<void> next() async {
    switch (state.step) {
      case OnboardingStep.welcome:
        emit(state.copyWith(step: OnboardingStep.account));
      case OnboardingStep.account:
        final errors = _accountErrors();
        emit(
          errors.isEmpty
              ? state.copyWith(step: OnboardingStep.categories, errors: {})
              : state.copyWith(errors: errors),
        );
      case OnboardingStep.categories:
        await _finish(
          account: _account(),
          categories: state.categorySet.categories,
        );
    }
  }

  /// Goes one step back, with everything that was typed in place.
  void back() {
    if (state.step == OnboardingStep.welcome) return;
    emit(
      state.copyWith(
        step: OnboardingStep.values[state.step.index - 1],
        status: OnboardingStatus.editing,
      ),
    );
  }

  /// Opens the app without the steps that are left. An account that the second
  /// step took stays.
  Future<void> skip() => _finish(
    account: state.step == OnboardingStep.categories ? _account() : null,
    categories: const [],
  );

  Set<OnboardingError> _accountErrors() => {
    if (state.name.trim().isEmpty) OnboardingError.nameMissing,
    if (state.balance == null) OnboardingError.amountInvalid,
  };

  FirstAccount _account() => FirstAccount(
    name: state.name.trim(),
    type: state.type,
    balance: state.previewBalance,
  );

  void _edit(OnboardingState next, OnboardingError cleared) =>
      emit(next.copyWith(errors: {...next.errors}..remove(cleared)));

  /// The mark goes first: without it a save that worked could run again.
  Future<void> _finish({
    required FirstAccount? account,
    required List<ReadyCategory> categories,
  }) async {
    if (state.status == OnboardingStatus.saving) return;
    emit(state.copyWith(status: OnboardingStatus.saving));
    try {
      await Settings.readFrom(_store).copyWith(onboarded: true).writeTo(_store);
      if (account != null || categories.isNotEmpty) {
        await _repository.save(account: account, categories: categories);
      }
      emit(state.copyWith(status: OnboardingStatus.finished));
    } on Exception {
      emit(state.copyWith(status: OnboardingStatus.failed));
    }
  }
}
