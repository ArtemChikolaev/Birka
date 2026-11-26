import 'dart:async';

import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/app/opened_database.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_common/identity_common.dart';
import 'package:identity_jaspr/identity_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:settings_common/settings_common.dart';

/// Optional account access, with locally available counts beneath the form.
@client
class IdentityIsland extends StatefulComponent {
  /// Creates the page island.
  const IdentityIsland({super.key});
  @override
  State<IdentityIsland> createState() => _IdentityIslandState();
}

class _IdentityIslandState extends State<IdentityIsland> {
  LedgerCounts? _counts;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    Settings.readFrom(
      const BrowserSettingsStore(),
    ).applyLanguage(device: browserLanguage);
    describePage(
      language: LocaleSettings.currentLocale.languageCode,
      title: '${t.identity.title} · Birka',
    );
    unawaited(_readCounts());
  }

  Future<void> _readCounts() async {
    final getIt = GetIt.instance;
    try {
      await openData(getIt);
      final counts = await getIt<LedgerRepository>().watchCounts().first;
      if (mounted) setState(() => _counts = counts);
    } on OpenInAnotherTab {
      // The account stays available alongside a tab holding the ledger.
      return;
    } on Object catch (error, stack) {
      logError(error, stack);
    }
  }

  @override
  Component build(BuildContext context) {
    if (!kIsWeb) return const BirkaColumn(children: [BirkaPlaceholder()]);
    final endpoint = accountEndpoint();
    return div([
      BlocProvider<IdentityCubit>(
        create: (_) => IdentityCubit(
          endpoint == null ? null : AccountApi(endpoint, accountClient()),
        ),
        child: IdentityPage(
          onBack: () => openSitePage('more/'),
          accounts: _counts?.accounts,
          operations: _counts?.transactions,
        ),
      ),
      const SiteNav(page: SitePage.more),
    ]);
  }
}
