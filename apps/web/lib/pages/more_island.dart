import 'dart:async';

import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/app/opened_database.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:birka_web/pages/more_page.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:get_it/get_it.dart';
import 'package:inbox_common/inbox_common.dart'
    show InboxState, InboxSummaryCubit;
import 'package:inbox_jaspr/inbox_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

/// The way to everything that has no tab of its own, and the settings. The
/// page needs no data, so it shows at once; it opens the database only to
/// count what waits in the inbox, and beside a tab that holds the database
/// the way to the inbox goes without a count (ADR 0022, point 9).
@client
class MoreIsland extends StatefulComponent {
  /// Creates the island.
  const MoreIsland({super.key});

  @override
  State<MoreIsland> createState() => _MoreIslandState();
}

class _MoreIslandState extends State<MoreIsland> {
  StreamSubscription<AppLocale>? _languages;

  /// What waits in the inbox, once the database is open.
  InboxSummaryCubit? _inbox;

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
    unawaited(_countInbox());
  }

  Future<void> _countInbox() async {
    final getIt = GetIt.instance;
    try {
      await openData(getIt);
    } on OpenInAnotherTab {
      return;
    } on Object catch (error, stack) {
      logError(error, stack);
      return;
    }
    if (!mounted) return;
    setState(() => _inbox = getIt());
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
    unawaited(_inbox?.close());
    super.dispose();
  }

  // The build knows no language, so its HTML has no words (ADR 0008). `t` is
  // not reactive (ADR 0010), so a new language takes new components.
  @override
  Component build(BuildContext context) {
    if (!kIsWeb) return const BirkaColumn(children: [BirkaPlaceholder()]);
    final inbox = _inbox;
    return BlocProvider<SettingsCubit>(
      // The other pages read the choice when they load.
      create: (_) => SettingsCubit(
        const BrowserSettingsStore(),
        deviceLanguage: browserLanguage,
        baseCurrency: BaseCurrency(null),
      ),
      child: div(key: ValueKey(LocaleSettings.currentLocale), [
        MorePage(
          inbox: inbox == null
              ? const InboxTile(href: 'inbox/')
              : BlocBuilder<InboxSummaryCubit, InboxState>(
                  bloc: inbox,
                  builder: (context, state) =>
                      InboxTile(href: 'inbox/', state: state),
                ),
        ),
        const SiteNav(page: SitePage.more),
      ]),
    );
  }
}
