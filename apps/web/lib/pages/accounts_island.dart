import 'dart:async';

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/accounts_jaspr.dart';
import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/dependencies.dart';
import 'package:birka_web/app/opened_database.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:get_it/get_it.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// Where the database stands.
enum _Stage { opening, ready, busy, failed }

/// The accounts in the browser: it opens the database and shows the list or
/// the form, by the fragment of the address (ADR 0008).
///
/// The address `accounts/#new` opens a new account and `accounts/#<id>` an
/// existing one, so the page stays in place and the database stays open.
@client
class AccountsIsland extends StatefulComponent {
  /// Creates the island.
  const AccountsIsland({super.key});

  @override
  State<AccountsIsland> createState() => _AccountsIslandState();

  /// The styles of the island.
  @css
  static List<StyleRule> get styles => [
    css('.accounts-placeholder').styles(
      raw: {
        'animation': 'accounts-placeholder 1.4s ease-in-out infinite',
        'background': 'var(--color-surface)',
        'border-radius': 'var(--radius-xl)',
        'height': '190px',
      },
    ),
    css.keyframes('accounts-placeholder', {
      '50%': const Styles(raw: {'opacity': '0.5'}),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.accounts-placeholder').styles(raw: {'animation': 'none'}),
    ]),
  ];
}

class _AccountsIslandState extends State<AccountsIsland> {
  static const _home = './';
  static const _list = 'accounts/';
  static const _newAccount = 'new';

  final GetIt _getIt = GetIt.instance;
  _Stage _stage = _Stage.opening;
  var _persists = true;
  var _fragment = '';
  var _cameFromList = false;
  void Function()? _stopWatching;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    LocaleSettings.setLocaleRawSync(browserLanguage);
    describePage(
      language: LocaleSettings.currentLocale.languageCode,
      title: '${t.accounts.title} · Birka',
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
      registerDependencies(_getIt, opened.executor);
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
    setState(() {
      _cameFromList = _fragment.isEmpty;
      _fragment = addressFragment;
    });
    scrollToTop();
  }

  /// Back to the list: one step back if the list is there, and otherwise the
  /// form leaves the history, so that the back button does not reopen it.
  void _close() {
    if (_cameFromList) {
      goBackInHistory();
      return;
    }
    clearAddressFragment();
    setState(() => _fragment = '');
    scrollToTop();
  }

  @override
  Component build(BuildContext context) {
    return switch (_stage) {
      _Stage.opening => const div(classes: 'accounts', [
        AccountsHeader(backHref: _home, addHref: '$_list#$_newAccount'),
        div(classes: 'accounts-placeholder', []),
      ]),
      _Stage.busy => _trouble(t.accounts.openElsewhere),
      _Stage.failed => _trouble(t.accounts.failed),
      _Stage.ready when _fragment.isEmpty => _accounts(),
      _Stage.ready => _form(),
    };
  }

  Component _accounts() {
    return BlocProvider<AccountsCubit>(
      create: (_) => _getIt(),
      child: AccountsPage(
        backHref: _home,
        addHref: '$_list#$_newAccount',
        hrefOf: (id) => '$_list#$id',
        note: _persists ? t.accounts.storedHere : t.accounts.notStored,
      ),
    );
  }

  Component _form() {
    final id = _fragment == _newAccount ? null : _fragment;
    return BlocProvider<AccountFormCubit>(
      key: ValueKey(_fragment),
      create: (_) => _getIt(param1: id),
      child: AccountFormPage(onClose: _close),
    );
  }

  Component _trouble(String message) {
    return div(classes: 'accounts', [
      const AccountsHeader(backHref: _home, addHref: '$_list#$_newAccount'),
      GlassSurface(
        child: div(classes: 'accounts__panel', [
          p(classes: 'accounts__panel-title', [.text(message)]),
          BirkaButton(label: t.accounts.retry, onPressed: _retry),
        ]),
      ),
    ]);
  }
}
