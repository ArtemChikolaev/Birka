import 'dart:async';

import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart' show InboxSummaryCubit;
import 'package:inbox_jaspr/inbox_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:onboarding_common/onboarding_common.dart';
import 'package:onboarding_jaspr/onboarding_jaspr.dart';
import 'package:overview_common/overview_common.dart';
import 'package:overview_jaspr/overview_jaspr.dart';
import 'package:settings_common/settings_common.dart' show Settings;

/// The first screen with data: the capital, the accounts and what the month
/// has cost. A new browser goes through the onboarding here first.
@client
class OverviewIsland extends StatefulComponent {
  /// Creates the island.
  const OverviewIsland({super.key});

  @override
  State<OverviewIsland> createState() => _OverviewIslandState();
}

class _OverviewIslandState extends DataIslandState<OverviewIsland> {
  OverviewCubit? _overview;

  /// Whether the steps of a new browser stand in place of the overview. A
  /// browser with no mark starts here, so that it never sees the overview
  /// flash by, and the database settles it (ADR 0013).
  var _welcoming = false;
  StreamSubscription<AppLocale>? _languages;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _welcoming = !Settings.readFrom(const BrowserSettingsStore()).onboarded;
    _languages = LocaleSettings.getLocaleStream().listen(_onLanguageChanged);
  }

  @override
  void dispose() {
    unawaited(_languages?.cancel());
    super.dispose();
  }

  void _onLanguageChanged(AppLocale language) {
    describePage(
      language: language.languageCode,
      title: '$pageName · Birka',
    );
    setState(() {});
  }

  void _onFinished() {
    setState(() => _welcoming = false);
    context.binding.addPostFrameCallback(() => scrollPageTo(0));
  }

  @override
  SitePage get page => SitePage.overview;

  @override
  String get pageName => t.app.overview;

  @override
  String get failure => t.overview.failed;

  @override
  Component get header =>
      _welcoming ? const div([]) : GlassPageHeader(title: t.app.overview);

  @override
  bool get standsAlone => _welcoming;

  @override
  Future<void> prepare() async {
    _welcoming = await onboardingNeeded(const BrowserSettingsStore(), getIt());
  }

  @override
  void onTabShown() => unawaited(_overview?.calendarChecked());

  @override
  Component buildPage(BuildContext context) {
    if (_welcoming) {
      return BlocProvider<OnboardingCubit>(
        create: (_) => getIt(),
        // `t` is not reactive (ADR 0010), so a new language takes new
        // components, and the steps stay in the cubit above them.
        child: div(key: ValueKey(LocaleSettings.currentLocale), [
          OnboardingPage(onFinished: _onFinished),
        ]),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider<OverviewCubit>(create: (_) => _overview = getIt()),
        BlocProvider<InboxSummaryCubit>(create: (_) => getIt()),
      ],
      child: OverviewPage(
        addAccountHref: 'accounts/#new',
        accountsHref: 'accounts/',
        hrefOfAccount: (id) => 'accounts/#$id',
        note: storageNote,
        notice: const InboxCard(href: 'inbox/'),
      ),
    );
  }
}
