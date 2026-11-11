import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:birka_web/app/wide_window.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:help_common/help_common.dart';
import 'package:help_jaspr/help_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

/// Help and feedback (ADR 0018). It reads no data, so it opens no database,
/// and it works beside a tab that holds one.
@client
class HelpIsland extends StatefulComponent {
  /// Creates the island.
  const HelpIsland({super.key});

  @override
  State<HelpIsland> createState() => _HelpIslandState();
}

class _HelpIslandState extends State<HelpIsland> with WideWindow<HelpIsland> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    Settings.readFrom(
      const BrowserSettingsStore(),
    ).applyLanguage(device: browserLanguage);
    describePage(
      language: LocaleSettings.currentLocale.languageCode,
      title: '${t.help.title} · Birka',
    );
  }

  // The build knows no language, so its HTML has no words (ADR 0008).
  @override
  Component build(BuildContext context) {
    if (!kIsWeb) return const BirkaColumn(children: [BirkaPlaceholder()]);
    return div([
      BlocProvider<HelpCubit>(
        create: (_) =>
            HelpCubit(const BrowserHelpLinks(), Future.value(browserAbout)),
        child: HelpPage(wide: wide),
      ),
      const SiteNav(page: SitePage.more),
    ]);
  }
}
