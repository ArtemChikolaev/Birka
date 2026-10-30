import 'package:accounts_common/accounts_common.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

import 'fake_accounts_repository.dart';

void main() {
  final rub = Money(100, Currency.rub);
  final card = AccountBalance(account('Card', rub), rub);

  Matcher loaded(List<String> names) => isA<AccountsLoaded>().having(
    (state) => state.overview.active.map((row) => row.account.name),
    'active accounts',
    names,
  );

  blocTest<AccountsCubit, AccountsState>(
    'shows the accounts as they change',
    build: () => AccountsCubit(FakeAccountsRepository([card])),
    expect: () => [
      loaded(['Card']),
    ],
  );

  test('follows later changes', () async {
    final repository = FakeAccountsRepository([card]);
    final cubit = AccountsCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    final cash = AccountBalance(account('Cash', rub), rub);
    repository.emit([card, cash]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, loaded(['Card', 'Cash']));
  });

  test('says so when the accounts cannot be read, and can retry', () async {
    final repository = FakeAccountsRepository([card]);
    final cubit = AccountsCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    repository.failStream();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<AccountsFailed>());

    await cubit.retry();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, loaded(['Card']));
  });

  test('puts an account away and brings it back', () async {
    final repository = FakeAccountsRepository([card]);
    final cubit = AccountsCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    await cubit.setArchived('Card', archived: true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, loaded([]));

    await cubit.setArchived('Card', archived: false);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, loaded(['Card']));
  });
}
