import 'dart:convert';

import 'package:ask_common/ask_common.dart' show AskAnswer;
import 'package:birka_web/app/browser.dart';
import 'package:ledger/ledger.dart' show CivilDate;
import 'package:transactions_common/transactions_common.dart'
    show OperationsFocus;

const _key = 'birka-ask-focus';

/// The operations of an answer of «Спросить» with the question they came
/// from, as the page of the operations takes them (ADR 0028).
typedef QuestionFocus = ({OperationsFocus focus, String question});

/// Leaves the operations that [answer] counted for the page of the
/// operations, under [title], with the [question] they came from. Their days
/// run from the first of them to the last, so that taking the plaque off
/// shows the month of the last.
void handFocus(AskAnswer answer, String title, String question) {
  final days = [
    for (final operation in answer.operations) operation.transaction.occurredOn,
  ]..sort();
  if (days.isEmpty) return;
  handToNextPage(
    _key,
    jsonEncode({
      'title': title,
      'question': question,
      'ids': [
        for (final operation in answer.operations) operation.transaction.id,
      ],
      'first': '${days.first}',
      'last': '${days.last}',
    }),
  );
}

/// The operations that «Спросить» left for this page, once, or `null`.
QuestionFocus? takeFocus() {
  final text = takeHanded(_key);
  if (text == null) return null;
  try {
    final json = jsonDecode(text) as Map<String, Object?>;
    return (
      focus: OperationsFocus(
        title: json['title']! as String,
        ids: {for (final id in json['ids']! as List<Object?>) id! as String},
        first: CivilDate.parse(json['first']! as String),
        last: CivilDate.parse(json['last']! as String),
      ),
      question: json['question']! as String,
    );
  } on Object {
    return null;
  }
}

/// Where the answer to [question] opens again: the question stands in the
/// fragment of «Спросить».
String answerHref(String question) =>
    question.isEmpty ? 'ask/' : 'ask/#${Uri.encodeComponent(question)}';

/// The question that the fragment of «Спросить» holds.
String questionOf(String fragment) {
  try {
    return Uri.decodeComponent(fragment).trim();
  } on Object {
    // A fragment typed by hand can break the encoding.
    return '';
  }
}
