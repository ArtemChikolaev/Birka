import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_flutter/src/presentation/inbox_bits.dart';
import 'package:inbox_flutter/src/presentation/widgets/inbox_row.dart';
import 'package:inbox_flutter/src/presentation/widgets/pair_card.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The inbox on the phone, as its board draws it (ADR 0022): what waits and
/// after which import, the transfers between one's own accounts to link, and
/// the operations without a category with the hints of past choices, several
/// picked at once for one category. It needs an [InboxCubit] above it.
class InboxPage extends StatefulWidget {
  /// Creates the page, which [onBack] leaves; [onImport] starts the import
  /// of a statement when nothing waits, and [onNewCategory] makes a category
  /// for the operations being sorted.
  const InboxPage({
    required this.onBack,
    this.onImport,
    this.onNewCategory,
    this.clock = DateTime.now,
    super.key,
  });

  /// Leaves the page.
  final VoidCallback onBack;

  /// Starts the import of a statement.
  final VoidCallback? onImport;

  /// Makes a category with the person, which the operations being sorted get
  /// at once; without it the sheet of categories offers none.
  final CategoryMaker? onNewCategory;

  /// What the time is now, which tests can fix.
  final DateTime Function() clock;

  /// How many operations the list shows at first, and more at a time.
  static const page = 30;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  /// How many operations the list shows.
  int _shown = InboxPage.page;

  void _say(String text) {
    if (mounted) showGlassToast(context, text);
  }

