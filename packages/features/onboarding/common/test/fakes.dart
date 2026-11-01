import 'package:device_settings/device_settings.dart';
import 'package:onboarding_common/onboarding_common.dart';

/// The settings in memory.
final class FakeSettingsStore implements SettingsStore {
  /// Creates a store that holds [values].
  FakeSettingsStore([Map<String, String>? values]) : values = values ?? {};

  /// What the store holds.
  final Map<String, String> values;

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// What one save of the onboarding carried.
typedef Saved = ({FirstAccount? account, List<ReadyCategory> categories});

/// The ledger in memory.
final class FakeOnboardingRepository implements OnboardingRepository {
  /// Whether the device holds an account.
  bool accounts = false;

  /// What the next call fails with.
  Exception? failure;

  /// Every save, in order.
  final saves = <Saved>[];

  @override
  Future<bool> hasAccounts() async {
    if (failure case final failure?) throw failure;
    return accounts;
  }

  @override
  Future<void> save({
    required FirstAccount? account,
    required List<ReadyCategory> categories,
  }) async {
    if (failure case final failure?) throw failure;
    saves.add((account: account, categories: categories));
  }
}
