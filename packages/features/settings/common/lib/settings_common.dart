/// The settings of Birka in pure Dart: what a person picks for this device,
/// shared by both hosts (ADR 0006, ADR 0011).
library;

export 'package:l10n/l10n.dart' show AppLocale;

export 'src/di/register_settings.dart';
export 'src/domain/settings.dart';
export 'src/domain/settings_store.dart';
export 'src/presentation/settings_cubit.dart';
export 'src/presentation/settings_labels.dart';
