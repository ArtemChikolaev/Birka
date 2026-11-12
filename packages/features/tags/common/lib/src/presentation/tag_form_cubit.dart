import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:tags_common/src/domain/tags_repository.dart';

/// Where the form of a метка stands.
enum TagFormStatus {
  /// The метка to change is on its way.
  loading,

  /// The person is filling in the form.
  editing,

  /// A save is under way.
  saving,

  /// The метка is saved, and the form can close.
  saved,

  /// The метка could not be read or saved.
  failed,
}

/// What the form of a метка holds (ADR 0027).
@immutable
final class TagFormState {
  /// Creates a state.
  const TagFormState({
    required this.status,
    required this.today,
    required this.first,
    required this.last,
    this.name = '',
    this.trip = true,
    this.marksDays = true,
    this.toMark = 0,
    this.nameMissing = false,
    this.original,
    this.saved,
  });

  /// Where the form stands.
  final TagFormStatus status;

  /// Today on this device.
  final CivilDate today;

  /// What the person calls it.
  final String name;

  /// Whether it is a trip, with days.
  final bool trip;

  /// The first day of the trip.
  final CivilDate first;

  /// The last day of the trip.
  final CivilDate last;

  /// Whether the expenses of its days get it by themselves.
  final bool marksDays;

  /// How many expenses its days already have that it would put itself on.
  final int toMark;

  /// Whether a save was tried without a name.
  final bool nameMissing;

  /// The метка being changed, or `null` for a new one.
  final Tag? original;

  /// What the save wrote, once it did.
  final TagMarking? saved;

  /// Whether the form makes a new метка.
  bool get isNew => original == null;

  /// The days of the trip.
  TagDays get days => TagDays(first, last);

  /// A copy with the given fields changed.
  TagFormState copyWith({
    TagFormStatus? status,
    String? name,
    bool? trip,
    CivilDate? first,
    CivilDate? last,
    bool? marksDays,
    int? toMark,
    bool? nameMissing,
    Tag? original,
    TagMarking? saved,
  }) => TagFormState(
    status: status ?? this.status,
    today: today,
    name: name ?? this.name,
    trip: trip ?? this.trip,
    first: first ?? this.first,
    last: last ?? this.last,
    marksDays: marksDays ?? this.marksDays,
    toMark: toMark ?? this.toMark,
    nameMissing: nameMissing ?? this.nameMissing,
    original: original ?? this.original,
    saved: saved ?? this.saved,
  );
}

/// Fills in and saves a метка, or a new one, which starts as a trip of today
/// and the two days after it.
final class TagFormCubit extends Cubit<TagFormState> {
  /// Creates the form on [_repository].
  TagFormCubit(this._repository, {String? id, String name = ''})
    : _id = id,
      super(_start(_repository.today(), name: name, editing: id != null)) {
    final id = _id;
    unawaited(id == null ? _count() : _load(id));
  }

  final TagsRepository _repository;
  final String? _id;

  static TagFormState _start(
    CivilDate today, {
    required String name,
    required bool editing,
  }) => TagFormState(
    status: editing ? TagFormStatus.loading : TagFormStatus.editing,
    today: today,
    name: name.trim(),
    first: today,
    last: today.addDays(2),
  );

  Future<void> _load(String id) async {
    try {
      final tags = await _repository.watchTags().first;
      final tag = tags.where((tag) => tag.id == id).firstOrNull;
      if (isClosed) return;
      if (tag == null) {
        return emit(state.copyWith(status: TagFormStatus.failed));
      }
      final days = tag.days;
      emit(
        state.copyWith(
          status: TagFormStatus.editing,
          name: tag.name,
          trip: days != null,
          first: days?.first,
          last: days?.last,
          marksDays: days == null || tag.marksDays,
          original: tag,
        ),
      );
    } on Object {
      if (!isClosed) emit(state.copyWith(status: TagFormStatus.failed));
    }
  }

  /// The person typed [value] as the name.
  void nameChanged(String value) =>
      emit(state.copyWith(name: value, nameMissing: false));

  /// The person chose a trip, with days, or a метка without them.
  void tripChanged({required bool trip}) {
    emit(state.copyWith(trip: trip));
    unawaited(_count());
  }

  /// The person picked the days from [first] to [last]; a last day before the
  /// first moves to it.
  void daysChanged(CivilDate first, CivilDate last) {
    emit(
      state.copyWith(
        first: first,
        last: last.compareTo(first) < 0 ? first : last,
      ),
    );
    unawaited(_count());
  }

  /// The person chose whether the expenses of the days get it by themselves.
  void marksChanged({required bool marksDays}) {
    emit(state.copyWith(marksDays: marksDays));
    unawaited(_count());
  }

  /// Counts the expenses of the days of a new trip, which its save marks.
  Future<void> _count() async {
    if (!state.isNew || !state.trip) return;
    final days = state.days;
    try {
      final count = await _repository.expensesOf(days);
      if (isClosed || state.days != days) return;
      emit(state.copyWith(toMark: count));
    } on Object {
      // The caption then speaks of the days ahead.
    }
  }

  /// Saves the метка, unless it has no name.
  Future<void> save() async {
    if (state.status == TagFormStatus.saving) return;
    final name = state.name.trim();
    if (name.isEmpty) return emit(state.copyWith(nameMissing: true));
    emit(state.copyWith(status: TagFormStatus.saving));
    final days = state.trip ? state.days : null;
    final marksDays = state.trip && state.marksDays;
    try {
      final original = state.original;
      final saved = original == null
          ? await _repository.add(name: name, days: days, marksDays: marksDays)
          : await _repository.update(
              original.copyWith(
                name: name,
                days: () => days,
                marksDays: marksDays,
              ),
            );
      if (!isClosed) {
        emit(state.copyWith(status: TagFormStatus.saved, saved: saved));
      }
    } on Object {
      if (!isClosed) emit(state.copyWith(status: TagFormStatus.failed));
    }
  }

  /// Takes back what the save marked, from the toast after it.
  Future<void> undo() async {
    final saved = state.saved;
    if (saved == null || saved.marked == 0) return;
    await _repository.unmarkDays(saved.tag.id);
  }
}
