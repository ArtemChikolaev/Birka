/// The onboarding in pure Dart: the three steps of a first launch, shared by
/// both hosts (ADR 0013).
library;

export 'package:device_settings/device_settings.dart'
    show baseCurrencyChoices, baseCurrencyLabel, languageLabel;
export 'package:l10n/l10n.dart' show AppLocale;
export 'package:ledger/ledger.dart' show AccountType, CategoryKind;
export 'package:money/money.dart' show Currency, Money, offeredCurrencies;

export 'src/di/register_onboarding.dart';
export 'src/domain/first_account.dart';
export 'src/domain/onboarding_needed.dart';
export 'src/domain/onboarding_repository.dart';
export 'src/domain/ready_category.dart';
export 'src/presentation/onboarding_cubit.dart';
