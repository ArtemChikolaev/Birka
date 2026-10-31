import 'package:jaspr/jaspr.dart';

/// Hides the digits of every amount below it, such as in a public place.
///
/// The host holds whether they are hidden, because a site loses what is in
/// memory on the way to its next page.
class HiddenAmounts extends InheritedComponent {
  /// Creates the scope around [child].
  const HiddenAmounts({
    required this.hidden,
    required this.onToggle,
    required super.child,
    super.key,
  });

  /// Whether the digits are hidden.
  final bool hidden;

  /// Called to hide the amounts or to show them again.
  final VoidCallback onToggle;

  /// A number with its groups, and the letter of a compact one: `1 250,50`, or
  /// `78k`, whose letter would tell its size.
  static final _digits = RegExp(r'\d(?:[\d\s.,]*\d)?[kMB]?');

  /// Whether the amounts around [context] are hidden.
  static bool of(BuildContext context) =>
      context.dependOnInheritedComponentOfExactType<HiddenAmounts>()?.hidden ??
      false;

  /// Shows the amounts around [context] if they are hidden, or hides them.
  static void toggle(BuildContext context) {
    final scope = context
        .getElementForInheritedComponentOfExactType<HiddenAmounts>()
        ?.component;
    if (scope is HiddenAmounts) scope.onToggle();
  }

  /// [text] with its digits hidden if the amounts around [context] are. The
  /// sign and the currency stay, and the length of the number goes.
  static String mask(BuildContext context, String text) =>
      of(context) ? text.replaceAll(_digits, '•••') : text;

  @override
  bool updateShouldNotify(HiddenAmounts oldComponent) =>
      hidden != oldComponent.hidden;
}
