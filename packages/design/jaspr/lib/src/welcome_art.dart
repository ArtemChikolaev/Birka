import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The art of the first screen: glass coins in three currencies on an orbit.
///
/// It says nothing that the words next to it do not, so screen readers skip
/// it.
class WelcomeArt extends StatelessComponent {
  /// Creates the art.
  const WelcomeArt({super.key});

  @override
  Component build(BuildContext context) {
    return const img(
      classes: 'welcome-art',
      src: 'packages/design_jaspr/images/welcome.webp',
      alt: '',
      width: 390,
      height: 300,
    );
  }

  /// The styles of the art. A short screen still shows what comes after it.
  @css
  static List<StyleRule> get styles => [
    css('.welcome-art').styles(
      raw: {
        'aspect-ratio': '1.3',
        'display': 'block',
        'height': 'auto',
        'margin': '0 auto',
        'max-height': '34vh',
        'max-width': '100%',
        'object-fit': 'contain',
      },
    ),
  ];
}
