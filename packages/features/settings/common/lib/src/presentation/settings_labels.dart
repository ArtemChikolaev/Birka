import 'package:l10n/l10n.dart';

/// The languages to choose from, with the one of the device first.
const List<AppLocale?> languageChoices = [null, ...AppLocale.values];

/// The name of [language], or what says that the app follows the device.
String languageLabel(AppLocale? language) => switch (language) {
  null => t.settings.deviceLanguage,
  AppLocale.en => t.settings.english,
  AppLocale.ru => t.settings.russian,
};
