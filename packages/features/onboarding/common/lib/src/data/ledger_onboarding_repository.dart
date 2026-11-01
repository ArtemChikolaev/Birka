import 'package:ledger/ledger.dart';
import 'package:onboarding_common/src/domain/first_account.dart';
import 'package:onboarding_common/src/domain/onboarding_repository.dart';
import 'package:onboarding_common/src/domain/ready_category.dart';

/// Leaves everything in the ledger, which holds its rules.
final class LedgerOnboardingRepository implements OnboardingRepository {
  /// Creates a repository on [_ledger].
  const LedgerOnboardingRepository(this._ledger);

  final LedgerRepository _ledger;

  @override
  Future<bool> hasAccounts() async {
    final accounts = await _ledger.watchAccounts(includeArchived: true).first;
    return accounts.isNotEmpty;
  }

  @override
  Future<void> save({
    required FirstAccount? account,
    required List<ReadyCategory> categories,
  }) => _ledger.atomically(() async {
    if (account != null) {
      await _ledger.addAccount(
        name: account.name,
        type: account.type,
        openingBalance: account.balance,
      );
    }
    for (final category in categories) {
      await _ledger.addCategory(
        kind: category.kind,
        name: category.name,
        icon: category.icon,
        color: category.color,
      );
    }
  });
}
