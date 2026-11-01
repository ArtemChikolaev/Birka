import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

/// The languages to choose from, with the one of the device first.
const List<AppLocale?> languageChoices = [null, ...AppLocale.values];

/// The base currencies to choose from, with the first account first.
final List<Currency?> baseCurrencyChoices = [null, ...offeredCurrencies];

/// The name of [currency], or what says that totals follow the first account.
String baseCurrencyLabel(Currency? currency) => currency == null
    ? t.settings.firstAccountCurrency
    : t.app.currencies[currency.code] ?? currency.code;

/// The name of [language], or what says that the app follows the device.
String languageLabel(AppLocale? language) => switch (language) {
  null => t.settings.deviceLanguage,
  AppLocale.en => t.settings.english,
  AppLocale.ru => t.settings.russian,
};
