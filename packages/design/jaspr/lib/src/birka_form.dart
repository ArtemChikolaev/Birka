import 'package:design_jaspr/src/birka_button.dart';
import 'package:design_jaspr/src/birka_icon.dart';
import 'package:design_jaspr/src/birka_split.dart';
import 'package:design_jaspr/src/glass_icon_button.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A form that stays on its page: a heading with a cross, the [children] and
/// a button that saves. That button or the Enter key in a field calls
/// [onSubmit]. With an [aside], a wide page shows it beside the fields, with
/// the button under it, in a `BirkaSplit`.
class BirkaForm extends StatelessComponent {
  /// Creates a form.
  const BirkaForm({
    required this.title,
    required this.closeLabel,
    required this.onClose,
    required this.submitLabel,
    required this.onSubmit,
    required this.children,
    this.leading,
    this.ready = true,
    this.submitting = false,
    this.failure,
    this.aside,
    this.asideWidth = 340,
    this.note,
    super.key,
  });

  /// The heading.
  final String title;

  /// What the cross does, for screen readers.
  final String closeLabel;

  /// Called by the cross.
  final VoidCallback onClose;

  /// The label of the button that saves.
  final String submitLabel;

  /// Called on a submit.
  final VoidCallback onSubmit;

  /// The fields.
  final List<Component> children;

  /// What stands before the heading.
  final Component? leading;

  /// Whether every field that a save needs is in place. Without them the
  /// button stays off.
  final bool ready;

  /// Whether a save is under way, which turns the button off.
  final bool submitting;

  /// Why the last save failed.
  final String? failure;

  /// What stands beside the fields on a wide page, over the button.
  final List<Component>? aside;

  /// How wide [aside] is, in pixels.
  final int asideWidth;

  /// What the button does, in a quiet line under it.
  final String? note;

  @override
  Component build(BuildContext context) {
    final failure = this.failure;
    final actions = div(classes: 'birka-form__actions', [
      if (failure != null)
        p(classes: 'text-caption birka-form__failure', [.text(failure)]),
      BirkaButton(label: submitLabel, submits: ready && !submitting),
      if (note case final note?)
        p(classes: 'text-caption birka-form__note', [.text(note)]),
    ]);
    return form(
      classes: 'birka-form',
      events: {
        'submit': (event) {
          event.preventDefault();
          onSubmit();
        },
      },
      [
        div(classes: 'birka-form__header', [
          ?leading,
          h1(classes: 'text-heading birka-form__title', [.text(title)]),
          GlassIconButton(
            glyph: BirkaGlyph.close,
            label: closeLabel,
            onPressed: onClose,
          ),
        ]),
        ...switch (aside) {
          final aside? => [
            BirkaSplit(
              asideWidth: asideWidth,
              main: children,
              aside: [...aside, actions],
            ),
          ],
          null => [...children, actions],
        },
      ],
    );
  }

  /// The styles of the form.
  @css
  static List<StyleRule> get styles => [
    css('.birka-form').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.birka-form__header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.birka-form__title').styles(raw: {'flex': '1', 'margin': '0'}),
    css('.birka-form__actions').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.birka-form__note').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
    css('.birka-form__failure').styles(
      raw: {
        'color': 'var(--color-negative)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
  ];
}
