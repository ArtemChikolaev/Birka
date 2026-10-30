import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A form that stays on its page: a submit button or the Enter key in a field
/// calls [onSubmit].
class BirkaForm extends StatelessComponent {
  /// Creates a form around [children].
  const BirkaForm({
    required this.onSubmit,
    required this.children,
    this.classes,
    super.key,
  });

  /// Called on a submit.
  final VoidCallback onSubmit;

  /// The fields and the buttons.
  final List<Component> children;

  /// The classes of the form.
  final String? classes;

  @override
  Component build(BuildContext context) {
    return form(
      classes: classes,
      events: {
        'submit': (event) {
          event.preventDefault();
          onSubmit();
        },
      },
      children,
    );
  }
}
