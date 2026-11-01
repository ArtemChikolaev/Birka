import 'package:device_settings/device_settings.dart';
import 'package:onboarding_common/src/domain/onboarding_repository.dart';

/// Whether this device starts with the onboarding: it has not been through it
/// and holds no accounts. A database that does not answer leaves the choice to
/// the first screen, which can say what is wrong.
Future<bool> onboardingNeeded(
  SettingsStore store,
  OnboardingRepository repository,
) async {
  if (Settings.readFrom(store).onboarded) return false;
  try {
    return !await repository.hasAccounts();
  } on Exception {
    return false;
  }
}
