import 'dart:async';

import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart' hide fragment;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart' show TagMarking;
import 'package:tags_common/tags_common.dart';
import 'package:tags_jaspr/tags_jaspr.dart';
import 'package:transactions_common/transactions_common.dart'
    show TagOperationsCubit;
import 'package:transactions_jaspr/transactions_jaspr.dart';

/// The метки of this browser (ADR 0027): the list, the report of a метка at
/// `tags/#<id>`, its form at `tags/#edit-<id>` and a new one at `tags/#new`.
/// In a wide window they open beside the list, which otherwise says how the
/// метки work. A save says what it did, and «Вернуть» takes back the days it
/// marked.
@client
class TagsIsland extends StatefulComponent {
  /// Creates the island.
  const TagsIsland({super.key});

  @override
  State<TagsIsland> createState() => _TagsIslandState();
}

class _TagsIslandState extends DataIslandState<TagsIsland> {
  static const _address = 'tags/';
  static const _new = 'new';
  static const _edit = 'edit-';

  TagsCubit? _tags;

  /// What the last save said, and the метка whose days it marked, which
  /// «Вернуть» takes back.
  ({String text, TagMarking? marked})? _toast;

  @override
  SitePage get page => SitePage.more;

  @override
  String get pageName => t.tags.title;

  @override
  String get failure => t.tags.failed;

  @override
  Component get header => GlassPageHeader(title: t.tags.title);

  @override
  bool get viewsBeside => true;

  // The list stays with the page, so that a report or a form beside it does
  // not read it again.
  @override
  Component buildPage(BuildContext context) {
    final toast = _toast;
    return BlocProvider<TagsCubit>(
      create: (_) => _tags = getIt(),
      child: div([
        if (wide) _besideList() else _inTurn(),
        if (toast != null)
          GlassToast(
            key: ValueKey(toast.text),
            toast.text,
            action: switch (toast.marked) {
              final marked? => (
                label: t.tags.undo,
                onPressed: () => unawaited(_undo(marked)),
              ),
              null => null,
            },
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

  /// A wide window: the list, and beside it how the метки work, or the
  /// report of the метка picked in the list, or a form.
  Component _besideList() {
    return switch (fragment) {
      '' => _list(
        side: GlassSteps(
          title: t.tags.howItWorks,
          points: [
            t.tags.steps.first,
            t.tags.steps.second,
            t.tags.steps.third,
          ],
        ),
      ),
      final view => _list(
        picked: switch (view) {
          _new => null,
          _ when view.startsWith(_edit) => view.substring(_edit.length),
          _ => view,
        },
        side: GlassPanel(
          key: ValueKey(view),
          child: _view(view, closes: true),
        ),
      ),
    };
  }

  Component _list({String? picked, Component? side}) {
    return TagsPage(
      addHref: '$_address#$_new',
      hrefOf: (id) => '$_address#$id',
      picked: picked,
      side: side,
    );
  }

  /// The form of a new метка, `new`, the form of one, `edit-<id>`, or its
  /// report, `<id>`. Beside the list a report [closes] with a cross.
  Component _view(String view, {required bool closes}) {
    if (view == _new) return _form(null);
    if (view.startsWith(_edit)) return _form(view.substring(_edit.length));
    return MultiBlocProvider(
      key: ValueKey(view),
      providers: [
        BlocProvider<TagReportCubit>(create: (_) => getIt(param1: view)),
        BlocProvider<TagOperationsCubit>(create: (_) => getIt(param1: view)),
      ],
      child: TagReportPage(
        onBack: closeForm,
        editHref: '$_address#$_edit$view',
        closes: closes,
        operations: TagOperations(
          hrefOf: (id) => 'operations/#$id',
          hrefOfDebt: (id) => 'debts/#$id',
        ),
      ),
    );
  }

  /// The form, which goes back to the report of the метка it changed, or to
  /// the list, and says what the save did.
  Component _form(String? id) {
    final parent = id ?? '';
    return BlocProvider<TagFormCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: id),
      child: TagFormPage(
        onClose: () => closeForm(parent),
        onDone: (saved, {required isNew}) {
          setState(
            () => _toast = (
              text: _said(saved, isNew: isNew),
              marked: saved.marked > 0 && isNew ? saved : null,
            ),
          );
          closeForm(parent);
        },
      ),
    );
  }

  /// What a save says: how many expenses its days marked, or that the метка
  /// is added or saved.
  static String _said(TagMarking saved, {required bool isNew}) {
    final name = saved.tag.name;
    if (saved.marked > 0) return t.tags.marked(n: saved.marked, name: name);
    if (!isNew) return t.tags.saved(name: name);
    return saved.tag.isTrip
        ? t.tags.addedTrip(name: name)
        : t.tags.addedTag(name: name);
  }

  /// Takes the marked days back and says so.
  Future<void> _undo(TagMarking marked) async {
    await _tags?.unmarkDays(marked.tag.id);
    if (!mounted) return;
    setState(
      () => _toast = (text: t.tags.unmarked(n: marked.marked), marked: null),
    );
  }
}
