import 'dart:async';

import 'package:backup_common/backup_common.dart'
    show databaseNameIn, settleDemo;
import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:birka_web/app/dependencies.dart';
import 'package:birka_web/app/fragment_trail.dart';
import 'package:birka_web/app/opened_database.dart';
import 'package:birka_web/app/wide_window.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:get_it/get_it.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show LedgerRepository;
import 'package:notifications_common/notifications_common.dart'
    show NotificationsRepository;
import 'package:rates/rates.dart' show RatesUpdater;
import 'package:settings_common/settings_common.dart';

enum _Stage { opening, ready, busy, failed }

/// Opens the database of this browser, that of the ledger or of the demo,
/// and registers the objects of the app in [getIt] on it. The notices older
/// than the 90 days that a device keeps go (ADR 0026). It throws
/// [OpenInAnotherTab] while another tab holds the database.
Future<OpenedDatabase> openData(GetIt getIt) async {
  const settings = BrowserSettingsStore();
  final name = databaseNameIn(settings);
  final opened = await openLocalDatabase(name);
  registerDependencies(getIt, opened.executor);
  // A demo that has just come on fills before the page shows it. Another
  // tab can turn it on meanwhile, so only the database that opened says
  // whether this is the demo.
  await settleDemo(
    settings,
    getIt<LedgerRepository>(),
    opened: name,
    now: DateTime.now(),
  );
  await getIt<NotificationsRepository>().forgetOld();
  return opened;
}

