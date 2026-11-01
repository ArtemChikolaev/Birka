import 'package:onboarding_common/src/domain/first_account.dart';
import 'package:onboarding_common/src/domain/ready_category.dart';

/// Where the onboarding leaves what it asked for.
abstract interface class OnboardingRepository {
  /// Whether this device holds any account, an archived one included.
  Future<bool> hasAccounts();

  /// Adds [account], if there is one, and [categories] in one go.
  Future<void> save({
    required FirstAccount? account,
    required List<ReadyCategory> categories,
  });
}
