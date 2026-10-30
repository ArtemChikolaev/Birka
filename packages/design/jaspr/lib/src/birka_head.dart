import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// What every page needs in its `<head>`: the design tokens and the fonts.
///
/// The paths are relative, so they work under the `<base>` of the site,
/// which is `/Birka/` on GitHub Pages.
const List<Component> birkaHead = [
  link(rel: 'stylesheet', href: 'packages/design_tokens/css/tokens.css'),
  link(rel: 'stylesheet', href: 'packages/design_jaspr/fonts/fonts.css'),
];

/// The base styles of a page: the dark scheme and the colors of the tokens.
@css
List<StyleRule> get birkaBaseStyles => [
  css('html').styles(raw: {'color-scheme': 'dark'}),
  css('body').styles(
    raw: {
      'margin': '0',
      'background': 'var(--color-background)',
      'color': 'var(--color-text)',
      '-webkit-font-smoothing': 'antialiased',
    },
  ),
];
