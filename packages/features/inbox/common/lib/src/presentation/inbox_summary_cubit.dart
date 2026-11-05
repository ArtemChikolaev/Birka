import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inbox_common/src/domain/dismissed_pairs.dart';
import 'package:inbox_common/src/domain/inbox_repository.dart';
import 'package:inbox_common/src/domain/waiting.dart';
import 'package:inbox_common/src/presentation/inbox_cubit.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';

/// What waits in the inbox, for the ways to it on the overview and in More
/// (ADR 0022, point 9): the operations without a category and the transfers
/// to link, counted as the inbox counts them, but without its hints and its
/// categories. It follows the ledger and the pairs kept apart in
/// [_dismissed], wherever the person keeps them apart, and counts once the
/// ledger has given all it needs, so that no count shows for a moment.
final class InboxSummaryCubit extends Cubit<InboxState> {
  /// Creates the count on [_repository].
  InboxSummaryCubit(this._repository, this._dismissed)
    : super(const InboxState()) {
    _subscriptions = [
      _repository.watchTransactions().listen((it) {
        _transactions = it;
        _update();
      }, onError: _failed),
      _repository.watchAccounts().listen((it) {
        _accounts = it;
        _update();
      }, onError: _failed),
      _repository.watchRates().listen((it) {
        _rates = it;
        _update();
      }, onError: _failed),
      _repository.watchImports().listen((it) {
        _imports = it;
        _update();
      }, onError: _failed),
      _dismissed.changes.listen((_) => _update()),
    ];
  }

  final InboxRepository _repository;
  final DismissedPairs _dismissed;
  late final List<StreamSubscription<Object>> _subscriptions;

  List<Transaction>? _transactions;
  List<Account>? _accounts;
  RateBook? _rates;
  List<LedgerImport>? _imports;

  // The ways to the inbox stay as they were: with nothing counted they show
  // nothing that waits.
  void _failed(Object _) {
    if (!isClosed) emit(const InboxState(loading: false, failed: true));
  }

  void _update() {
    if (isClosed) return;
    if ((_transactions, _accounts, _rates, _imports) case (
      final transactions?,
      final accounts?,
      final rates?,
      final imports?,
    )) {
      final (:waiting, :pairs) = waitingIn(
        transactions,
        rates: rates,
        dismissed: _dismissed.keys,
      );
      emit(
        InboxState(
          loading: false,
          items: [for (final transaction in waiting) InboxItem(transaction)],
          pairs: pairs,
          accounts: accounts,
          rates: rates,
          latestImport: imports.firstOrNull,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
