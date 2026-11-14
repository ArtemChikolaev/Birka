import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:debts_common/debts_common.dart';
import 'package:debts_jaspr/debts_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart' hide fragment;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The debts of this browser (ADR 0029): the list, the card of a debt at
/// `debts/#<id>` with its return and the text of a reminder to copy in
/// folds (ADR 0030), more money on it at
/// `debts/#more-<id>`, its terms at `debts/#edit-<id>` and a new debt at
/// `debts/#new`. In a wide window they open beside the list, which otherwise
/// says how the debts work. A save says what it wrote.
@client
class DebtsIsland extends StatefulComponent {
  /// Creates the island.
  const DebtsIsland({super.key});

  @override
  State<DebtsIsland> createState() => _DebtsIslandState();
}

class _DebtsIslandState extends DataIslandState<DebtsIsland> {
  static const _address = 'debts/';
  static const _new = 'new';
  static const _more = 'more-';
  static const _edit = 'edit-';

  /// What the last save said.
  String? _toast;

  @override
  SitePage get page => SitePage.more;

  @override
  String get pageName => t.debts.title;

  @override
  String get failure => t.debts.failed;

  @override
  Component get header => GlassPageHeader(title: t.debts.title);

  @override
  bool get viewsBeside => true;

  // The list stays with the page, so that a card or a form beside it does not
  // read it again.
  @override
  Component buildPage(BuildContext context) {
    final toast = _toast;
    return BlocProvider<DebtsCubit>(
      create: (_) => getIt(),
      child: div([
        if (wide) _besideList() else _inTurn(),
        if (toast != null)
          GlassToast(
            key: ValueKey(toast),
            toast,
            onGone: () => setState(() => _toast = null),
          ),
      ]),
    );
  }

  /// A narrow window: the list, or a view in its place.
  Component _inTurn() {
    return switch (fragment) {
      '' => _list(),
      final view => _view(view, closes: false),
    };
  }

  /// A wide window: the list, and beside it how the debts work, or the card
  /// of the debt picked in the list, or a form.
  Component _besideList() {
    return switch (fragment) {
      '' => _list(
        side: GlassSteps(
          title: t.debts.howItWorks,
          points: [
            t.debts.steps.first,
            t.debts.steps.second,
            t.debts.steps.third,
          ],
        ),
      ),
      final view => _list(
        picked: _debtOf(view),
        side: GlassPanel(
          key: ValueKey(view),
          child: _view(view, closes: true),
        ),
      ),
    };
  }

  /// The debt that [view] is about, or `null` for a new one.
  static String? _debtOf(String view) => switch (view) {
    _new => null,
    _ when view.startsWith(_more) => view.substring(_more.length),
    _ when view.startsWith(_edit) => view.substring(_edit.length),
    _ => view,
  };

  Component _list({String? picked, Component? side}) {
    return DebtsPage(
      addHref: '$_address#$_new',
      hrefOf: (id) => '$_address#$id',
      picked: picked,
      side: side,
    );
  }

  /// The form of a new debt, `new`, of more money on one, `more-<id>`, of
  /// its terms, `edit-<id>`, or its card, `<id>`. Beside the list a card
  /// [closes] with a cross.
  Component _view(String view, {required bool closes}) {
    if (view == _new) return _form(null);
    if (view.startsWith(_more)) return _form(view.substring(_more.length));
    if (view.startsWith(_edit)) return _terms(view.substring(_edit.length));
    // The card reads the debts of the list above it.
    return DebtPage(
      key: ValueKey(view),
      id: view,
      onBack: closeForm,
      editHref: '$_address#$_edit$view',
      moreHref: '$_address#$_more$view',
      hrefOfOperation: (id) => 'operations/#$id',
      closes: closes,
      onCopy: (text) async {
        final copied = await copyText(text);
        setState(
          () => _toast = copied
              ? t.debts.remind.copied
              : t.debts.remind.notCopied,
        );
      },
      returnForm: (close) => BlocProvider<DebtReturnCubit>(
        create: (_) => getIt(param1: view),
        child: DebtReturnForm(
          onDone: (returned) {
            close();
            setState(() => _toast = debtReturnedToast(returned));
          },
        ),
      ),
    );
  }

  /// The form of a new debt, or of more money on debt [id], which goes back
  /// to the card of the debt it wrote and says what it wrote.
  Component _form(String? id) {
    return BlocProvider<DebtFormCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: id),
      child: DebtFormPage(
        onClose: () => closeForm(id ?? ''),
        onDone: (saved) {
          setState(() => _toast = debtSavedToast(saved));
          closeForm(saved.debtId);
        },
      ),
    );
  }

  /// The terms of debt [id], which go back to its card.
  Component _terms(String id) {
    return BlocProvider<DebtTermsCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: id),
      child: DebtTermsPage(
        onClose: () => closeForm(id),
        onDone: () => closeForm(id),
      ),
    );
  }
}
