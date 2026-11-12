import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:tags_common/src/domain/tag_report.dart';
import 'package:tags_common/src/domain/tags_repository.dart';

/// Where the report of a метка stands.
enum TagReportStatus {
  /// The first read has not come back yet.
  loading,

  /// Everything is here.
  ready,

  /// There is no such метка.
  gone,

  /// Something could not be read.
  failed,
}

/// What the report of a метка shows (ADR 0027).
@immutable
final class TagReportState {
  /// Creates a state of [today].
  const TagReportState({
    required this.status,
    required this.today,
    this.report,
  });

  /// Where the report stands.
  final TagReportStatus status;

  /// Today on this device.
  final CivilDate today;

  /// What the метка took, once it is read.
  final TagReport? report;
}

/// Follows метка [_id], what wears it, and the rates of its totals.
final class TagReportCubit extends Cubit<TagReportState> {
  /// Creates the cubit of метка [_id] on [_repository].
  TagReportCubit(this._repository, this._id)
    : super(
        TagReportState(
          status: TagReportStatus.loading,
          today: _repository.today(),
        ),
      ) {
    void failed(Object _) {
      if (isClosed) return;
      emit(TagReportState(status: TagReportStatus.failed, today: state.today));
    }

    _subscriptions.addAll([
      _repository.watchTags().listen((tags) {
        _tag = tags.where((tag) => tag.id == _id).firstOrNull;
        _tagRead = true;
        _update();
      }, onError: failed),
      _repository.watchTransactionsOf(_id).listen((operations) {
        _operations = operations;
        _update();
      }, onError: failed),
      _repository.watchCategories().listen((categories) {
        _categories = categories;
        _update();
      }, onError: (Object _) {}),
      _repository.watchRates().listen((rates) {
        _rates = rates;
        _update();
      }, onError: (Object _) {}),
      _repository.watchBaseCurrency().listen((base) {
        _base = base;
        _baseRead = true;
        _update();
      }, onError: (Object _) {}),
      _repository.watchMainCurrency().listen((main) {
        _main = main;
        _update();
      }, onError: (Object _) {}),
    ]);
  }

  final TagsRepository _repository;
  final String _id;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Tag? _tag;
  var _tagRead = false;
  List<Transaction>? _operations;
  List<Category> _categories = const [];
  RateBook _rates = const RateBook.empty();
  Currency? _base;
  var _baseRead = false;
  Currency? _main;

  void _update() {
    final operations = _operations;
    if (!_tagRead || operations == null || !_baseRead || isClosed) return;
    final today = _repository.today();
    final tag = _tag;
    if (tag == null) {
      return emit(TagReportState(status: TagReportStatus.gone, today: today));
    }
    emit(
      TagReportState(
        status: TagReportStatus.ready,
        today: today,
        report: reportOf(
          tag: tag,
          operations: operations,
          categories: _categories,
          rates: _rates,
          base: _base ?? _main ?? Currency.rub,
          today: today,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
