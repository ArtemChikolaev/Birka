import 'package:help_common/help_common.dart';

/// What the tests say about the app.
const sampleAbout = AppAbout(
  version: '0.1.0',
  build: '42',
  system: 'Android 14',
  locale: 'ru-RU',
);

/// Ways out that remember where they led, and open only what they are told.
final class FakeHelpLinks implements HelpLinks {
  /// Whether a mail app opens.
  bool mailOpens = true;

  /// The letters handed to the mail app.
  final letters = <Uri>[];

  /// The pages handed to the browser.
  final pages = <Uri>[];

  /// What went to the clipboard.
  final copied = <String>[];

  @override
  Future<bool> mail(Uri letter) async {
    letters.add(letter);
    return mailOpens;
  }

  @override
  Future<bool> open(Uri page) async {
    pages.add(page);
    return true;
  }

  @override
  Future<void> copy(String text) async => copied.add(text);
}
