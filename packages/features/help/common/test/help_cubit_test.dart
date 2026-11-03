import 'dart:async';

import 'package:help_common/help_common.dart';
import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late FakeHelpLinks links;
  late HelpCubit cubit;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    links = FakeHelpLinks();
    cubit = HelpCubit(links, Future.value(sampleAbout));
  });

  tearDown(() async {
    await cubit.close();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test('learns what the app says about itself', () async {
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.about, sampleAbout);
    expect(aboutLine(sampleAbout), 'Birka 0.1.0 · Android 14 · русский');
  });

  test('searches the questions', () {
    cubit.search('курс');

    expect(cubit.state.query, 'курс');
  });

  test('opens one question at a time and closes it again', () {
    cubit.toggle(2);
    expect(cubit.state.open, 2);

    cubit.toggle(4);
    expect(cubit.state.open, 4);

    cubit.toggle(4);
    expect(cubit.state.open, isNull);
  });

  test('writes a letter about a bug with the version in its subject', () async {
    await cubit.compose(LetterKind.bug);

    final letter = cubit.state.letter!;
    expect(letter.address, supportAddress);
    expect(letter.subject, 'Birka 0.1.0 · ошибка');
    expect(
      letter.body,
      'Что случилось:\n\nЧто ожидали:\n\n'
      '—\nBirka 0.1.0 (42) · Android 14 · ru-RU',
    );
  });

  test('waits for what the app says about itself before a letter', () async {
    final about = Completer<AppAbout>();
    final waiting = HelpCubit(links, about.future);

    final composed = waiting.compose(LetterKind.question);
    await Future<void>.delayed(Duration.zero);
    expect(waiting.state.letter, isNull);

    about.complete(sampleAbout);
    await composed;
    expect(waiting.state.letter?.body, endsWith('ru-RU'));
    await waiting.close();
  });

  test('hands the letter to the mail app and lets it go', () async {
    await cubit.compose(LetterKind.idea);
    final letter = cubit.state.letter!;

    await cubit.send();

    expect(links.letters, [letter.uri]);
    expect(cubit.state.letter, isNull);
    expect(cubit.state.notice, isNull);
  });

  test('copies the address when no mail app opens', () async {
    links.mailOpens = false;
    await cubit.compose(LetterKind.question);

    await cubit.send();

    expect(links.copied, [supportAddress]);
    final notice = cubit.state.notice! as MailMissing;
    expect(notice.address, supportAddress);
    expect(
      helpNoticeLabel(notice),
      'Почта не открылась. Адрес скопирован: $supportAddress',
    );
  });

  test('lets a letter go without sending it', () async {
    await cubit.compose(LetterKind.question);

    cubit.dismiss();

    expect(cubit.state.letter, isNull);
    expect(links.letters, isEmpty);
  });

  test('opens the public page of bugs and ideas', () async {
    await cubit.openIssues();

    expect(links.pages, [issuesPage]);
    expect(cubit.state.notice, isNull);
  });

  test('says so when the page does not open', () async {
    links.pageOpens = false;

    await cubit.openIssues();

    expect(cubit.state.notice, isA<PageMissing>());
  });
}
