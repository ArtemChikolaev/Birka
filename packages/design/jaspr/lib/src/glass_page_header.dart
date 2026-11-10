import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The heading of a page, with what stands beside it, such as the button that
/// adds, and before it, such as the way back. A [subtitle] under the heading
/// says what the page holds.
class GlassPageHeader extends StatelessComponent {
  /// Creates a header.
  const GlassPageHeader({
    required this.title,
    this.trailing,
    this.leading,
    this.subtitle,
    super.key,
  });

  /// The heading.
  final String title;

  /// What stands at the other end of the line.
  final Component? trailing;

  /// What stands before the heading, such as the way back.
  final Component? leading;

  /// The quieter line under the heading.
  final String? subtitle;

  @override
  Component build(BuildContext context) {
    final subtitle = this.subtitle;
    final heading = h1(classes: 'text-title glass-page-header__title', [
      .text(title),
    ]);
    if (leading == null && subtitle == null) {
      return div(classes: 'glass-page-header', [heading, ?trailing]);
    }
    return div(classes: 'glass-page-header glass-page-header--full', [
      ?leading,
      div(classes: 'glass-page-header__heading', [
        heading,
        if (subtitle != null)
          p(classes: 'text-caption glass-page-header__subtitle', [
            .text(subtitle),
          ]),
      ]),
      ?trailing,
    ]);
  }

  /// The styles of the header.
  @css
  static List<StyleRule> get styles => [
    css('.glass-page-header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'justify-content': 'space-between',
        'min-height': 'var(--size-touch-target)',
      },
    ),
    css('.glass-page-header__title').styles(
      raw: {'margin': '0', 'min-width': '0'},
    ),
    css('.glass-page-header--full').styles(raw: {'gap': 'var(--space-md)'}),
    css('.glass-page-header__heading').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': '2px',
        'min-width': '0',
      },
    ),
    css('.glass-page-header__subtitle').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
  ];
}
