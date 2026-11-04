import 'package:help_common/src/domain/app_about.dart';
import 'package:help_common/src/domain/help_letter.dart';
import 'package:help_common/src/presentation/help_cubit.dart';
import 'package:l10n/l10n.dart';

/// The name of the way to write a letter of [kind]: `Написать разработчику`.
String letterWayLabel(LetterKind kind) => switch (kind) {
  LetterKind.question => t.help.write,
  LetterKind.bug => t.help.bug,
  LetterKind.idea => t.help.idea,
};

/// The line under [letterWayLabel]: `Откроется ваша почта`.
String letterWayText(LetterKind kind) => switch (kind) {
  LetterKind.question => t.help.writeText,
  LetterKind.bug => t.help.bugText,
  LetterKind.idea => t.help.ideaText,
};

/// The title of the sheet that shows a letter of [kind]:
/// `Письмо разработчику`.
String letterTitle(LetterKind kind) => switch (kind) {
  LetterKind.question => t.help.letterTitle,
  LetterKind.bug => t.help.bug,
  LetterKind.idea => t.help.idea,
};

/// The text of [letter] as the screen shows it: its hyphens do not break, so
/// that a tag such as `ru-RU` stays on one line. The letter itself keeps its
/// plain hyphens.
String letterBodyLabel(HelpLetter letter) =>
    letter.body.replaceAll('-', '\u2011');

/// What the screen says about [notice].
String helpNoticeLabel(HelpNotice notice) => switch (notice) {
  MailMissing(:final address) => t.help.noMail(address: address),
  PageMissing() => t.help.noPage,
};

/// The last line of the screen: `Birka 0.1.0 · Android 14 · русский`.
String aboutLine(AppAbout about) => t.help.about(
  version: about.version,
  system: about.system,
  language: t.help.language,
);
