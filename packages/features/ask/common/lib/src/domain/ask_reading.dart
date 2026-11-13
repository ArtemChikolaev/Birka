import 'package:ask_common/src/domain/ask_query.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// A fact that Birka already knows and answers in one card.
enum AskFact {
  /// What can be spent today until the salary.
  allowance,

  /// The regular payments that come next.
  payments,

  /// What the accounts hold together.
  capital,

  /// The rate of a currency.
  rate,
}

/// A screen that a question can lead to. The host knows its path.
enum AskPlace {
  /// The money until the salary.
  payday,

  /// The regular payments, the salary among them.
  schedules,

  /// The метки and trips.
  tags,

  /// The accounts.
  accounts,

  /// The categories.
  categories,

  /// The import of a statement.
  imports,

  /// What waits for a decision after an import.
  inbox,

  /// The copy of the ledger, its export and its wipe.
  backup,

  /// Help and feedback.
  help,

  /// What Birka told the person.
  notifications,

  /// The reports.
  reports,

  /// The settings of the device on «Ещё».
  settings,
}

/// Why a question gets a fixed reply instead of an answer.
enum AskRefusal {
  /// It asks for advice on money, which Birka never gives.
  advice,

  /// It is not about the money in Birka.
  offTopic,
}

/// What a question was read as (ADR 0028).
@immutable
sealed class AskReading {
  const AskReading();

  /// The reading as plain data, for the golden tests of the parser.
  Map<String, Object> toJson();
}

/// A question about the money in the ledger.
final class AskData extends AskReading {
  /// Creates the reading of [query], and of the screens it may also mean.
  const AskData(this.query, {this.places = const []});

  /// What the ledger counts.
  final AskQuery query;

  /// The screens that the words also name, such as the salary.
  final List<AskPlace> places;

  @override
  Map<String, Object> toJson() => {
    'data': query.toJson(),
    if (places.isNotEmpty) 'places': [for (final place in places) place.name],
  };
}

/// A question about a fact that Birka keeps.
final class AskFactReading extends AskReading {
  /// Creates the reading of [fact], of [currency] for a rate.
  const AskFactReading(this.fact, {this.currency});

  /// The fact.
  final AskFact fact;

  /// The currency of a rate.
  final Currency? currency;

  @override
  Map<String, Object> toJson() => {
    'fact': fact.name,
    'currency': ?currency?.code,
  };
}

/// A question that the help answers.
final class AskHelpReading extends AskReading {
  /// Creates the reading of the help [questions], by their place among the
  /// common questions, and of the screens the words also name.
  const AskHelpReading(this.questions, {this.places = const []});

  /// The common questions that answer it, the best first.
  final List<int> questions;

  /// The screens that the words also name.
  final List<AskPlace> places;

  @override
  Map<String, Object> toJson() => {
    'help': questions,
    if (places.isNotEmpty) 'places': [for (final place in places) place.name],
  };
}

/// A question that names screens.
final class AskPlacesReading extends AskReading {
  /// Creates the reading of [places].
  const AskPlacesReading(this.places);

  /// The screens, the best first.
  final List<AskPlace> places;

  @override
  Map<String, Object> toJson() => {
    'places': [for (final place in places) place.name],
  };
}

/// A question that gets a fixed reply.
final class AskRefused extends AskReading {
  /// Creates the reading of a question refused for [reason].
  const AskRefused(this.reason);

  /// Why.
  final AskRefusal reason;

  @override
  Map<String, Object> toJson() => {'refused': reason.name};
}

/// A question that Birka did not understand.
final class AskUnknown extends AskReading {
  /// Creates the reading.
  const AskUnknown();

  @override
  Map<String, Object> toJson() => {'unknown': true};
}
