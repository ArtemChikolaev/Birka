import 'dart:async';

import 'package:accounts_common/src/domain/accounts_overview.dart';
import 'package:accounts_common/src/domain/accounts_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// What the list of accounts shows.
@immutable
sealed class AccountsState {
  const AccountsState();
}

/// The first read has not come back yet.
final class AccountsLoading extends AccountsState {
  /// Creates the state.
  const AccountsLoading();
}

/// The accounts are here.
final class AccountsLoaded extends AccountsState {
  /// Creates the state with [overview].
  const AccountsLoaded(this.overview);

  /// The accounts and their totals.
  final AccountsOverview overview;
}

/// The accounts could not be read.
final class AccountsFailed extends AccountsState {
  /// Creates the state.
  const AccountsFailed();
}

/// Follows the accounts in the local database.
class AccountsCubit extends Cubit<AccountsState> {
  /// Creates the cubit and starts to follow [_repository].
  AccountsCubit(this._repository) : super(const AccountsLoading()) {
    _follow();
  }

  final AccountsRepository _repository;
  List<StreamSubscription<void>> _subscriptions = const [];

  /// What has arrived so far. The list waits for all of it, so that its totals
  /// never appear without their rates.
  List<AccountBalance>? _accounts;
  RateBook? _rates;
  (Currency?,)? _base;

  /// Reads the accounts again after a failure.
  Future<void> retry() async {
    final cancelled = _cancel();
    emit(const AccountsLoading());
    _follow();
    await cancelled;
  }

  /// Hides account [id] from everyday lists, or brings it back.
  Future<void> setArchived(String id, {required bool archived}) =>
      _repository.setArchived(id, archived: archived);

  void _follow() {
    void failed(Object _) => emit(const AccountsFailed());
    _accounts = null;
    _rates = null;
    _base = null;
    _subscriptions = [
      _repository.watchAccounts().listen((accounts) {
        _accounts = accounts;
        _show();
      }, onError: failed),
      _repository.watchRates().listen((rates) {
        _rates = rates;
        _show();
      }, onError: failed),
      _repository.watchBaseCurrency().listen((base) {
        _base = (base,);
        _show();
      }, onError: failed),
    ];
  }

  void _show() {
    if ((_accounts, _rates, _base) case (
      final accounts?,
      final rates?,
      (final base,)?,
    )) {
      emit(
        AccountsLoaded(AccountsOverview.of(accounts, rates: rates, base: base)),
      );
    }
  }

  Future<void> _cancel() =>
      Future.wait(_subscriptions.map((subscription) => subscription.cancel()));

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }
}
