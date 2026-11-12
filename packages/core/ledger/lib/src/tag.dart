import 'package:ledger/src/civil_date.dart';
import 'package:ledger/src/transaction.dart';
import 'package:meta/meta.dart';

/// How a метка came onto a transaction (ADR 0027).
enum TagMark {
  /// The person put it on.
  hand,

  /// The days of its trip put it on: the transaction is an expense of those
  /// days.
  days,

  /// The person took off a метка that the days of its trip had put on, so
  /// that the days leave the transaction alone from then on.
  off,
}

/// The days of a trip, the first and the last included.
@immutable
final class TagDays {
  /// Creates the days from [first] to [last].
  TagDays(this.first, this.last) {
    if (last.compareTo(first) < 0) {
      throw ArgumentError('A trip ends on $last before it starts on $first');
    }
  }

  /// The first day.
  final CivilDate first;

  /// The last day.
  final CivilDate last;

  /// How many days the trip lasts.
  int get length => first.daysUntil(last) + 1;

  /// Whether [day] is one of the days.
  bool contains(CivilDate day) =>
      day.compareTo(first) >= 0 && day.compareTo(last) <= 0;

  @override
  bool operator ==(Object other) =>
      other is TagDays && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => '$first..$last';
}

/// A метка that transactions wear besides their category: a project, an
/// event, or a trip with its [days] (ADR 0027).
@immutable
final class Tag {
  /// Creates a метка.
  const Tag({
    required this.id,
    required this.name,
    this.days,
    this.marksDays = false,
    this.archived = false,
  });

  /// The id.
  final String id;

  /// What the person calls it.
  final String name;

  /// The days of a trip, or `null` for a метка without days.
  final TagDays? days;

  /// Whether the expenses of its [days] get it by themselves.
  final bool marksDays;

  /// Whether the lists leave it out.
  final bool archived;

  /// Whether it is a trip: a метка with days.
  bool get isTrip => days != null;

  /// Whether its days put it on a transaction of [kind] from [source] on
  /// [day] by themselves: an expense of those days, unless a regular payment
  /// gave it, as the rent at home is not a cost of the trip.
  bool marks({
    required TransactionKind kind,
    required TransactionSource source,
    required CivilDate day,
  }) =>
      marksDays &&
      !archived &&
      (days?.contains(day) ?? false) &&
      kind == TransactionKind.expense &&
      source != TransactionSource.recurring;

  /// A copy with what changes.
  Tag copyWith({
    String? name,
    TagDays? Function()? days,
    bool? marksDays,
    bool? archived,
  }) => Tag(
    id: id,
    name: name ?? this.name,
    days: days == null ? this.days : days(),
    marksDays: marksDays ?? this.marksDays,
    archived: archived ?? this.archived,
  );

  @override
  bool operator ==(Object other) =>
      other is Tag &&
      other.id == id &&
      other.name == name &&
      other.days == days &&
      other.marksDays == marksDays &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(id, name, days, marksDays, archived);
}

/// A метка after a write, with how many expenses its days put it on then.
@immutable
final class TagMarking {
  /// Creates the result of a write of [tag].
  const TagMarking(this.tag, {required this.marked});

  /// The метка as it was written.
  final Tag tag;

  /// How many expenses its days put it on in that write.
  final int marked;
}
