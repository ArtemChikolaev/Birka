/// The settings of Birka in pure Dart: what a person picks for this device,
/// shared by both hosts (ADR 0006, ADR 0011).
library;

export 'package:device_settings/device_settings.dart';
export 'package:l10n/l10n.dart' show AppLocale;
export 'package:money/money.dart' show Currency;
export 'package:rates/rates.dart' show BaseCurrency;

export 'src/di/register_settings.dart';
export 'src/presentation/settings_cubit.dart';
