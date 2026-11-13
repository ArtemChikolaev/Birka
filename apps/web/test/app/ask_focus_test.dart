import 'package:birka_web/app/ask_focus.dart';
import 'package:test/test.dart';

void main() {
  test('the question of an answer goes to the address and comes back', () {
    const question = 'кафе в октябре';
    final href = answerHref(question);

    expect(href, startsWith('ask/#'));
    expect(href, isNot(contains(' ')));
    expect(questionOf(href.substring('ask/#'.length)), question);
  });

  test('no question leads to the page itself', () {
    expect(answerHref(''), 'ask/');
    expect(questionOf(''), '');
  });

  test('a fragment with a broken encoding reads as no question', () {
    expect(questionOf('%E0%A4%A'), '');
  });
}
