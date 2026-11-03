import 'package:help_common/help_common.dart';
import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('keeps spaces as spaces and ends lines with CRLF', () {
    const letter = HelpLetter(
      kind: LetterKind.question,
      address: 'help@example.org',
      subject: 'Birka · вопрос',
      body: 'Здравствуйте!\nКак дела?',
    );

    final uri = letter.uri.toString();

    expect(uri, startsWith('mailto:help@example.org?subject='));
    expect(uri, isNot(contains('+')));
    expect(uri, contains('%0D%0A'));
    expect(letter.uri.queryParameters, {
      'subject': 'Birka · вопрос',
      'body': 'Здравствуйте!\r\nКак дела?',
    });
  });

  test('gives each letter its own subject and lines to fill in', () {
    final question = HelpLetter.of(LetterKind.question, sampleAbout);
    final idea = HelpLetter.of(LetterKind.idea, sampleAbout);

    expect(question.subject, 'Birka · вопрос');
    expect(question.body, startsWith('Здравствуйте!\n\n\n—'));
    expect(idea.subject, 'Birka · идея');
    expect(idea.body, startsWith('Чего не хватает:\n\nКак это помогло бы:'));
  });

  test('names the way to write each letter', () {
    expect(letterWayLabel(LetterKind.question), 'Написать разработчику');
    expect(letterTitle(LetterKind.question), 'Письмо разработчику');
    expect(letterTitle(LetterKind.bug), 'Сообщить об ошибке');
    expect(
      letterWayText(LetterKind.idea),
      'Расскажите, чего не хватает в Birka',
    );
  });
}