  Future<void> _choosePicked(InboxCubit cubit, InboxState state) async {
    final kinds = {for (final item in state.picked) kindOf(item.transaction)};
    final category = await chooseCategory(
      context,
      state,
      [
        for (final kind in CategoryKind.values)
          if (kinds.contains(kind)) kind,
      ],
      title: t.inbox.pickedCategory,
      onNew: widget.onNewCategory,
    );
    if (category == null) return;
    // A new category may come after a while, and of the other kind.
    final count = cubit.state.picked
        .where((it) => kindOf(it.transaction) == category.kind)
        .length;
    if (count == 0) return;
    await cubit.choosePicked(category);
    if (!cubit.state.failed) {
      _say(
        t.inbox.sorted(
          category: category.name,
          operations: operationsOf(count),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thisYear = widget.clock().year;
    final reduced = BirkaMotion.reduced(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: BlocConsumer<InboxCubit, InboxState>(
          listenWhen: (previous, current) =>
              current.transfers > previous.transfers ||
              (current.failed && !previous.failed),
          listener: (context, state) => showGlassToast(
            context,
            state.failed ? t.inbox.failed : t.inbox.madeTransfer,
            trouble: state.failed,
          ),
          builder: (context, state) {
            final cubit = context.read<InboxCubit>();
            final picked = state.picked.length;
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceXxl * 3 + bottom,
                    ),
                    children: [
                      BackHeader(
                        label: t.inbox.title,
                        backLabel: t.inbox.back,
                        onBack: widget.onBack,
                      ),
                      const SizedBox(height: BirkaTokens.spaceLg),
                      ..._body(context, cubit, state, thisYear),
                    ],
                  ),
                ),
                Positioned(
                  left: BirkaTokens.spaceSm,
                  right: BirkaTokens.spaceSm,
                  bottom: BirkaTokens.spaceSm + bottom,
                  child: IgnorePointer(
                    ignoring: picked == 0,
                    child: ExcludeSemantics(
                      excluding: picked == 0,
                      // The bar leaves the screen whole, past the edge and the
                      // bar of the system under it.
                      child: AnimatedSlide(
                        offset: picked == 0
                            ? const Offset(0, 2.5)
                            : Offset.zero,
                        duration: reduced ? Duration.zero : BirkaMotion.base,
                        curve: BirkaMotion.standardCurve,
                        child: AnimatedOpacity(
                          opacity: picked == 0 ? 0 : 1,
                          duration: reduced ? Duration.zero : BirkaMotion.fast,
                          child: _PickedBar(
                            count: picked,
                            onNone: cubit.pickNone,
                            onChoose: () =>
                                unawaited(_choosePicked(cubit, state)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    InboxCubit cubit,
    InboxState state,
    int thisYear,
  ) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    if (state.loading) return const [];
    final pairs = state.shownPairs;
    final items = state.shownItems;
    if (state.count == 0) return [_Empty(onImport: widget.onImport)];
    final shown = items.take(_shown).toList();
    final visible = [for (final item in shown) item.id];
    final all = visible.isNotEmpty && visible.every(state.selected.contains);
    final after = afterLabel(state);
    return [
      // The count rolls down as the sorted rows close; it is no amount, so it
      // stays when amounts are hidden.
      AmountText(
        t.inbox.waiting(n: state.count, count: formatCount(state.count)),
        value: state.count,
        alwaysShown: true,
        style: styles.title.copyWith(color: colors.text),
      ),
      if (after != null)
        Text(
          _sentence(after),
          style: styles.caption.copyWith(color: colors.textMuted),
        ),
      const SizedBox(height: BirkaTokens.spaceMd),
      Wrap(
        spacing: BirkaTokens.spaceXs,
        runSpacing: BirkaTokens.spaceXs,
        children: [
          for (final (filter, count) in [
            (InboxFilter.all, state.count),
            (InboxFilter.uncategorized, state.items.length),
            (InboxFilter.transfers, state.pairs.length),
          ])
            BirkaChip(
              label: t.inbox.filters[filter.name] ?? filter.name,
              selected: state.filter == filter,
              count: count,
              compact: true,
              onTap: () => cubit.show(filter),
            ),
        ],
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      // A list of another filter comes at once; a row that goes within one
      // closes.
      AnimatedColumn(
        key: ValueKey(state.filter),
        children: [
          for (final pair in pairs)
            Padding(
              key: ValueKey(pair.key),
              padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
              child: PairCard(
                pair: pair,
                state: state,
                thisYear: thisYear,
                onSay: _say,
              ),
            ),
        ],
      ),
      if (items.isNotEmpty) ...[
        Row(
          children: [
            Expanded(
              child: SectionLabel(
                t.inbox.section(
                  title: t.inbox.uncategorized,
                  count: formatCount(items.length),
                ),
                color: colors.textMuted,
              ),
            ),
            _Link(
              label: all ? t.inbox.pickNone : t.inbox.pickAll,
              onTap: () => cubit.toggleAll(visible),
            ),
          ],
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        GlassListGroup(
          key: ValueKey(state.filter),
          children: [
            for (final item in shown)
              InboxRow(
                key: ValueKey(item.id),
                item: item,
                state: state,
                thisYear: thisYear,
                onSay: _say,
                onNewCategory: widget.onNewCategory,
              ),
            if (items.length > _shown)
              _More(
                key: const ValueKey('more'),
                left: items.length - _shown,
                onTap: () => setState(() => _shown += InboxPage.page),
              ),
          ],
        ),
        const SizedBox(height: BirkaTokens.spaceLg),
      ],
      if (pairs.isEmpty && items.isEmpty) ...[
        _Empty(onImport: widget.onImport),
        const SizedBox(height: BirkaTokens.spaceLg),
      ],
      Text(
        t.inbox.sourceText,
        style: styles.caption.copyWith(color: colors.textSubtle),
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      Text(
        t.inbox.stillCounted,
        style: styles.caption.copyWith(color: colors.textSubtle),
      ),
    ];
  }

  /// [text] as the start of a sentence.
  static String _sentence(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// What the page says when nothing waits, with the way to a statement.
class _Empty extends StatelessWidget {
  const _Empty({required this.onImport});

  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final onImport = this.onImport;
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GlyphBadge(
              glyph: BirkaGlyph.check,
              color: colors.accent,
              size: 44,
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Text(
            t.inbox.emptyTitle,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.inbox.emptyText,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          if (onImport != null) ...[
            const SizedBox(height: BirkaTokens.spaceLg),
            BirkaButton(label: t.inbox.toImport, onPressed: onImport),
          ],
        ],
      ),
    );
  }
}

/// The action on the picked operations: one category for them together.
class _PickedBar extends StatelessWidget {
  const _PickedBar({
    required this.count,
    required this.onNone,
    required this.onChoose,
  });

  final int count;
  final VoidCallback onNone;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BirkaTokens.spaceLg,
        BirkaTokens.spaceXxs,
        BirkaTokens.spaceXs,
        BirkaTokens.spaceXxs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusPill),
        ),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t.inbox.picked(n: count, count: formatCount(count)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.bodyStrong.copyWith(color: colors.text),
            ),
          ),
          _Link(label: t.inbox.unpick, onTap: onNone),
          const SizedBox(width: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.inbox.category,
            compact: true,
            onPressed: onChoose,
          ),
        ],
      ),
    );
  }
}

/// A quiet action in words, such as «Выбрать все».
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: BirkaTokens.sizeTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BirkaTokens.spaceXs,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BirkaTextStyles.of(
                  context,
                ).bodyStrong.copyWith(color: colors.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The row that shows more of the list.
class _More extends StatelessWidget {
  const _More({required this.left, required this.onTap, super.key});

  final int left;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BirkaTokens.spaceMd),
          child: Center(
            child: Text(
              t.inbox.more(n: left, count: formatCount(left)),
              style: BirkaTextStyles.of(
                context,
              ).body.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
