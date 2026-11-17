import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_jaspr/limits_jaspr.dart';

/// The monthly limits of this browser (ADR 0033): the page of the limits,
/// the form of a limit at `#new` and `#<category>`, and the limits from
/// averages at `#suggest`. The card of the spending on the overview leads
/// here, and the page has a way back of its own, so it stands without the
/// tabs of the site. A form or the averages go back to the page that opened
/// them, and that page says what they did.
@client
class LimitsIsland extends StatefulComponent {
  /// Creates the island.
  const LimitsIsland({super.key});

  @override
  State<LimitsIsland> createState() => _LimitsIslandState();
}

class _LimitsIslandState extends DataIslandState<LimitsIsland> {
  static const _address = 'limits/';
  static const _new = 'new';
  static const _suggest = 'suggest';

  LimitsCubit? _limits;

  /// What the page says once a form or the averages are done.
  String? _said;

  @override
  SitePage get page => SitePage.overview;

  @override
  String get pageName => t.limits.title;

  @override
  String get failure => t.limits.form.failed;

  @override
  Component get header => GlassPageHeader(title: t.limits.title);

  @override
  bool get standsAlone => true;

  @override
  void onTabShown() => _limits?.refresh();

  @override
  Component buildPage(BuildContext context) {
    return switch (fragment) {
      '' => _page(),
      _new => _form(null),
      _suggest => BlocProvider<LimitSuggestCubit>(
        key: const ValueKey(_suggest),
        create: (_) => getIt(),
        child: LimitSuggestPage(
          manualHref: '$_address#$_new',
          onClose: _close,
          onDone: _done,
        ),
      ),
      final id => _form(id),
    };
  }

  /// The page, which says what a form did once: back from another page by
  /// the browser, it says nothing.
  Component _page() {
    final said = _said;
    _said = null;
    return BlocProvider<LimitsCubit>(
      create: (_) => _limits = getIt(),
      child: LimitsPage(
        said: said,
        backHref: 'overview/',
        addHref: '$_address#$_new',
        suggestHref: '$_address#$_suggest',
        hrefOf: (id) => '$_address#$id',
      ),
    );
  }

  Component _form(String? categoryId) {
    return BlocProvider<LimitFormCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: categoryId),
      child: LimitFormPage(onClose: _close, onDone: _done),
    );
  }

  void _close() {
    _said = null;
    closeView();
  }

  void _done(String said) {
    _said = said;
    if (closeView()) sayOnNextPage(said);
  }
}
