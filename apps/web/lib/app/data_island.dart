import 'dart:async';

import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/dependencies.dart';
import 'package:birka_web/app/fragment_trail.dart';
import 'package:birka_web/app/opened_database.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:get_it/get_it.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

enum _Stage { opening, ready, busy, failed }

/// An island with data: it takes the language of the browser, opens the
/// database and follows the fragment of the address (ADR 0008).
///
/// The fragment keeps the page in place and the database open while a form
/// comes and goes.
abstract class DataIslandState<T extends StatefulComponent> extends State<T> {
  /// The objects of the app, once the database is open.
  final GetIt getIt = GetIt.instance;

  _Stage _stage = _Stage.opening;
  var _persists = true;
  var _fragment = '';
  final _trail = FragmentTrail();

  /// How far down the list was when a form took its place.
  var _listScroll = 0.0;

  void Function()? _stopWatching;

  /// The part of the address after `#`.
  String get fragment => _fragment;

  /// Says where the data lives.
  String get storageNote => _persists ? t.app.storedHere : t.app.notStored;

  /// The name of the page, for the tab of the browser.
  String get pageName;

  /// What stands at the top of the page while the data is on its way.
  Component get header;

  /// What to say when the database does not open.
  String get failure;

  /// The page itself, once the database is open.
  Component buildPage(BuildContext context);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    LocaleSettings.setLocaleRawSync(browserLanguage);
    describePage(
      language: LocaleSettings.currentLocale.languageCode,
      title: '$pageName · Birka',
    );
    _fragment = addressFragment;
    _stopWatching = watchAddressFragment(_onFragmentChanged);
    unawaited(_open());
  }

  @override
  void dispose() {
    _stopWatching?.call();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      final opened = await openLocalDatabase();
      registerDependencies(getIt, opened.executor);
      setState(() {
        _persists = opened.persists;
        _stage = _Stage.ready;
      });
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
    if (_fragment.isEmpty) _listScroll = pageScroll;
    final next = addressFragment;
    _trail.moved(from: _fragment, to: next);
    setState(() => _fragment = next);
    _placePage();
  }

  /// A new view must not start half way down, and the list comes back to
  /// where it was left.
  void _placePage() {
    final top = _fragment.isEmpty ? _listScroll : 0.0;
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
    _placePage();
  }

  @override
  Component build(BuildContext context) {
    return switch (_stage) {
      _Stage.opening => BirkaColumn(
        children: [header, const BirkaPlaceholder()],
      ),
      _Stage.ready => buildPage(context),
      _Stage.busy => _trouble(t.app.openElsewhere),
      _Stage.failed => _trouble(failure),
    };
  }

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
