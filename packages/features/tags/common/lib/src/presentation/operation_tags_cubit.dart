import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:tags_common/src/domain/tags_repository.dart';

/// A метка that an operation wears, and how it came there.
typedef WornTag = ({Tag tag, TagMark mark});

/// What the card of an operation says of its метки (ADR 0027).
@immutable
final class OperationTagsState {
  /// Creates a state of [today].
  const OperationTagsState({
    required this.today,
    this.read = false,
    this.worn = const [],
    this.can = false,
  });

  /// Today on this device.
  final CivilDate today;

  /// Whether the operation and the метки are read.
  final bool read;

  /// The метки it wears, the trips first.
  final List<WornTag> worn;

  /// Whether it can wear метки: an operation that is there.
  final bool can;

  /// The ids of the метки it wears.
  Set<String> get picked => {for (final it in worn) it.tag.id};
}

/// Follows operation [_id] and the метки for its card.
final class OperationTagsCubit extends Cubit<OperationTagsState> {
  /// Creates the cubit of operation [_id] on [_repository].
  OperationTagsCubit(this._repository, this._id)
    : super(OperationTagsState(today: _repository.today())) {
    _subscriptions.addAll([
      _repository.watchTransaction(_id).listen((made) {
        _transaction = made;
        _transactionRead = true;
        _update();
      }, onError: (Object _) {}),
      _repository.watchTags().listen((tags) {
        _tags = tags;
        _update();
      }, onError: (Object _) {}),
    ]);
  }

  final TagsRepository _repository;
  final String _id;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Transaction? _transaction;
  var _transactionRead = false;
  List<Tag>? _tags;

  void _update() {
    final tags = _tags;
    if (!_transactionRead || tags == null || isClosed) return;
    final made = _transaction;
    if (made == null) {
      return emit(OperationTagsState(today: state.today, read: true));
    }
    final byId = {for (final tag in tags) tag.id: tag};
    final worn = [
      for (final MapEntry(key: id, value: mark) in made.tags.entries)
        if (mark != TagMark.off)
          if (byId[id] case final tag?) (tag: tag, mark: mark),
    ]..sort((a, b) => (b.tag.isTrip ? 1 : 0).compareTo(a.tag.isTrip ? 1 : 0));
    emit(
      OperationTagsState(
        today: state.today,
        read: true,
        worn: worn,
        can: made.kind != TransactionKind.adjustment,
      ),
    );
  }

  /// Puts exactly [tagIds] on the operation. The метки it already wears
  /// write nothing: a picker closed without a change leaves it as it is.
  Future<void> pick(Set<String> tagIds) async {
    final worn = state.picked;
    if (tagIds.length == worn.length && worn.containsAll(tagIds)) return;
    await _repository.setTags(_id, tagIds);
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
