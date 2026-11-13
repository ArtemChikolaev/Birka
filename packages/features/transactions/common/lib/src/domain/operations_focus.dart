import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// The operations an answer of «Спросить» counted, which the list of
/// operations shows alone under a plaque until the plaque is taken off
/// (ADR 0028).
@immutable
final class OperationsFocus {
  /// Creates the focus on [ids], the operations from [first] to [last] that
  /// the plaque [title] stands for.
  const OperationsFocus({
    required this.title,
    required this.ids,
    required this.first,
    required this.last,
  });

  /// What the plaque says, such as `Кафе · Октябрь 2026`.
  final String title;

  /// The operations it keeps.
  final Set<String> ids;

  /// The day of the first of them.
  final CivilDate first;

  /// The day of the last of them.
  final CivilDate last;
}
