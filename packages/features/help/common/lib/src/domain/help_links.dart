/// The ways out of the app that help takes: the mail app of the person, a
/// page in the browser and the clipboard. Each host has its own.
abstract interface class HelpLinks {
  /// Opens [letter], a `mailto:` address, in the mail app and says whether
  /// one opened.
  Future<bool> mail(Uri letter);

  /// Opens [page] in the browser and says whether it opened.
  Future<bool> open(Uri page);

  /// Puts [text] on the clipboard.
  Future<void> copy(String text);
}
