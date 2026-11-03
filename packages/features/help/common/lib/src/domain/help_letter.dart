import 'package:help_common/src/domain/app_about.dart';
import 'package:help_common/src/domain/contacts.dart';
import 'package:l10n/l10n.dart';
import 'package:meta/meta.dart';

/// What a letter to the developer is about.
enum LetterKind {
  /// Anything at all.
  question,

  /// Something that went wrong.
  bug,

  /// Something that Birka lacks.
  idea,
}

/// A letter to the developer before the mail app opens it. It holds only
/// what the person sees in it: a few lines to fill in and what the app says
/// about itself, never a record of the ledger (ADR 0018).
@immutable
final class HelpLetter {
  /// Creates a letter.
  const HelpLetter({
    required this.kind,
    required this.address,
    required this.subject,
    required this.body,
  });

  /// The letter of [kind] in the language of the app, signed with [about].
  factory HelpLetter.of(LetterKind kind, AppAbout about) {
    final (subject, body) = switch (kind) {
      LetterKind.question => (t.help.questionSubject, t.help.questionBody),
      LetterKind.bug => (
        t.help.bugSubject(version: about.version),
        t.help.bugBody,
      ),
      LetterKind.idea => (t.help.ideaSubject, t.help.ideaBody),
    };
    return HelpLetter(
      kind: kind,
      address: supportAddress,
      subject: subject,
      body: '$body\n\n${about.signature}',
    );
  }

  /// What the letter is about.
  final LetterKind kind;

  /// Where it goes.
  final String address;

  /// Its subject.
  final String subject;

  /// Its text.
  final String body;

  /// The letter as a `mailto:` address (RFC 6068). Every character but the
  /// plain ones is encoded, so that a space stays a space rather than a `+`,
  /// and lines end with CRLF.
  Uri get uri {
    final subject = Uri.encodeComponent(this.subject);
    final body = Uri.encodeComponent(this.body.replaceAll('\n', '\r\n'));
    return Uri.parse('mailto:$address?subject=$subject&body=$body');
  }
}
