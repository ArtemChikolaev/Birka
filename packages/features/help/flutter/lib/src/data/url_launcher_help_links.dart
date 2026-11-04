import 'package:flutter/services.dart';
import 'package:help_common/help_common.dart';
import 'package:url_launcher/url_launcher.dart';

/// The ways out on phones: the mail app and the browser of the system, and
/// its clipboard.
final class UrlLauncherHelpLinks implements HelpLinks {
  /// Creates the ways out.
  const UrlLauncherHelpLinks();

  @override
  Future<bool> mail(Uri letter) => _launch(letter);

  @override
  Future<bool> open(Uri page) => _launch(page);

  @override
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Hands [uri] to the app of the system that takes it. A system without
  /// one says no or fails, and both mean that nothing opened.
  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
