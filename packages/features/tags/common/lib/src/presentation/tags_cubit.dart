import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:tags_common/src/domain/tag_report.dart';
import 'package:tags_common/src/domain/tags_repository.dart';

/// Where the list of метки stands.
enum TagsStatus {
  /// The first read has not come back yet.
  loading,

  /// Everything is here.
  ready,

  /// Something could not be read.
  failed,
}

/// What the list of метки shows (ADR 0027).
@immutable
final class TagsState {
  /// Creates a state of [today].
  const TagsState({
    required this.status,
    required this.today,
    this.summaries = const [],
  });

  /// Where the list stands.
  final TagsStatus status;

  /// Today on this device.
  final CivilDate today;

  /// What each метка took, in the order of the ledger.
  final List<TagSummary> summaries;

  /// The метки of [shelf], in their order.
  List<TagSummary> on(TagShelf shelf) => [
    for (final summary in summaries)
      if (shelfOf(summary.tag, today) == shelf) summary,
  ];

  /// Whether there is no метка yet.
  bool get isEmpty => summaries.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is TagsState &&
      other.status == status &&
      other.today == today &&
      _same(other.summaries, summaries);

  @override
  int get hashCode => Object.hash(status, today, Object.hashAll(summaries));
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Follows the метки and what each took.
final class TagsCubit extends Cubit<TagsState> {
  /// Creates the cubit on [_repository].
  TagsCubit(this._repository)
    : super(TagsState(status: TagsStatus.loading, today: _repository.today())) {
    void failed(Object _) {
      if (isClosed) return;
      emit(TagsState(status: TagsStatus.failed, today: state.today));
    }

    _subscriptions.addAll([
      _repository.watchTags().listen((tags) {
        _tags = tags;
        _update();
      }, onError: failed),
      _repository.watchTagged().listen((tagged) {
        _tagged = tagged;
        _update();
      }, onError: failed),
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
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<Tag>? _tags;
  List<Transaction>? _tagged;
  RateBook _rates = const RateBook.empty();
  Currency? _base;
  var _baseRead = false;
  Currency? _main;

  void _update() {
    final tags = _tags;
    final tagged = _tagged;
    if (tags == null || tagged == null || !_baseRead || isClosed) return;
    final base = _base ?? _main ?? Currency.rub;
    emit(
      TagsState(
        status: TagsStatus.ready,
        today: _repository.today(),
        summaries: summarize(tags, tagged, rates: _rates, base: base),
      ),
    );
  }

  /// Takes the days of trip [id] back off its expenses, from the toast that
  /// said what its save marked.
  Future<void> unmarkDays(String id) => _repository.unmarkDays(id);

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