/// An island with data: it takes the language of the browser, opens the
/// database and follows the fragment of the address (ADR 0008).
///
/// The fragment keeps the page in place and the database open while a form
/// comes and goes.
abstract class DataIslandState<T extends StatefulComponent> extends State<T>
    with WideWindow<T> {
  /// The objects of the app, once the database is open.
  final GetIt getIt = GetIt.instance;

  _Stage _stage = _Stage.opening;
  var _persists = true;
  var _fragment = '';
  final _trail = FragmentTrail();

  /// How far down each view was when another one took its place.
  final _scrolls = <String, double>{};

  var _amountsHidden = false;

  /// What the page before asked this one to say once it is ready.
  String? _said;
  void Function()? _stopWatching;
  void Function()? _stopWatchingTab;
  void Function()? _stopWatchingSlash;

  /// The part of the address after `#`.
  String get fragment => _fragment;

  /// Says where the data lives.
  String get storageNote => _persists ? t.app.storedHere : t.app.notStored;

  /// The tab of the page in the navigation of the site.
  SitePage get page;

  /// The name of the page, for the tab of the browser.
  String get pageName;

  /// What stands at the top of the page while the data is on its way.
  Component get header;

  /// What to say when the database does not open.
  String get failure;

  /// The page itself, once the database is open.
  Component buildPage(BuildContext context);

  /// What the page has to read before it shows, once the database is open.
  Future<void> prepare() async {}

  /// Whether the page stands without the tabs of the site.
  bool get standsAlone => false;

  /// Whether the views of the page stand beside its list in a wide window,
  /// as the card of an operation beside the operations. The tabs of the site
  /// stay then, and the list keeps its place as the views come and go.
  bool get viewsBeside => false;

  bool get _beside => viewsBeside && wide;

  /// Whether the tabs stay while the address has a fragment, as on a page
  /// whose fragment holds what it shows rather than a view.
  bool get fragmentKeepsTabs => false;

  /// Called by the key `/` outside a field: it opens «Спросить» from any
  /// page (ADR 0028).
  void onSlashKey() => openSitePage('ask/');

  /// Called when the tab of the browser comes back into view, which can be
  /// after a night in the background.
  void onTabShown() {}

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    final settings = Settings.readFrom(const BrowserSettingsStore())
      ..applyLanguage(device: browserLanguage);
    describePage(
      language: LocaleSettings.currentLocale.languageCode,
      title: '$pageName · Birka',
    );
    _fragment = addressFragment;
    _amountsHidden = amountsHidden ?? settings.hideAmountsOnLaunch;
    _said = takeSaid();
    _stopWatching = watchAddressFragment(_onFragmentChanged);
    _stopWatchingTab = watchTabShown(onTabShown);
    _stopWatchingSlash = watchSlashKey(onSlashKey);
    unawaited(_open());
  }

  @override
  void dispose() {
    _stopWatching?.call();
    _stopWatchingTab?.call();
    _stopWatchingSlash?.call();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      final opened = await openData(getIt);
      await prepare();
      setState(() {
        _persists = opened.persists;
        _stage = _Stage.ready;
      });
      // The page waits for no network (ADR 0012).
      unawaited(getIt<RatesUpdater>().refresh());
    } on OpenInAnotherTab {
      setState(() => _stage = _Stage.busy);
    } on Object catch (error, stack) {
      logError(error, stack);
      setState(() => _stage = _Stage.failed);
    }
  }

  void _retry() {
    setState(() => _stage = _Stage.opening);
    unawaited(_open());
  }

  void _onFragmentChanged() {
    _scrolls[_fragment] = pageScroll;
    final next = addressFragment;
    final back = _trail.leadsBackTo(next);
    _trail.moved(from: _fragment, to: next);
    setState(() => _fragment = next);
    // A view beside the list leaves the list where it was.
    if (!_beside) _placePage(top: back ? _scrolls[next] ?? 0 : 0);
  }

  /// A new view must not start half way down, and a step back comes back to
  /// where the view was left.
  void _placePage({double top = 0}) {
    context.binding.addPostFrameCallback(() => scrollPageTo(top));
  }

  /// Back to [parent], which is the list by default: one step back if it is
  /// there, and otherwise the form leaves the history, so that the back button
  /// does not reopen it.
  void closeForm([String parent = '']) {
    if (_trail.leadsBackTo(parent)) {
      goBackInHistory();
      return;
    }
    replaceAddressFragment(parent);
    setState(() => _fragment = parent);
    if (!_beside) _placePage();
  }

  /// Back from a view that other pages of the site link to: to [parent] if it
  /// is one step back, then to the page that led here, and otherwise to
  /// [parent]. It says whether it went back to the page that led here, which
  /// then says what the view asks it to with `sayOnNextPage`.
  bool closeView([String parent = '']) {
    if (!_trail.leadsBackTo(parent) && cameFromSite) {
      goBackInHistory();
      return true;
    }
    closeForm(parent);
    return false;
  }

  void _toggleAmounts() {
    setState(() => _amountsHidden = !_amountsHidden);
    keepAmountsHidden(hidden: _amountsHidden);
  }

  // The build knows no language, so its HTML has no words (ADR 0008).
  @override
  Component build(BuildContext context) {
    return HiddenAmounts(
      hidden: _amountsHidden,
      onToggle: _toggleAmounts,
      child: div([
        switch (_stage) {
          _Stage.opening => BirkaColumn(
            children: [if (kIsWeb) header, const BirkaPlaceholder()],
          ),
          _Stage.ready => buildPage(context),
          _Stage.busy => _trouble(t.app.openElsewhere),
          _Stage.failed => _trouble(failure),
        },
        if (kIsWeb &&
            (_fragment.isEmpty || _beside || fragmentKeepsTabs) &&
            !_alone)
          SiteNav(page: page),
        if (_said case final said? when _stage == _Stage.ready)
          GlassToast(said, onGone: () => setState(() => _said = null)),
      ]),
    );
  }

  /// Trouble needs the tabs, which are the way to the pages that work.
  bool get _alone =>
      standsAlone && (_stage == _Stage.opening || _stage == _Stage.ready);

  Component _trouble(String message) {
    return BirkaColumn(
      children: [
        header,
        GlassNotice(
          text: message,
          actions: [BirkaButton(label: t.app.retry, onPressed: _retry)],
        ),
      ],
    );
  }
}
