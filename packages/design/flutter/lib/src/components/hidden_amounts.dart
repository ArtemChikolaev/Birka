import 'package:flutter/widgets.dart';

/// Hides the digits of every amount below it, such as in a public place.
///
/// [notifier] holds whether they are hidden.
class HiddenAmounts extends InheritedNotifier<ValueNotifier<bool>> {
  /// Creates the scope around [child].
  const HiddenAmounts({
    required ValueNotifier<bool> super.notifier,
    required super.child,
    super.key,
  });

  /// A number with its groups, and the letter of a compact one: `1 250,50`, or
  /// `78k`, whose letter would tell its size.
  static final _digits = RegExp(r'\d(?:[\d\s.,]*\d)?[kMB]?');

  /// Whether the amounts around [context] are hidden.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HiddenAmounts>()
          ?.notifier
          ?.value ??
      false;

  /// Shows the amounts around [context] if they are hidden, or hides them.
  static void toggle(BuildContext context) {
    final hidden = context
        .getInheritedWidgetOfExactType<HiddenAmounts>()
        ?.notifier;
    if (hidden != null) hidden.value = !hidden.value;
  }

  /// [text] with its digits hidden if the amounts around [context] are. The
  /// sign and the currency stay, and the length of the number goes.
  static String mask(BuildContext context, String text) =>
      of(context) ? text.replaceAll(_digits, '•••') : text;
}
