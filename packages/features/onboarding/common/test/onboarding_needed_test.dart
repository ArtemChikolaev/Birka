import 'package:device_settings/device_settings.dart';
import 'package:onboarding_common/onboarding_common.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late FakeSettingsStore store;
  late FakeOnboardingRepository repository;

  setUp(() {
    store = FakeSettingsStore();
    repository = FakeOnboardingRepository();
  });

  test('a new device starts with the onboarding', () async {
    expect(await onboardingNeeded(store, repository), isTrue);
  });

  test('a device that holds accounts does not', () async {
    repository.accounts = true;

    expect(await onboardingNeeded(store, repository), isFalse);
  });

  test('a device that has been through it does not', () async {
    await const Settings(onboarded: true).writeTo(store);

    expect(await onboardingNeeded(store, repository), isFalse);
  });

  test('a device that has been through it asks the database nothing', () async {
    await const Settings(onboarded: true).writeTo(store);
    repository.failure = Exception('never asked');

    expect(await onboardingNeeded(store, repository), isFalse);
  });

  test('a database that fails leaves it to the first screen', () async {
    repository.failure = Exception('disk');

    expect(await onboardingNeeded(store, repository), isFalse);
  });
}
