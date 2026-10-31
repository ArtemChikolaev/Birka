import 'dart:async';

import 'package:ledger/ledger.dart';
import 'package:overview_common/overview_common.dart';

/// Keeps what the first screen reads in memory.
final class FakeOverviewRepository implements OverviewRepository {
  /// Creates a repository.
  FakeOverviewRepository({
    this.accounts = const [],
    this.changes = const [],
    this.spending = const [],
  });

  /// The accounts.
  List<AccountBalance> accounts;

  /// What each day changed.
  List<DayChange> changes;

  /// What went through each category.
  List<CategoryTotal> spending;

  /// The error of the next read.
  Exception? readFailure;

  /// The months of spending that were asked for.
  final spendingFrom = <CivilDate>[];

  /// The last day of spending that was asked for.
  CivilDate? spendingTo;

  /// The first day of history that was asked for.
  CivilDate? changesFrom;

  final _accounts = StreamController<void>.broadcast();
  final _others = StreamController<void>.broadcast();

  /// Tells those who follow that something changed.
  void changed() {
    _accounts.add(null);
    _others.add(null);
  }

  /// Tells those who follow everything but the accounts that it changed.
  void changedOthers() => _others.add(null);

  /// Sends an error to those who follow the accounts.
  void breakAccounts(Object error) => _accounts.addError(error);

  Stream<T> _follow<T>(
    StreamController<void> changes,
    T Function() read,
  ) => Stream.multi((controller) {
    if (readFailure case final failure?) {
      controller.addError(failure);
    } else {
      controller.add(read());
    }
    final subscription = changes.stream.listen(
      (_) => controller.add(read()),
      onError: controller.addError,
    );
    controller.onCancel = () => unawaited(subscription.cancel());
  });

  @override
  Stream<List<AccountBalance>> watchAccounts() =>
      _follow(_accounts, () => accounts);

  @override
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) {
    changesFrom = from;
    return _follow(_others, () => changes);
  }

  @override
  Stream<List<CategoryTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) {
    spendingFrom.add(from);
    spendingTo = to;
    return _follow(_others, () => spending);
  }
}

/// An account for tests with [balance].
AccountBalance testBalance(
  String id,
  Money balance, {
  bool includeInTotals = true,
}) => AccountBalance(
  Account(
    id: id,
    name: id,
    type: AccountType.debit,
    openingBalance: Money.zero(balance.currency),
    includeInTotals: includeInTotals,
    archived: false,
    sortOrder: 0,
  ),
  balance,
);

/// What went through a category for tests.
CategoryTotal testTotal(String name, Money total) => CategoryTotal(
  Category(
    id: name,
    kind: CategoryKind.expense,
    name: name,
    archived: false,
    sortOrder: 0,
    color: '#4ade80',
  ),
  total,
);
