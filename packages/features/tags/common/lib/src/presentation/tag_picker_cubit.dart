import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:tags_common/src/domain/tags_repository.dart';

/// What the picker of метки shows (ADR 0027).
@immutable
final class TagPickerState {
  /// Creates a state of [today].
  const TagPickerState({
    required this.today,
    required this.picked,
    this.tags,
    this.query = '',
  });

  /// Today on this device.
  final CivilDate today;

  /// The метки, or `null` while they are read.
  final List<Tag>? tags;

  /// The ids of the метки that are picked.
  final Set<String> picked;

  /// What the person typed to find or create a метка.
  final String query;

  /// The trips that the query finds, the one that goes on first.
  List<Tag> get trips =>
      _found.where((tag) => tag.isTrip).toList()
        ..sort((a, b) => (_now(b) ? 1 : 0).compareTo(_now(a) ? 1 : 0));

  /// The метки without days that the query finds.
  List<Tag> get plain => _found.where((tag) => !tag.isTrip).toList();

  /// Whether the query names no метка yet, so that one can be made of it.
  bool get canCreate {
    final key = searchKey(query);
    if (key.isEmpty) return false;
    return !(tags ?? const <Tag>[]).any((tag) => searchKey(tag.name) == key);
  }

  /// Whether there is no метка at all.
  bool get isEmpty => tags?.isEmpty ?? false;

  /// Whether trip [tag] goes on today.
  bool goesOn(Tag tag) => _now(tag);

  bool _now(Tag tag) => tag.days?.contains(today) ?? false;

  List<Tag> get _found {
    final key = searchKey(query);
    return [
      for (final tag in tags ?? const <Tag>[])
        if (key.isEmpty || searchKey(tag.name).contains(key)) tag,
    ];
  }

  /// A copy with the given fields changed.
  TagPickerState copyWith({
    List<Tag>? tags,
    Set<String>? picked,
    String? query,
  }) => TagPickerState(
    today: today,
    tags: tags ?? this.tags,
    picked: picked ?? this.picked,
    query: query ?? this.query,
  );
}

/// Picks the метки of an operation, starting from those it wears.
final class TagPickerCubit extends Cubit<TagPickerState> {
  /// Creates the picker on [_repository].
  TagPickerCubit(this._repository, {Set<String> picked = const {}})
    : super(TagPickerState(today: _repository.today(), picked: {...picked})) {
    _tags = _repository.watchTags().listen((tags) {
      if (!isClosed) emit(state.copyWith(tags: tags));
    }, onError: (Object _) {});
  }

  final TagsRepository _repository;
  late final StreamSubscription<List<Tag>> _tags;

  /// The person typed [value] in the field of the search.
  void queryChanged(String value) => emit(state.copyWith(query: value));

  /// Picks метка [id], or lets it go when it is picked.
  void toggle(String id) {
    final picked = {...state.picked};
    if (!picked.remove(id)) picked.add(id);
    emit(state.copyWith(picked: picked));
  }

  /// Picks метка [id] that the form just made, and clears the search.
  void created(String id) =>
      emit(state.copyWith(picked: {...state.picked, id}, query: ''));

  /// Makes a метка without days of the name in the search, where a form
  /// cannot open over the picker, as on the site: picks it, clears the
  /// search and gives its id. It gives `null` when the search names a метка
  /// already or the save fails.
  Future<String?> create() async {
    if (!state.canCreate) return null;
    try {
      final marking = await _repository.add(name: state.query.trim());
      final id = marking.tag.id;
      if (!isClosed) created(id);
      return id;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _tags.cancel();
    return super.close();
  }
}
