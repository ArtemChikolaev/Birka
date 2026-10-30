import 'package:birka_web/pages/accounts_route.dart';
import 'package:birka_web/pages/home_route.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// The pages of the site. The router runs only when the build renders them to
/// HTML, so it never meets the `/Birka/` of the real address (ADR 0008).
class App extends StatelessComponent {
  /// Creates the site.
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(path: '/', builder: (_, _) => const HomeRoute()),
        Route(
          path: '/accounts',
          title: 'Accounts · Birka',
          builder: (_, _) => const AccountsRoute(),
        ),
      ],
    );
  }
}
