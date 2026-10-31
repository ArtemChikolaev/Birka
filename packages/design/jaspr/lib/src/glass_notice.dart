import 'package:design_jaspr/src/glass_surface.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A panel of glass with a message and the ways on from it, such as an empty
/// list or a failure.
class GlassNotice extends StatelessComponent {
  /// Creates a notice.
  const GlassNotice({
    required this.text,
    this.actions = const [],
    this.title,
    super.key,
  });

  /// The message.
  final String text;

  /// The heading over [text], which then gets quieter.
  final String? title;

  /// The buttons, if there is a way on.
  final List<Component> actions;

  @override
  Component build(BuildContext context) {
    final title = this.title;
    return GlassSurface(
      child: div(classes: 'glass-notice', [
        div(classes: 'glass-notice__text', [
          if (title != null)
            h2(classes: 'text-heading glass-notice__title', [.text(title)]),
          p(
            classes: title == null
                ? 'glass-notice__message'
                : 'glass-notice__message glass-notice__message--quiet',
            [.text(text)],
          ),
        ]),
        if (actions.isNotEmpty) div(classes: 'glass-notice__actions', actions),
      ]),
    );
  }

  /// The styles of the notice.
  @css
  static List<StyleRule> get styles => [
    css('.glass-notice').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
        'padding': 'var(--space-xxs)',
      },
    ),
    css('.glass-notice__text').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.glass-notice__title').styles(raw: {'margin': '0'}),
    css('.glass-notice__message').styles(raw: {'margin': '0'}),
    css('.glass-notice__message--quiet').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.glass-notice__actions').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
  ];
}
