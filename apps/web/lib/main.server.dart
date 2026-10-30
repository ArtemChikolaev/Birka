import 'package:birka_web/app.dart';
import 'package:birka_web/main.server.options.dart';
import 'package:birka_web/pages/home_route.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

/// The path the site lives under: `/` locally and `/Birka/` on GitHub Pages,
/// which `make build-web BASE=/Birka/` sets.
const _basePath = String.fromEnvironment('BASE_PATH', defaultValue: '/');

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);
  runApp(
    const Document(
      title: 'Birka',
      lang: 'en',
      // The analyzer sees the default; the build for Pages sets another path.
      // ignore: avoid_redundant_argument_values
      base: _basePath,
      // The glow of the backdrop goes under the bars of a phone.
      viewport: 'width=device-width, initial-scale=1, viewport-fit=cover',
      meta: {'description': HomeRoute.tagline},
      head: [
        ...birkaHead,
        link(rel: 'icon', type: 'image/png', href: 'favicon.png'),
        link(rel: 'apple-touch-icon', href: 'apple-touch-icon.png'),
      ],
      body: App(),
    ),
  );
}
