import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('asks five questions, where the data lives first', () {
    final questions = helpQuestions();

    expect(questions, hasLength(5));
    expect(questions.first.question, 'Где хранятся мои данные?');
  });

  test('finds a question by the words of its answer', () {
    const question = HelpQuestion(
      'Откуда берётся курс валют?',
      'Это курс Банка России на день операции.',
    );

    expect(question.matches(''), isTrue);
    expect(question.matches('банка'), isTrue);
    expect(question.matches('  КУРС   россии '), isTrue);
    expect(question.matches('берется'), isTrue);
    expect(question.matches('курс биржи'), isFalse);
  });
}
