import 'dart:async';

import 'package:accounts_common/src/domain/accounts_overview.dart';
import 'package:accounts_common/src/domain/accounts_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

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
  StreamSubscription<void>? _subscription;

  /// Reads the accounts again after a failure.
  Future<void> retry() async {
    await _subscription?.cancel();
    emit(const AccountsLoading());
    _follow();
  }

  /// Hides account [id] from everyday lists, or brings it back.
  Future<void> setArchived(String id, {required bool archived}) =>
      _repository.setArchived(id, archived: archived);

  void _follow() {
    _subscription = _repository.watchAccounts().listen(
      (accounts) => emit(AccountsLoaded(AccountsOverview.of(accounts))),
      onError: (Object _) => emit(const AccountsFailed()),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
