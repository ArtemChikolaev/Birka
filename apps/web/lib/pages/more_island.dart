import 'package:birka_web/app/browser.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:birka_web/pages/more_page.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// The way to everything that has no tab of its own. It reads no data, so it
/// opens no database, and it works beside a tab that holds one.
@client
class MoreIsland extends StatefulComponent {
  /// Creates the island.
  const MoreIsland({super.key});

  @override
  State<MoreIsland> createState() => _MoreIslandState();
}

class _MoreIslandState extends State<MoreIsland> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    LocaleSettings.setLocaleRawSync(browserLanguage);
    describePage(
      language: LocaleSettings.currentLocale.languageCode,
      title: '${t.app.more} · Birka',
    );
  }

  // The build knows no language, so its HTML has no words (ADR 0008).
  @override
  Component build(BuildContext context) {
    if (!kIsWeb) return const BirkaColumn(children: [BirkaPlaceholder()]);
    return const div([MorePage(), SiteNav(page: SitePage.more)]);
  }
}
