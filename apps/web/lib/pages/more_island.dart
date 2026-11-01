import 'dart:async';

import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:birka_web/pages/more_page.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

/// The way to everything that has no tab of its own, and the settings. It reads
/// no data, so it opens no database, and it works beside a tab that holds one.
@client
class MoreIsland extends StatefulComponent {
  /// Creates the island.
  const MoreIsland({super.key});

  @override
  State<MoreIsland> createState() => _MoreIslandState();
}

class _MoreIslandState extends State<MoreIsland> {
  StreamSubscription<AppLocale>? _languages;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    Settings.readFrom(
      const BrowserSettingsStore(),
    ).applyLanguage(device: browserLanguage);
    _describePage();
    _languages = LocaleSettings.getLocaleStream().listen((_) {
      _describePage();
      setState(() {});
    });
  }

  void _describePage() {
    describePage(
      language: LocaleSettings.currentLocale.languageCode,
      title: '${t.app.more} · Birka',
    );
  }

  @override
  void dispose() {
    unawaited(_languages?.cancel());
    super.dispose();
  }

  // The build knows no language, so its HTML has no words (ADR 0008). `t` is
  // not reactive (ADR 0010), so a new language takes new components.
  @override
  Component build(BuildContext context) {
    if (!kIsWeb) return const BirkaColumn(children: [BirkaPlaceholder()]);
    return BlocProvider<SettingsCubit>(
      create: (_) => SettingsCubit(
        const BrowserSettingsStore(),
        deviceLanguage: browserLanguage,
      ),
      child: div(key: ValueKey(LocaleSettings.currentLocale), const [
        MorePage(),
        SiteNav(page: SitePage.more),
      ]),
    );
  }
}
