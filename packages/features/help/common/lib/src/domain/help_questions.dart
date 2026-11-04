import 'package:l10n/l10n.dart';
import 'package:meta/meta.dart';

/// A common question with its answer.
@immutable
final class HelpQuestion {
  /// Creates a question.
  const HelpQuestion(this.question, this.answer);

  /// What people ask.
  final String question;

  /// What the help answers.
  final String answer;

  /// Whether every word of [query] is in the question or in the answer. Case
  /// and the letter ё do not matter, and an empty query finds everything.
  bool matches(String query) {
    final text = searchKey('$question $answer');
    final words = searchKey(query).split(RegExp(r'\s+'));
    return words.every(text.contains);
  }
}

/// The common questions in the language of the app, the commonest first.
List<HelpQuestion> helpQuestions() => [
  HelpQuestion(t.help.storageQuestion, t.help.storageAnswer),
  HelpQuestion(t.help.moveQuestion, t.help.moveAnswer),
  HelpQuestion(t.help.ratesQuestion, t.help.ratesAnswer),
  HelpQuestion(t.help.importQuestion, t.help.importAnswer),
  HelpQuestion(t.help.hideQuestion, t.help.hideAnswer),
];
